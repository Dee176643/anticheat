const alertsEl = document.getElementById('alerts');
const bansEl = document.getElementById('bans');
const playersEl = document.getElementById('players');
const tokenInput = document.getElementById('tokenInput');
const noticeBox = document.getElementById('noticeBox');
const statusBadge = document.getElementById('statusBadge');
const tokenState = document.getElementById('tokenState');
const navLinks = [...document.querySelectorAll('.nav-link')];
const tabPanels = [...document.querySelectorAll('.tab-panel')];
const chartSvg = document.getElementById('activityChart');

const TOKEN_STORAGE_KEY = 'custom-anticheat-admin-token';

const escapeHtml = (value) => String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

const formatDate = (value) => {
    if (!value) {
        return 'Unknown';
    }

    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const showNotice = (message, type = 'info') => {
    if (!message) {
        noticeBox.classList.add('hidden');
        noticeBox.textContent = '';
        noticeBox.className = 'notice hidden';
        return;
    }

    noticeBox.textContent = message;
    noticeBox.className = `notice ${type}`;
};

const getToken = () => tokenInput.value.trim();

async function fetchJson(url, options = {}) {
    const headers = new Headers(options.headers || {});
    const token = getToken();

    if (token) {
        headers.set('x-admin-token', token);
    }

    const response = await fetch(url, {
        ...options,
        headers
    });

    if (!response.ok) {
        const payload = await response.text();
        throw new Error(`Request failed: ${response.status}${payload ? ` - ${payload}` : ''}`);
    }

    return response.json();
}

function setActiveTab(tabName) {
    navLinks.forEach((button) => {
        button.classList.toggle('active', button.dataset.tab === tabName);
    });

    tabPanels.forEach((panel) => {
        const visibleTabs = (panel.dataset.tabPanel || '').split(' ');
        panel.classList.toggle('active', visibleTabs.includes(tabName));
    });
}

function renderChart(alerts) {
    const values = alerts.slice(0, 12).reverse().map((alert) => Number(alert.scoreDelta) || 0);
    const width = 900;
    const height = 260;
    const padding = 18;
    const points = values.length ? values : [0, 0, 0, 0];
    const maxValue = Math.max(...points, 10);
    const step = points.length > 1 ? (width - padding * 2) / (points.length - 1) : width - padding * 2;

    const linePoints = points.map((value, index) => {
        const x = padding + step * index;
        const y = height - padding - (value / maxValue) * (height - padding * 2);
        return `${x},${y}`;
    }).join(' ');

    const areaPoints = `${padding},${height - padding} ${linePoints} ${padding + step * (points.length - 1)},${height - padding}`;

    chartSvg.innerHTML = `
        <defs>
            <linearGradient id="chartFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="rgba(61, 171, 255, 0.42)"></stop>
                <stop offset="100%" stop-color="rgba(61, 171, 255, 0.02)"></stop>
            </linearGradient>
        </defs>
        <g class="chart-grid">
            <line x1="${padding}" y1="42" x2="${width - padding}" y2="42"></line>
            <line x1="${padding}" y1="106" x2="${width - padding}" y2="106"></line>
            <line x1="${padding}" y1="170" x2="${width - padding}" y2="170"></line>
            <line x1="${padding}" y1="${height - padding}" x2="${width - padding}" y2="${height - padding}"></line>
        </g>
        <polygon points="${areaPoints}" fill="url(#chartFill)"></polygon>
        <polyline points="${linePoints}" fill="none" stroke="#3dabff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></polyline>
    `;
}

function renderOverview(data, players) {
    document.getElementById('totalPlayers').textContent = data.stats.totalPlayers;
    document.getElementById('liveSessions').textContent = data.stats.liveSessions;
    document.getElementById('bannedPlayers').textContent = data.stats.bannedPlayers;
    document.getElementById('alertCount').textContent = data.alerts.length;
    document.getElementById('chartLabel').textContent = `Last ${Math.min(data.alerts.length || 0, 12)} detections`;

    statusBadge.textContent = data.stats.liveSessions > 0 ? 'Live Data' : 'Connected';
    statusBadge.className = 'status-pill online';
    tokenState.textContent = getToken() ? 'Token Active' : 'Open Access';

    alertsEl.innerHTML = data.alerts.length ? data.alerts.map((alert) => `
        <article class="feed-item">
            <div class="feed-head">
                <strong>${escapeHtml(alert.type)}</strong>
                <span class="pill ${escapeHtml(alert.severity)}">${escapeHtml(alert.severity)}</span>
            </div>
            <p>Player ID ${escapeHtml(alert.playerId)} | +${escapeHtml(alert.scoreDelta)} | ${escapeHtml(alert.confidence)}</p>
            <small>${escapeHtml(formatDate(alert.createdAt))}</small>
        </article>
    `).join('') : '<article class="feed-item empty"><p>No alerts recorded yet.</p></article>';

    bansEl.innerHTML = data.bans.length ? data.bans.map((ban) => `
        <article class="feed-item">
            <div class="feed-head">
                <strong>Player ${escapeHtml(ban.player_id)}</strong>
                <span class="pill ${ban.active ? 'critical' : 'neutral'}">${ban.active ? 'Active' : 'Revoked'}</span>
            </div>
            <p>${escapeHtml(ban.reason)}</p>
            <small>${escapeHtml(formatDate(ban.issued_at))} | ${escapeHtml(ban.issued_by || 'system')}</small>
        </article>
    `).join('') : '<article class="feed-item empty"><p>No bans found.</p></article>';

    playersEl.innerHTML = players.length ? players.map((player) => `
        <article class="player-card">
            <div class="feed-head">
                <strong>Player ${escapeHtml(player.id)}</strong>
                <span class="pill ${player.is_banned ? 'critical' : 'neutral'}">${player.is_banned ? 'Banned' : 'Clear'}</span>
            </div>
            <div class="player-meta">
                <span>Score</span>
                <strong>${escapeHtml(player.current_risk_score)}</strong>
            </div>
            <p>${escapeHtml(player.license_id || player.fivem_id || player.discord_id || 'Unknown identifier')}</p>
            <small>Last seen ${escapeHtml(formatDate(player.last_seen_at))}</small>
        </article>
    `).join('') : '<article class="player-card empty"><p>No players in database.</p></article>';

    renderChart(data.alerts);
}

async function load() {
    showNotice('Refreshing dashboard data...', 'info');

    try {
        const [overview, players] = await Promise.all([
            fetchJson('/api/overview'),
            fetchJson('/api/players')
        ]);

        renderOverview(overview, players);
        showNotice('');
    } catch (error) {
        statusBadge.textContent = 'Connection Error';
        statusBadge.className = 'status-pill offline';
        tokenState.textContent = getToken() ? 'Token Rejected' : 'Token Missing';
        showNotice(error.message, 'error');
    }
}

document.getElementById('refreshBtn').addEventListener('click', () => {
    load();
});

document.getElementById('saveTokenBtn').addEventListener('click', () => {
    localStorage.setItem(TOKEN_STORAGE_KEY, getToken());
    tokenState.textContent = getToken() ? 'Token Saved' : 'Open Access';
    showNotice('Token saved in this browser. Use Refresh Data to reload.', 'success');
});

navLinks.forEach((button) => {
    button.addEventListener('click', () => {
        setActiveTab(button.dataset.tab);
    });
});

tokenInput.value = localStorage.getItem(TOKEN_STORAGE_KEY) || '';
tokenState.textContent = tokenInput.value ? 'Token Loaded' : 'Token Needed';
setActiveTab('dashboard');
load();
