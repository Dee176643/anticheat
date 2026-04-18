const alertsEl = document.getElementById('alerts');
const bansEl = document.getElementById('bans');
const playersEl = document.getElementById('players');

const escapeHtml = (value) => String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

async function fetchJson(url, options = {}) {
    const response = await fetch(url, options);
    if (!response.ok) {
        throw new Error(`Request failed: ${response.status}`);
    }
    return response.json();
}

function renderOverview(data, players) {
    document.getElementById('totalPlayers').textContent = data.stats.totalPlayers;
    document.getElementById('liveSessions').textContent = data.stats.liveSessions;
    document.getElementById('bannedPlayers').textContent = data.stats.bannedPlayers;

    alertsEl.innerHTML = data.alerts.length ? data.alerts.map((alert) => `
        <article class="item">
            <div class="item-head">
                <strong>${escapeHtml(alert.type)}</strong>
                <span class="pill">${escapeHtml(alert.severity)}</span>
            </div>
            <p>Player ID ${escapeHtml(alert.playerId)} • +${escapeHtml(alert.scoreDelta)} • ${escapeHtml(alert.confidence)}</p>
            <small>${escapeHtml(JSON.stringify(alert.details))}</small>
        </article>
    `).join('') : '<article class="item"><p>No alerts.</p></article>';

    bansEl.innerHTML = data.bans.length ? data.bans.map((ban) => `
        <article class="item">
            <div class="item-head">
                <strong>Player ${escapeHtml(ban.player_id)}</strong>
                <span class="pill">${ban.active ? 'active' : 'revoked'}</span>
            </div>
            <p>${escapeHtml(ban.reason)}</p>
            <small>${escapeHtml(String(ban.issued_at || ''))}</small>
        </article>
    `).join('') : '<article class="item"><p>No bans.</p></article>';

    playersEl.innerHTML = players.length ? players.map((player) => `
        <article class="item">
            <div class="item-head">
                <strong>Player ${escapeHtml(player.id)}</strong>
                <span class="pill">${player.is_banned ? 'banned' : 'clear'}</span>
            </div>
            <p>Score ${escapeHtml(player.current_risk_score)} • ${escapeHtml(player.license_id || player.fivem_id || 'unknown')}</p>
            <small>Last seen ${escapeHtml(String(player.last_seen_at || ''))}</small>
        </article>
    `).join('') : '<article class="item"><p>No players.</p></article>';
}

async function load() {
    const [overview, players] = await Promise.all([
        fetchJson('/api/overview'),
        fetchJson('/api/players')
    ]);

    renderOverview(overview, players);
}

document.getElementById('refreshBtn').addEventListener('click', () => {
    load().catch((error) => {
        window.alert(error.message);
    });
});

load().catch((error) => {
    window.alert(error.message);
});
