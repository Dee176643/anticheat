Bans = {}

local function fetchPlayerIdByIdentifiers(ids)
    if not ids then
        return nil
    end

    local row = MySQL.single.await([[
        SELECT id
        FROM ac_players
        WHERE license_id = ? OR fivem_id = ? OR discord_id = ? OR steam_id = ?
        LIMIT 1
    ]], {
        ids.license,
        ids.fivem,
        ids.discord,
        ids.steam
    })

    return row and row.id or nil
end

function Bans.getActiveByIdentifiers(ids)
    local playerId = fetchPlayerIdByIdentifiers(ids)
    if not playerId then
        return nil
    end

    return MySQL.single.await([[
        SELECT id, reason, issued_by, issued_at, expires_at, evidence_summary
        FROM ac_bans
        WHERE player_id = ?
          AND active = 1
          AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
        ORDER BY issued_at DESC
        LIMIT 1
    ]], { playerId })
end

function Bans.issueForSource(source, reason, issuedBy, evidenceSummary, expiresAt)
    local session = Sessions.get(source)
    if not session then
        return nil
    end

    local banId = MySQL.insert.await([[
        INSERT INTO ac_bans (player_id, reason, issued_by, issued_at, expires_at, evidence_summary, active)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?, 1)
    ]], {
        session.playerId,
        reason,
        issuedBy or 'system',
        expiresAt,
        evidenceSummary
    })

    MySQL.update.await('UPDATE ac_players SET is_banned = 1 WHERE id = ?', { session.playerId })
    Logger.error('Ban issued:', 'source=' .. tostring(source), 'banId=' .. tostring(banId), 'reason=' .. tostring(reason))
    DropPlayer(source, ('Anticheat: banned (%s)'):format(reason))
    return banId
end

function Bans.issueForPlayerId(playerId, reason, issuedBy, evidenceSummary, expiresAt)
    local banId = MySQL.insert.await([[
        INSERT INTO ac_bans (player_id, reason, issued_by, issued_at, expires_at, evidence_summary, active)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?, 1)
    ]], {
        playerId,
        reason,
        issuedBy or 'system',
        expiresAt,
        evidenceSummary
    })

    MySQL.update.await('UPDATE ac_players SET is_banned = 1 WHERE id = ?', { playerId })
    return banId
end

function Bans.revoke(banId)
    local ban = MySQL.single.await('SELECT player_id FROM ac_bans WHERE id = ? LIMIT 1', { banId })
    if not ban then
        return false
    end

    MySQL.update.await('UPDATE ac_bans SET active = 0, expires_at = CURRENT_TIMESTAMP WHERE id = ?', { banId })

    local stillActive = MySQL.single.await([[
        SELECT id
        FROM ac_bans
        WHERE player_id = ?
          AND active = 1
          AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
        LIMIT 1
    ]], { ban.player_id })

    MySQL.update.await('UPDATE ac_players SET is_banned = ? WHERE id = ?', {
        stillActive and 1 or 0,
        ban.player_id
    })

    return true
end

function Bans.getRecent(limit)
    return MySQL.query.await([[
        SELECT b.id, b.player_id, b.reason, b.issued_by, b.issued_at, b.expires_at, b.evidence_summary, b.active,
               p.license_id, p.fivem_id, p.discord_id, p.steam_id
        FROM ac_bans b
        JOIN ac_players p ON p.id = b.player_id
        ORDER BY b.issued_at DESC
        LIMIT ?
    ]], { limit or 25 })
end

function Bans.enforceConnection(source, deferrals)
    local ids = Identifiers.getAll(source)
    local activeBan = Bans.getActiveByIdentifiers(ids)

    if not activeBan then
        return false
    end

    deferrals.done(('Anticheat: banned (%s)'):format(activeBan.reason))
    CancelEvent()
    return true
end
