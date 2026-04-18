const app = document.getElementById('app');
const tabs = [...document.querySelectorAll('.tab')];
const navLinks = [...document.querySelectorAll('.nav-link')];
const alertList = document.getElementById('alertList');
const playerList = document.getElementById('playerList');
const banList = document.getElementById('banList');
const dashboardUrl = document.getElementById('dashboardUrl');

const state = {
    data: {
        players: [],
        alerts: [],
        bans: [],
        localDashboardUrl: ''
    }
};

const isNui = typeof GetParentResourceName === 'function';

const post = async (event, payload = {}) => {
    if (!isNui) {
        return null;
    }

    const response = await fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    });

    return response.json();
};

const escapeHtml = (value) => String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

const setTab = (tabName) => {
    tabs.forEach((tab) => tab.classList.toggle('active', tab.id === `${tabName}Tab`));
    navLinks.forEach((button) => button.classList.toggle('active', button.dataset.tab === tabName));
};

const formatTime = (value) => {
    if (!value) {
        return 'Unknown';
    }

    const date = new Date(value * 1000);
    return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const renderOverview = () => {
    const { players, alerts, bans, localDashboardUrl } = state.data;
    document.getElementById('playerCount').textContent = players.length;
    document.getElementById('alertCount').textContent = alerts.length;
    document.getElementById('banCount').textContent = bans.length;
    dashboardUrl.textContent = localDashboardUrl ? `Dashboard: ${localDashboardUrl}` : '';

    alertList.innerHTML = alerts.length ? alerts.map((entry) => `
        <article class="item">
            <div class="item-head">
                <strong>${escapeHtml(entry.playerName)} <span class="muted">#${escapeHtml(entry.source)}</span></strong>
                <span class="pill ${escapeHtml(entry.severity)}">${escapeHtml(entry.type)}</span>
            </div>
            <p>${escapeHtml(entry.details && JSON.stringify(entry.details))}</p>
            <small>${escapeHtml(formatTime(entry.createdAt))} • +${escapeHtml(entry.scoreDelta)} • ${escapeHtml(entry.confidence)}</small>
        </article>
    `).join('') : '<article class="item"><p>No alerts yet.</p></article>';
};

const renderPlayers = () => {
    const { players } = state.data;

    playerList.innerHTML = players.length ? players.map((player) => `
        <article class="item">
            <div class="item-head">
                <strong>${escapeHtml(player.name)}</strong>
                <span class="pill neutral">#${escapeHtml(player.source)}</span>
            </div>
            <p>Score: <strong>${escapeHtml(player.score)}</strong> • License: ${escapeHtml(player.license || 'unknown')}</p>
            <small>Joined ${escapeHtml(formatTime(player.joinedAt))}</small>
            <div class="action-row">
                <button class="ghost" data-action="warn" data-target="${escapeHtml(player.source)}">Warn</button>
                <button class="ghost danger" data-action="kick" data-target="${escapeHtml(player.source)}">Kick</button>
                <button class="ghost danger" data-action="ban" data-target="${escapeHtml(player.source)}">Ban</button>
            </div>
        </article>
    `).join('') : '<article class="item"><p>No live players.</p></article>';

    playerList.querySelectorAll('button[data-action]').forEach((button) => {
        button.addEventListener('click', async () => {
            const action = button.dataset.action;
            const target = Number(button.dataset.target);
            const reason = window.prompt(`Reason for ${action}:`, `Admin ${action}`);
            if (!reason) {
                return;
            }

            await post('moderatePlayer', { action, target, reason });
            await post('getPanelData');
        });
    });
};

const renderBans = () => {
    const { bans } = state.data;

    banList.innerHTML = bans.length ? bans.map((ban) => `
        <article class="item">
            <div class="item-head">
                <strong>Player ID ${escapeHtml(ban.player_id)}</strong>
                <span class="pill ${ban.active ? 'critical' : 'neutral'}">${ban.active ? 'active' : 'revoked'}</span>
            </div>
            <p>${escapeHtml(ban.reason)}</p>
            <small>${escapeHtml(ban.issued_by)} • ${escapeHtml(String(ban.issued_at || ''))}</small>
        </article>
    `).join('') : '<article class="item"><p>No bans recorded.</p></article>';
};

const renderAll = () => {
    renderOverview();
    renderPlayers();
    renderBans();
};

document.getElementById('refreshBtn').addEventListener('click', async () => {
    await post('getPanelData');
});

document.getElementById('closeBtn').addEventListener('click', async () => {
    await post('close');
});

navLinks.forEach((button) => {
    button.addEventListener('click', () => setTab(button.dataset.tab));
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.type === 'panel:toggle') {
        app.classList.toggle('hidden', !data.open);
        if (data.open) {
            setTab('overview');
            post('getPanelData');
        }
    }

    if (data.type === 'panel:data') {
        state.data = data.payload || state.data;
        renderAll();
    }
});
