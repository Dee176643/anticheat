import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mysql from 'mysql2/promise';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dashboardDir = path.resolve(__dirname, '../../dashboard');
const app = express();
const port = Number(process.env.PORT || 3012);
const host = process.env.HOST || '127.0.0.1';
const adminToken = process.env.ADMIN_TOKEN || '';

const pool = mysql.createPool({
    host: process.env.MYSQL_HOST || '127.0.0.1',
    port: Number(process.env.MYSQL_PORT || 3306),
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || '',
    database: process.env.MYSQL_DATABASE || 'fivem',
    waitForConnections: true,
    connectionLimit: 10
});

app.use(cors());
app.use(express.json());
app.use(express.static(dashboardDir));

const requireToken = (req, res, next) => {
    if (!adminToken || req.headers['x-admin-token'] === adminToken) {
        next();
        return;
    }

    res.status(401).json({ error: 'Unauthorized' });
};

const decodeJson = (raw, fallback = {}) => {
    if (!raw) {
        return fallback;
    }

    try {
        return JSON.parse(raw);
    } catch {
        return fallback;
    }
};

app.get('/health', async (_req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ ok: true, host, port });
    } catch (error) {
        res.status(500).json({ ok: false, error: error.message });
    }
});

app.get('/api/overview', requireToken, async (_req, res) => {
    try {
        const [[playerStats]] = await pool.query('SELECT COUNT(*) AS totalPlayers, SUM(is_banned) AS bannedPlayers FROM ac_players');
        const [[sessionStats]] = await pool.query('SELECT COUNT(*) AS liveSessions FROM ac_sessions WHERE left_at IS NULL');
        const [alerts] = await pool.query(`
            SELECT d.id, d.type, d.severity, d.score_delta, d.confidence, d.details_json, d.created_at,
                   p.id AS player_id, p.license_id, p.fivem_id, p.discord_id
            FROM ac_detections d
            JOIN ac_players p ON p.id = d.player_id
            ORDER BY d.created_at DESC
            LIMIT 50
        `);
        const [bans] = await pool.query(`
            SELECT id, player_id, reason, issued_by, issued_at, expires_at, evidence_summary, active
            FROM ac_bans
            ORDER BY issued_at DESC
            LIMIT 25
        `);

        res.json({
            stats: {
                totalPlayers: playerStats.totalPlayers || 0,
                bannedPlayers: playerStats.bannedPlayers || 0,
                liveSessions: sessionStats.liveSessions || 0
            },
            alerts: alerts.map((row) => ({
                id: row.id,
                playerId: row.player_id,
                type: row.type,
                severity: row.severity,
                scoreDelta: row.score_delta,
                confidence: row.confidence,
                details: decodeJson(row.details_json),
                createdAt: row.created_at,
                identifiers: {
                    license: row.license_id,
                    fivem: row.fivem_id,
                    discord: row.discord_id
                }
            })),
            bans
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/players', requireToken, async (_req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT p.id, p.license_id, p.fivem_id, p.discord_id, p.steam_id, p.first_seen_at, p.last_seen_at,
                   p.current_risk_score, p.is_banned,
                   s.id AS live_session_id, s.joined_at AS live_joined_at
            FROM ac_players p
            LEFT JOIN ac_sessions s ON s.player_id = p.id AND s.left_at IS NULL
            ORDER BY p.last_seen_at DESC
            LIMIT 250
        `);

        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/players/:id', requireToken, async (req, res) => {
    try {
        const playerId = Number(req.params.id);
        const [[player]] = await pool.query('SELECT * FROM ac_players WHERE id = ? LIMIT 1', [playerId]);

        if (!player) {
            res.status(404).json({ error: 'Player not found' });
            return;
        }

        const [sessions] = await pool.query('SELECT * FROM ac_sessions WHERE player_id = ? ORDER BY joined_at DESC LIMIT 50', [playerId]);
        const [detections] = await pool.query('SELECT * FROM ac_detections WHERE player_id = ? ORDER BY created_at DESC LIMIT 100', [playerId]);
        const [bans] = await pool.query('SELECT * FROM ac_bans WHERE player_id = ? ORDER BY issued_at DESC LIMIT 25', [playerId]);

        res.json({
            player,
            sessions,
            detections: detections.map((row) => ({ ...row, details_json: decodeJson(row.details_json) })),
            bans
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/alerts', requireToken, async (_req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT id, player_id, type, severity, score_delta, confidence, details_json, created_at
            FROM ac_detections
            ORDER BY created_at DESC
            LIMIT 100
        `);

        res.json(rows.map((row) => ({ ...row, details_json: decodeJson(row.details_json) })));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/bans', requireToken, async (_req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT id, player_id, reason, issued_by, issued_at, expires_at, evidence_summary, active
            FROM ac_bans
            ORDER BY issued_at DESC
            LIMIT 100
        `);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/bans', requireToken, async (req, res) => {
    try {
        const { playerId, reason, issuedBy, evidenceSummary, expiresAt } = req.body || {};
        if (!playerId || !reason) {
            res.status(400).json({ error: 'playerId and reason are required' });
            return;
        }

        const [result] = await pool.query(`
            INSERT INTO ac_bans (player_id, reason, issued_by, issued_at, expires_at, evidence_summary, active)
            VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?, 1)
        `, [
            Number(playerId),
            reason,
            issuedBy || 'dashboard',
            expiresAt || null,
            evidenceSummary || null
        ]);

        await pool.query('UPDATE ac_players SET is_banned = 1 WHERE id = ?', [Number(playerId)]);
        res.status(201).json({ id: result.insertId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/bans/:id/revoke', requireToken, async (req, res) => {
    try {
        const banId = Number(req.params.id);
        const [[ban]] = await pool.query('SELECT player_id FROM ac_bans WHERE id = ? LIMIT 1', [banId]);
        if (!ban) {
            res.status(404).json({ error: 'Ban not found' });
            return;
        }

        await pool.query('UPDATE ac_bans SET active = 0, expires_at = CURRENT_TIMESTAMP WHERE id = ?', [banId]);

        const [[stillActive]] = await pool.query(`
            SELECT id
            FROM ac_bans
            WHERE player_id = ?
              AND active = 1
              AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
            LIMIT 1
        `, [ban.player_id]);

        await pool.query('UPDATE ac_players SET is_banned = ? WHERE id = ?', [stillActive ? 1 : 0, ban.player_id]);
        res.json({ ok: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('*', (_req, res) => {
    res.sendFile(path.join(dashboardDir, 'index.html'));
});

app.listen(port, host, () => {
    console.log(`Custom anticheat dashboard running at http://${host}:${port}`);
});
