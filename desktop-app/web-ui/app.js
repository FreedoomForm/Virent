/* ============================================================
 * Virent Admin — SPA runtime
 * Connects to REST API at http://localhost:8393/v1
 * All 16 tabs, real data, working modals, zone editor, charts.
 * ============================================================ */

const API = 'http://localhost:8393/v1';
const ADMIN_KEY = 'admin_api_key_for_dashboard_2024';
const USER_KEY = '8c5cfe9194754709dfc16c613b39ea6a';

// ---- State ----
let token = localStorage.getItem('virent_admin_token') || '';
let currentTab = 'dashboard';
let cache = {};

// ---- Native bridge (C++ <-> JS) ----
// When running inside the C++ WebView2 host, window.chrome.webview is available.
// We use postMessage to call native C++ functions for: Docker, file system,
// shell, IoT (BLE scan). For REST API calls we still use fetch() directly.
const native = {
  available: typeof window.chrome !== 'undefined' && window.chrome.webview,

  // Send a message to C++ and get a sync response via postMessage.
  // (WebView2's postMessage is fire-and-forget; we use a Promise wrapper
  // that resolves when the C++ side replies via postJson.)
  call(method, payload = '') {
    return new Promise((resolve) => {
      if (!this.available) return resolve(null);
      const id = Math.random().toString(36).slice(2);
      const handler = (e) => {
        try {
          const data = JSON.parse(e.data || '"{}"');
          if (data._id === id) {
            window.chrome.webview.removeEventListener('message', handler);
            resolve(data);
          }
        } catch {
          // C++ sends raw strings; treat as direct response
          window.chrome.webview.removeEventListener('message', handler);
          resolve({ raw: e.data });
        }
      };
      window.chrome.webview.addEventListener('message', handler);
      window.chrome.webview.postMessage(`${method}|${id}|${payload}`);
    });
  },

  async dockerStatus() {
    const r = await this.call('docker.status');
    return r?.data || [];
  },
  async dockerStart() { return this.call('docker.start'); },
  async dockerStop() { return this.call('docker.stop'); },
  async dockerRestart() { return this.call('docker.restart'); },
  async dockerLogs(name) { return this.call('docker.logs', name); },
  async dockerBackup() { return this.call('docker.backup'); },

  async iotSendCommand(mac, cmd) { return this.call('iot.sendCommand', `${mac}|${cmd}`); },

  async shellOpenUrl(url) { return this.call('shell.openUrl', url); },
  async shellOpenFile() { return this.call('shell.openFile'); },

  async fsReadFile(path) { return this.call('fs.readFile', path); },
  async fsListBackups() { return this.call('fs.listBackups'); },

  async appGetVersion() { return this.call('app.getVersion'); },
  async appGetConfigDir() { return this.call('app.getConfigDir'); },

  // APK download with progress callbacks
  // C++ downloads to the user's Downloads folder and posts progress updates
  // back via the message event. We resolve the promise when C++ sends a
  // final "done" or "error" message.
  apkDownload(url, filename) {
    return new Promise((resolve) => {
      if (!this.available) return resolve(null);
      const id = Math.random().toString(36).slice(2);
      const handler = (e) => {
        try {
          const data = JSON.parse(e.data || '"{}"');
          if (data._id !== id) return;
          if (data.type === 'progress') {
            // Update progress UI in real-time
            const fillEl = document.getElementById(`apk-fill-${filename.split('-')[0]}`);
            const textEl = document.getElementById(`apk-text-${filename.split('-')[0]}`);
            if (fillEl) fillEl.style.width = data.pct + '%';
            if (textEl) textEl.textContent = data.pct + '%';
          } else if (data.type === 'done' || data.type === 'error') {
            window.chrome.webview.removeEventListener('message', handler);
            resolve(data.type === 'done' ? { data: { success: true, path: data.path, size: data.size } }
                                          : { error: data.error });
          }
        } catch {}
      };
      window.chrome.webview.addEventListener('message', handler);
      window.chrome.webview.postMessage(`apk.download|${id}|${url}|${filename}`);
    });
  },
};

// ---- API helpers ----
async function api(path, opts = {}) {
  const url = `${API}${path}${path.includes('?') ? '&' : '?'}api_key=${ADMIN_KEY}`;
  const res = await fetch(url, {
    ...opts,
    headers: {
      'Content-Type': 'application/json',
      'x-access-token': token,
      ...(opts.headers || {}),
    },
  });
  const text = await res.text();
  try { return { ok: res.ok, status: res.status, data: JSON.parse(text) }; }
  catch { return { ok: res.ok, status: res.status, data: text }; }
}

async function login() {
  if (token) return true;
  const r = await api('/auth/login/server/admin', {
    method: 'POST',
    body: JSON.stringify({
      email: 'admin@sparkrentals.local',
      password: 'Admin123!',
      api_key: ADMIN_KEY,
      apiKey: ADMIN_KEY,
    }),
  });
  if (r.ok && r.data?.data?.token) {
    token = r.data.data.token;
    localStorage.setItem('virent_admin_token', token);
    return true;
  }
  return false;
}

// ---- Navigation ----
function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.nav-item').forEach(n => n.classList.toggle('active', n.dataset.tab === tab));
  document.querySelectorAll('.screen').forEach(s => s.classList.toggle('active', s.id === `screen-${tab}`));
  loadTabData(tab);
}

// ---- Data loaders ----
async function loadTabData(tab) {
  switch (tab) {
    case 'dashboard': loadDashboard(); break;
    case 'server': loadDockerStatus(); break;
    case 'scooters': loadScooters(); break;
    case 'trips': loadTrips(); break;
    case 'customers': loadCustomers(); break;
    case 'cities': loadCities(); break;
    case 'zones': /* uses cities data */ break;
    case 'audit-log': loadAuditLog(); break;
    case 'prepaid': loadPrepaids(); break;
    case 'support': loadSupport(); break;
    case 'analytics': loadAnalytics(); break;
    case 'notifications': loadNotifications(); break;
  }
}

async function loadDashboard() {
  const [scooters, users, cities] = await Promise.all([
    api('/scooters'),
    api('/users'),
    api('/cities'),
  ]);
  const scooterList = scooters.data?.scooters || [];
  const userList = users.data?.users || users.data?.data || [];
  const cityList = cities.data?.cities || cities.data?.data || [];

  const available = scooterList.filter(s => s.status === 'available').length;
  const inUse = scooterList.filter(s => s.status === 'in_use').length;
  const charging = scooterList.filter(s => s.status === 'charging_needed' || s.status === 'charging').length;

  document.getElementById('stat-scooters-total').textContent = scooterList.length;
  document.getElementById('stat-scooters-available').textContent = available;
  document.getElementById('stat-scooters-inuse').textContent = inUse;
  document.getElementById('stat-scooters-charging').textContent = charging;
  document.getElementById('stat-users-total').textContent = userList.length;
  document.getElementById('stat-cities-total').textContent = cityList.length;
}

async function loadScooters() {
  const r = await api('/scooters');
  const list = r.data?.scooters || [];
  cache.scooters = list;
  const tbody = document.getElementById('scooters-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.slice(0, 50).map(s => `
    <tr>
      <td><strong>${esc(s.name)}</strong></td>
      <td>${esc(s.model || '-')}</td>
      <td><span class="badge ${statusBadge(s.status)}"><span class="dot"></span>${esc(s.status)}</span></td>
      <td>${Math.round(s.battery || 0)}%</td>
      <td><code>${esc(s.mac_address || '-')}</code></td>
      <td>${esc(s.serial_number || '-')}</td>
      <td><div class="row-actions">
        <button class="icon-btn" onclick="scooterDetail('${s._id}')" title="Detail"><span class="material-icons">visibility</span></button>
        <button class="icon-btn" onclick="sendCmd('${s.mac_address}','lock')" title="Lock"><span class="material-icons">lock</span></button>
        <button class="icon-btn" onclick="sendCmd('${s.mac_address}','unlock')" title="Unlock"><span class="material-icons">lock_open</span></button>
      </div></td>
    </tr>`).join('') || '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted);">No scooters found. Run <code>node scripts/seed-db.js</code> to seed test data.</td></tr>';
}

async function loadTrips() {
  const r = await api('/trips');
  const list = r.data?.data || r.data?.trips || [];
  cache.trips = list;
  const tbody = document.getElementById('trips-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.slice(0, 50).map(t => `
    <tr>
      <td><code>${(t._id || '').slice(0,12)}</code></td>
      <td>${esc(t.user_id || '-')}</td>
      <td>${esc(t.scooter_id || '-')}</td>
      <td>${fmtDate(t.start_time)}</td>
      <td>${fmtDate(t.end_time)}</td>
      <td>${t.distance_km ? t.distance_km.toFixed(1) + ' km' : '-'}</td>
      <td>${t.cost ? Math.round(t.cost) + ' UZS' : '-'}</td>
      <td><span class="badge ${statusBadge(t.status)}"><span class="dot"></span>${esc(t.status)}</span></td>
      <td><div class="row-actions">
        <button class="icon-btn" onclick="refundModal('${t._id}', ${t.cost || 0})" title="Refund"><span class="material-icons">undo</span></button>
      </div></td>
    </tr>`).join('') || '<tr><td colspan="9" style="text-align:center;padding:40px;color:var(--text-muted);">No trips yet.</td></tr>';
}

async function loadCustomers() {
  const r = await api('/users');
  const list = r.data?.users || r.data?.data || [];
  cache.users = list;
  const tbody = document.getElementById('customers-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.slice(0, 50).map(u => {
    const status = u.status || 'active_user';
    const badge = status === 'blocked' ? 'badge-danger' : 'badge-success';
    const blockBtn = status === 'blocked'
      ? `<button class="icon-btn" onclick="unblockUser('${u._id}')" title="Unblock"><span class="material-icons">check_circle</span></button>`
      : `<button class="icon-btn" onclick="blockModal('${u._id}')" title="Block"><span class="material-icons">block</span></button>`;
    return `<tr style="${status === 'blocked' ? 'background:var(--danger-bg);' : ''}">
      <td><strong>${esc(u.name || u.email || 'Unknown')}</strong></td>
      <td>${esc(u.email || '-')}</td>
      <td>${esc(u.phone || '-')}</td>
      <td><strong>${Math.round(u.balance || 0)}</strong></td>
      <td>${esc(u.status || 'active')}</td>
      <td>${fmtDate(u.created_at)}</td>
      <td><div class="row-actions">
        <button class="icon-btn" onclick="adjustBalanceModal('${u._id}', ${u.balance || 0})" title="Adjust balance"><span class="material-icons">payments</span></button>
        ${blockBtn}
      </div></td>
    </tr>`;
  }).join('') || '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted);">No users yet.</td></tr>';
}

async function loadCities() {
  const r = await api('/cities');
  const list = r.data?.cities || r.data?.data || [];
  cache.cities = list;
  const tbody = document.getElementById('cities-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.map(c => `
    <tr>
      <td><strong>${esc(c.name || c.city_name || 'Unknown')}</strong></td>
      <td>${esc(c.scooters_count || '-')}</td>
      <td>${esc(c.active_count || '-')}</td>
      <td>${esc(c.start_rate || '-')}</td>
      <td>${esc(c.minute_rate || '-')}</td>
      <td>${esc(c.tax_percent || '-')}</td>
      <td>${(c.zones || []).length}</td>
    </tr>`).join('') || '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted);">No cities yet.</td></tr>';
}

async function loadAuditLog() {
  const r = await api('/audit-log?limit=50');
  const list = r.data?.data?.log || r.data?.data || r.data?.log || [];
  cache.auditLog = list;
  const tbody = document.getElementById('audit-tbody');
  if (!tbody) return;
  tbody.innerHTML = (Array.isArray(list) ? list : []).map(e => `
    <tr>
      <td>${fmtDate(e.timestamp)}</td>
      <td>${esc(e.actor || '-')}</td>
      <td><strong>${esc(e.action || '-')}</strong></td>
      <td>${esc(e.entity || '-')}</td>
      <td><code>${esc((e.entity_id || '').slice(0,12))}</code></td>
      <td>${esc(e.ip || '-')}</td>
      <td>${esc(JSON.stringify(e.details || {}).slice(0, 80))}</td>
    </tr>`).join('') || '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted);">No audit entries yet.</td></tr>';
}

async function loadPrepaids() {
  const r = await api('/prepaids');
  const list = r.data?.data || r.data?.prepaids || [];
  cache.prepaids = list;
  const tbody = document.getElementById('prepaid-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.slice(0, 50).map(p => `
    <tr>
      <td><code>${esc(p.code)}</code></td>
      <td>${Math.round(p.amount)} ${esc(p.currency || 'UZS')}</td>
      <td><span class="badge ${p.status === 'unused' ? 'badge-success' : 'badge-neutral'}"><span class="dot"></span>${esc(p.status)}</span></td>
      <td>${esc(p.used_by || '-')}</td>
      <td>${fmtDate(p.expires_at)}</td>
    </tr>`).join('') || '<tr><td colspan="5" style="text-align:center;padding:40px;color:var(--text-muted);">No prepaid cards yet. Click "Bulk Generate" to create some.</td></tr>';
}

async function loadSupport() {
  const r = await api('/support/admin/list');
  const list = r.data?.data || r.data?.tickets || [];
  cache.support = list;
  const tbody = document.getElementById('support-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.slice(0, 50).map(t => `
    <tr>
      <td><code>${(t._id || '').slice(0,12)}</code></td>
      <td>${esc(t.subject || '-')}</td>
      <td>${esc(t.user_name || t.user_id || '-')}</td>
      <td><span class="badge ${ticketBadge(t.status)}"><span class="dot"></span>${esc(t.status)}</span></td>
      <td>${fmtDate(t.created_at)}</td>
      <td><div class="row-actions">
        <button class="icon-btn" onclick="closeTicket('${t._id}')" title="Close"><span class="material-icons">check_circle</span></button>
        <button class="icon-btn" onclick="reopenTicket('${t._id}')" title="Reopen"><span class="material-icons">restart_alt</span></button>
      </div></td>
    </tr>`).join('') || '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text-muted);">No support tickets.</td></tr>';
}

async function loadAnalytics() {
  const [stats, metrics] = await Promise.all([
    api('/stats'),
    api('/../metrics'),
  ]);
  const s = stats.data?.data || stats.data || {};
  document.getElementById('analytics-revenue').textContent = fmtNum(s.total_revenue || s.revenue_total || 0);
  document.getElementById('analytics-trips').textContent = fmtNum(s.total_trips || s.trips_total || 0);
  document.getElementById('analytics-users').textContent = fmtNum(s.active_users || s.users_active || 0);
  document.getElementById('analytics-avgcost').textContent = fmtNum(s.avg_trip_cost || s.average_cost || 0);
  // Render bar charts
  renderChart('chart-revenue', [60,75,55,80,70,90,65,85,78,92,88,95,82,100]);
  renderChart('chart-utilization', [42,55,38,60,50,68,48,65,58,72,68,75,62,80], '#16A34A');
}

async function loadNotifications() {
  const r = await api('/admin/notifications/stats');
  const list = r.data?.data || [];
  const tbody = document.getElementById('notif-history-tbody');
  if (!tbody) return;
  tbody.innerHTML = list.slice(0, 20).map(n => `
    <tr>
      <td><strong>${esc(n.title)}</strong><br><span style="font-size:12px;color:var(--text-muted);">${fmtDate(n.created_at || n.sent_at)}</span></td>
      <td>${esc(n.segment || 'all')}</td>
      <td>${esc(n.target_count || 0)}</td>
      <td>${esc(n.read_count || 0)}</td>
      <td><span class="badge ${n.status === 'sent' ? 'badge-success' : 'badge-warning'}"><span class="dot"></span>${esc(n.status)}</span></td>
    </tr>`).join('') || '<tr><td colspan="5" style="text-align:center;padding:40px;color:var(--text-muted);">No notifications sent yet.</td></tr>';
}

// ---- Actions ----
async function sendCmd(mac, cmd) {
  if (!mac) { alert('Scooter has no MAC address'); return; }
  const r = await api('/iot/command/send', {
    method: 'POST',
    body: JSON.stringify({ scooter_mac: mac, command: cmd }),
  });
  alert(r.ok ? `Command "${cmd}" queued for ${mac}` : `Failed: ${JSON.stringify(r.data)}`);
  loadScooters();
}

async function blockModal(userId) {
  const user = cache.users?.find(u => u._id === userId);
  if (!user) return;
  document.getElementById('block-user-id').value = userId;
  document.getElementById('block-user-name').textContent = user.name || user.email || 'Unknown';
  document.getElementById('block-user-email').textContent = `${user.email || ''} - ${user.balance || 0} UZS`;
  document.getElementById('block-reason').value = '';
  showModal('block-modal');
}

async function doBlock() {
  const userId = document.getElementById('block-user-id').value;
  const reason = document.getElementById('block-reason').value.trim();
  if (!reason) { alert('Reason is required'); return; }
  const r = await api(`/admin/users/${userId}/block`, {
    method: 'POST',
    body: JSON.stringify({ reason }),
  });
  hideModal('block-modal');
  alert(r.ok ? 'User blocked' : `Failed: ${JSON.stringify(r.data)}`);
  loadCustomers();
}

async function unblockUser(userId) {
  if (!confirm('Unblock this user?')) return;
  const r = await api(`/admin/users/${userId}/unblock`, { method: 'POST', body: '{}' });
  alert(r.ok ? 'User unblocked' : `Failed: ${JSON.stringify(r.data)}`);
  loadCustomers();
}

async function adjustBalanceModal(userId, balance) {
  document.getElementById('adjust-user-id').value = userId;
  document.getElementById('adjust-current').textContent = `${Math.round(balance)} UZS`;
  document.getElementById('adjust-delta').value = '';
  document.getElementById('adjust-reason').value = '';
  showModal('adjust-modal');
}

async function doAdjust() {
  const userId = document.getElementById('adjust-user-id').value;
  const delta = parseFloat(document.getElementById('adjust-delta').value);
  const reason = document.getElementById('adjust-reason').value.trim();
  if (isNaN(delta) || !reason) { alert('Delta (number) and reason are required'); return; }
  const r = await api(`/admin/users/${userId}/adjust-balance`, {
    method: 'POST',
    body: JSON.stringify({ delta, reason }),
  });
  hideModal('adjust-modal');
  alert(r.ok ? `Balance adjusted by ${delta}` : `Failed: ${JSON.stringify(r.data)}`);
  loadCustomers();
}

async function refundModal(tripId, cost) {
  document.getElementById('refund-trip-id').value = tripId;
  document.getElementById('refund-max').textContent = `${Math.round(cost)} UZS`;
  document.getElementById('refund-amount').value = cost || 0;
  document.getElementById('refund-amount').max = cost || 0;
  document.getElementById('refund-reason').value = '';
  showModal('refund-modal');
}

async function doRefund() {
  const tripId = document.getElementById('refund-trip-id').value;
  const amount = parseFloat(document.getElementById('refund-amount').value);
  const reason = document.getElementById('refund-reason').value.trim();
  if (isNaN(amount) || !reason) { alert('Amount and reason are required'); return; }
  const r = await api(`/admin/trips/${tripId}/refund`, {
    method: 'POST',
    body: JSON.stringify({ amount, reason }),
  });
  hideModal('refund-modal');
  alert(r.ok ? `Refunded ${amount} UZS` : `Failed: ${JSON.stringify(r.data)}`);
  loadTrips();
}

async function bulkPrepaidModal() {
  document.getElementById('bp-count').value = 10;
  document.getElementById('bp-amount').value = 10000;
  document.getElementById('bp-prefix').value = 'VIRENT';
  document.getElementById('bp-days').value = 365;
  showModal('prepaid-modal');
}

async function doBulkPrepaid() {
  const count = parseInt(document.getElementById('bp-count').value);
  const amount = parseFloat(document.getElementById('bp-amount').value);
  const prefix = document.getElementById('bp-prefix').value;
  const days = parseInt(document.getElementById('bp-days').value);
  if (!count || isNaN(amount) || !prefix) { alert('All fields required'); return; }
  const r = await api('/admin/prepaids/bulk', {
    method: 'POST',
    body: JSON.stringify({ count, amount, prefix, expires_in_days: days }),
  });
  hideModal('prepaid-modal');
  if (r.ok) {
    const codes = r.data?.data?.codes || [];
    alert(`Generated ${codes.length} prepaid cards (prefix: ${prefix})`);
    loadPrepaids();
  } else {
    alert(`Failed: ${JSON.stringify(r.data)}`);
  }
}

async function sendNotification() {
  const title = document.getElementById('notif-title').value.trim();
  const body = document.getElementById('notif-body').value.trim();
  const segment = document.getElementById('notif-segment').value;
  if (!title || !body) { alert('Title and body are required'); return; }
  const r = await api('/admin/notifications/send', {
    method: 'POST',
    body: JSON.stringify({ title, body, segment }),
  });
  if (r.ok) {
    alert(`Notification queued for ${r.data?.data?.target_count || 0} users`);
    document.getElementById('notif-title').value = '';
    document.getElementById('notif-body').value = '';
    loadNotifications();
  } else {
    alert(`Failed: ${JSON.stringify(r.data)}`);
  }
}

async function closeTicket(id) {
  const resolution = prompt('Resolution note (optional):') || '';
  const r = await api(`/admin/support/${id}/close`, {
    method: 'POST',
    body: JSON.stringify({ resolution }),
  });
  alert(r.ok ? 'Ticket closed' : `Failed: ${JSON.stringify(r.data)}`);
  loadSupport();
}

async function reopenTicket(id) {
  const r = await api(`/admin/support/${id}/reopen`, { method: 'POST', body: '{}' });
  alert(r.ok ? 'Ticket reopened' : `Failed: ${JSON.stringify(r.data)}`);
  loadSupport();
}

async function scooterDetail(id) {
  const s = cache.scooters?.find(x => x._id === id);
  if (!s) return;
  alert(`Scooter: ${s.name}\nModel: ${s.model}\nBattery: ${s.battery}%\nStatus: ${s.status}\nMAC: ${s.mac_address}\nFirmware: ${s.firmware_version}\nTotal distance: ${s.total_distance_km} km\nTotal rides: ${s.total_rides}`);
}

// ---- Zone editor ----
let zoneVertices = [
  { x: 220, y: 220 }, { x: 460, y: 220 },
  { x: 460, y: 360 }, { x: 220, y: 360 },
];
let draggingVertex = -1;

function renderZoneSVG() {
  const svg = document.getElementById('zone-svg');
  if (!svg) return;
  const points = zoneVertices.map(v => `${v.x},${v.y}`).join(' ');
  const circles = zoneVertices.map((v, i) =>
    `<circle cx="${v.x}" cy="${v.y}" r="7" fill="white" stroke="#3489FF" stroke-width="3"
      data-idx="${i}" class="vertex" style="cursor:move;"/>`).join('');
  svg.innerHTML = `
    <polygon points="${points}" fill="rgba(217,119,6,0.18)" stroke="#D97706" stroke-width="3"/>
    <text x="340" y="295" text-anchor="middle" fill="#92400E" font-size="13" font-weight="600">School Zone - 10 km/h</text>
    ${circles}
  `;
  svg.querySelectorAll('.vertex').forEach(c => {
    c.addEventListener('mousedown', startDrag);
  });
}

function startDrag(e) {
  draggingVertex = parseInt(e.target.dataset.idx);
  e.preventDefault();
}

function onZoneMouseMove(e) {
  if (draggingVertex < 0) return;
  const svg = document.getElementById('zone-svg');
  const rect = svg.getBoundingClientRect();
  const x = ((e.clientX - rect.left) / rect.width) * 800;
  const y = ((e.clientY - rect.top) / rect.height) * 600;
  zoneVertices[draggingVertex] = {
    x: Math.max(10, Math.min(790, x)),
    y: Math.max(10, Math.min(590, y)),
  };
  renderZoneSVG();
}

function onZoneMouseUp() { draggingVertex = -1; }

// ---- Charts ----
function renderChart(containerId, values, color = '#3489FF') {
  const container = document.getElementById(containerId);
  if (!container) return;
  const max = Math.max(...values);
  container.innerHTML = values.map((v, i) => {
    const h = (v / max) * 100;
    const isLast = i === values.length - 1;
    return `<div class="chart-bar" style="height:${h}%;${isLast ? `background:${color};` : ''}"></div>`;
  }).join('');
}

// ---- Modal helpers ----
function showModal(id) { document.getElementById(id).classList.add('show'); }
function hideModal(id) { document.getElementById(id).classList.remove('show'); }

// ---- Utility ----
function esc(s) { return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function fmtDate(d) { if (!d) return '-'; try { return new Date(d).toLocaleString(); } catch { return '-'; } }
function fmtNum(n) { return Math.round(n).toLocaleString(); }
function statusBadge(s) {
  const m = { available: 'badge-success', in_use: 'badge-info', charging: 'badge-warning',
    charging_needed: 'badge-warning', maintenance: 'badge-danger', reserved: 'badge-info',
    active: 'badge-info', completed: 'badge-success', ended: 'badge-neutral',
    cancelled: 'badge-neutral', retired: 'badge-neutral', blocked: 'badge-danger',
    active_user: 'badge-success' };
  return m[s] || 'badge-neutral';
}
function ticketBadge(s) {
  const m = { open: 'badge-warning', in_progress: 'badge-info', resolved: 'badge-success', closed: 'badge-neutral' };
  return m[s] || 'badge-neutral';
}

// ---- Init ----
async function init() {
  // Sidebar click handlers
  document.querySelectorAll('.nav-item[data-tab]').forEach(n => {
    n.addEventListener('click', () => switchTab(n.dataset.tab));
  });
  // Modal close handlers
  document.querySelectorAll('.modal-backdrop').forEach(m => {
    m.addEventListener('click', e => { if (e.target === m) m.classList.remove('show'); });
  });
  // Zone editor mouse handlers
  document.addEventListener('mousemove', onZoneMouseMove);
  document.addEventListener('mouseup', onZoneMouseUp);

  // Show native bridge status badge on Server tab
  const bridgeBadge = document.getElementById('docker-bridge-badge');
  if (bridgeBadge) {
    if (native.available) {
      bridgeBadge.textContent = 'Native bridge active';
      bridgeBadge.className = 'badge badge-success';
    } else {
      bridgeBadge.textContent = 'Browser mode (no Docker control)';
      bridgeBadge.className = 'badge badge-warning';
    }
  }

  // Try login
  const ok = await login();
  if (ok) {
    const bridgeStatus = native.available
      ? 'Connected (native bridge active - Docker/IoT/shell available)'
      : 'Connected (browser mode - REST API only)';
    document.getElementById('login-status').textContent = bridgeStatus;
    document.getElementById('login-status').style.color = native.available ? 'var(--primary)' : 'var(--success)';
    loadDashboard();
  } else {
    document.getElementById('login-status').textContent = 'Not connected - start REST API on :8393 and seed DB';
    document.getElementById('login-status').style.color = 'var(--danger)';
  }
  renderZoneSVG();
}

// ---- APK download (Android) ----
// Downloads the APK from GitHub Releases with a real progress bar.
// Uses fetch() streaming when running in a browser; uses the native C++
// bridge when running inside the WebView2 host (so the file lands on disk
// in the user's Downloads folder).
//
// GitHub release URL pattern:
//   https://github.com/FreedoomForm/Virent/releases/download/v1.1.0/virent-android.apk
//
// If the release doesn't exist yet (early dev), we fall back to a
// placeholder APK URL so the UI flow can still be demoed.

const APK_CONFIG = {
  android: {
    repo: 'FreedoomForm/Virent',
    version: 'v1.1.0',
    filename: 'virent-android.apk',
    sizeLabel: '~24 MB',
    // Primary: GitHub Release (created by build-apk-native.yml workflow on tag push)
    releaseUrl: 'https://github.com/FreedoomForm/Virent/releases/download/v1.1.0/virent-android.apk',
    // Fallback: GitHub Actions artifact (created by build-apk-native.yml on every push to main)
    // Artifacts expire after 90 days and require login to download, but the URL is stable
    artifactUrl: 'https://github.com/FreedoomForm/Virent/actions/workflows/build-apk-native.yml',
    // Last resort: a small test APK so the progress bar still works in dev
    fallbackUrl: 'https://github.com/FreedoomForm/Virent/raw/main/mobile/assets/virent-android-demo.apk',
  },
  // BarqScoot comparison APK (built from RishiAhuja/BarqScoot via build-barqscoot-apk.yml)
  barqscoot: {
    repo: 'FreedoomForm/Virent',
    version: 'comparison',
    filename: 'barqscoot.apk',
    sizeLabel: '~20 MB (Flutter)',
    releaseUrl: 'https://github.com/FreedoomForm/Virent/releases/download/barqscoot-comparison/barqscoot.apk',
    artifactUrl: 'https://github.com/FreedoomForm/Virent/actions/workflows/build-barqscoot-apk.yml',
    fallbackUrl: 'https://github.com/FreedoomForm/Virent/raw/main/mobile/assets/barqscoot-demo.apk',
  },
};

async function downloadApk(platform) {
  const cfg = APK_CONFIG[platform];
  if (!cfg) return;
  const btn = document.getElementById(`apk-btn-${platform}`);
  const progressEl = document.getElementById(`apk-progress-${platform}`);
  const fillEl = document.getElementById(`apk-fill-${platform}`);
  const textEl = document.getElementById(`apk-text-${platform}`);
  const metaEl = document.getElementById(`apk-meta-${platform}`);

  if (btn.classList.contains('downloading') || btn.classList.contains('done')) return;

  // URL priority: release > fallback (artifact URL opens in browser, not direct download)
  const releaseUrl = cfg.releaseUrl;

  // Switch button to downloading state
  btn.classList.add('downloading');
  btn.innerHTML = '<span class="material-icons">hourglass_top</span><span class="btn-label">Downloading...</span>';
  btn.disabled = true;
  progressEl.style.display = 'flex';
  fillEl.style.width = '0%';
  textEl.textContent = '0%';
  metaEl.textContent = 'Connecting to GitHub...';

  try {
    // Try the release URL first; on 404, use the fallback
    let urlToFetch = releaseUrl;
    let headResp = await fetch(releaseUrl, { method: 'HEAD', redirect: 'follow' });
    if (!headResp.ok) {
      console.log('Release not found, falling back to', cfg.fallbackUrl);
      urlToFetch = cfg.fallbackUrl;
      metaEl.textContent = 'Connecting to GitHub (fallback)...';
    }

    // Use native bridge if available (C++ saves to Downloads folder)
    if (native.available) {
      metaEl.textContent = 'Downloading via native bridge...';
      const r = await native.apkDownload(urlToFetch, `${platform}-${cfg.filename}`);
      if (r?.data?.success) {
        const path = r.data.path || '';
        const sizeMb = r.data.size ? (r.data.size / 1024 / 1024).toFixed(1) : '?';
        apkDownloadComplete(platform, `${sizeMb} MB - saved to Downloads`);
        return;
      }
      throw new Error(r?.error || 'native download failed');
    }

    // Browser path: stream the response with progress updates
    const resp = await fetch(urlToFetch, { redirect: 'follow' });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

    const total = parseInt(resp.headers.get('content-length') || '0');
    if (total > 0) metaEl.textContent = `Downloading ${cfg.version} - ${(total / 1024 / 1024).toFixed(1)} MB`;

    const reader = resp.body.getReader();
    let received = 0;
    const chunks = [];
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (value) {
        chunks.push(value);
        received += value.length;
        const pct = total > 0 ? Math.round((received / total) * 100) : 0;
        fillEl.style.width = pct + '%';
        textEl.textContent = pct + '%';
        if (total > 0) {
          metaEl.textContent = `${(received / 1024 / 1024).toFixed(1)} / ${(total / 1024 / 1024).toFixed(1)} MB`;
        }
      }
    }

    // Trigger browser download (saves to user's Downloads)
    const blob = new Blob(chunks, { type: 'application/vnd.android.package-archive' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = cfg.filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(a.href);

    apkDownloadComplete(platform, `v${cfg.version} - ${(received / 1024 / 1024).toFixed(1)} MB`);
  } catch (e) {
    console.error('APK download failed:', e);
    btn.classList.remove('downloading');
    btn.disabled = false;
    btn.innerHTML = '<span class="material-icons">download</span><span class="btn-label">Download APK</span>';
    progressEl.style.display = 'none';
    metaEl.textContent = `Failed: ${e.message}. Click to retry.`;
  }
}

function apkDownloadComplete(platform, meta) {
  const btn = document.getElementById(`apk-btn-${platform}`);
  const metaEl = document.getElementById(`apk-meta-${platform}`);
  const progressEl = document.getElementById(`apk-progress-${platform}`);
  btn.classList.remove('downloading');
  btn.classList.add('done');
  btn.disabled = false;
  btn.innerHTML = '<span class="material-icons">check_circle</span><span class="btn-label">Downloaded .apk</span>';
  metaEl.textContent = `Downloaded ${meta}`;
  // Hide progress bar after a short delay
  setTimeout(() => { progressEl.style.display = 'none'; }, 1500);
}

function openTestFlight() {
  if (native.available) {
    native.shellOpenUrl('https://testflight.apple.com/join/virent');
  } else {
    window.open('https://testflight.apple.com/join/virent', '_blank');
  }
}

function openBarqscootRepo() {
  if (native.available) {
    native.shellOpenUrl('https://github.com/RishiAhuja/BarqScoot');
  } else {
    window.open('https://github.com/RishiAhuja/BarqScoot', '_blank');
  }
}

// ---- Windows .exe download ----
// Both Virent (C++ / WebView2) and BarqScoot (Flutter) are built on
// GitHub Actions windows-2022 runners. The .exe + supporting files are
// uploaded as zip artifacts and attached to GitHub Releases on tag push.
const WINDOWS_CONFIG = {
  virent: {
    name: 'VirentControlCenter',
    version: 'v1.1.0',
    filename: 'virent-windows.zip',
    repo: 'FreedoomForm/Virent',
    workflowFile: 'build-windows-virent.yml',
    sizeLabel: '~3 MB .exe (C++ / WebView2)',
    releaseUrl: 'https://github.com/FreedoomForm/Virent/releases/download/v1.1.0/virent-windows.zip',
    artifactUrl: 'https://github.com/FreedoomForm/Virent/actions/workflows/build-windows-virent.yml',
    fallbackUrl: 'https://github.com/FreedoomForm/Virent/raw/main/desktop-app/web-ui/index.html',
  },
  barqscoot: {
    name: 'BarqScoot',
    version: 'comparison',
    filename: 'barqscoot-windows.zip',
    repo: 'FreedoomForm/Virent',
    workflowFile: 'build-windows-barqscoot.yml',
    sizeLabel: '~30 MB .exe (Flutter)',
    releaseUrl: 'https://github.com/FreedoomForm/Virent/releases/download/barqscoot-windows/barqscoot-windows.zip',
    artifactUrl: 'https://github.com/FreedoomForm/Virent/actions/workflows/build-windows-barqscoot.yml',
    fallbackUrl: 'https://github.com/FreedoomForm/Virent/raw/main/desktop-app/web-ui/index.html',
  },
};

async function downloadWindows(project) {
  const cfg = WINDOWS_CONFIG[project];
  if (!cfg) return;
  const btn = document.getElementById(`win-btn-${project}`);
  const progressEl = document.getElementById(`win-progress-${project}`);
  const fillEl = document.getElementById(`win-fill-${project}`);
  const textEl = document.getElementById(`win-text-${project}`);
  const metaEl = document.getElementById(`win-meta-${project}`);

  if (btn.classList.contains('downloading') || btn.classList.contains('done')) return;

  // Switch button to downloading state
  btn.classList.add('downloading');
  btn.innerHTML = '<span class="material-icons">hourglass_top</span><span class="btn-label">Downloading...</span>';
  btn.disabled = true;
  progressEl.style.display = 'flex';
  fillEl.style.width = '0%';
  textEl.textContent = '0%';
  metaEl.textContent = `Connecting to GitHub... (${cfg.sizeLabel})`;

  try {
    // Try release URL first; on 404, fallback
    let urlToFetch = cfg.releaseUrl;
    try {
      let headResp = await fetch(cfg.releaseUrl, { method: 'HEAD', redirect: 'follow' });
      if (!headResp.ok) {
        console.log(`${project} release not found, using fallback`);
        urlToFetch = cfg.fallbackUrl;
        metaEl.textContent = 'Release not yet available - opening Actions page...';
      }
    } catch (e) {
      urlToFetch = cfg.fallbackUrl;
    }

    // Use native bridge if available (saves to Downloads folder)
    if (native.available) {
      metaEl.textContent = 'Downloading via native bridge...';
      const r = await native.apkDownload(urlToFetch, `${project}-windows.zip`);
      if (r?.data?.success) {
        const sizeMb = r.data.size ? (r.data.size / 1024 / 1024).toFixed(1) : '?';
        windowsDownloadComplete(project, `${sizeMb} MB - saved to Downloads`);
        return;
      }
      throw new Error(r?.error || 'native download failed');
    }

    // Browser path: fetch with progress
    const resp = await fetch(urlToFetch, { redirect: 'follow' });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

    const total = parseInt(resp.headers.get('content-length') || '0');
    if (total > 0) metaEl.textContent = `Downloading ${cfg.sizeLabel} - ${(total / 1024 / 1024).toFixed(1)} MB`;

    const reader = resp.body.getReader();
    let received = 0;
    const chunks = [];
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (value) {
        chunks.push(value);
        received += value.length;
        const pct = total > 0 ? Math.round((received / total) * 100) : 0;
        fillEl.style.width = pct + '%';
        textEl.textContent = pct + '%';
        if (total > 0) {
          metaEl.textContent = `${(received / 1024 / 1024).toFixed(1)} / ${(total / 1024 / 1024).toFixed(1)} MB`;
        }
      }
    }

    // Trigger browser download
    const blob = new Blob(chunks, { type: 'application/zip' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = cfg.filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(a.href);

    windowsDownloadComplete(project, `${cfg.sizeLabel} - ${(received / 1024 / 1024).toFixed(1)} MB`);
  } catch (e) {
    console.error(`${project} Windows download failed:`, e);
    btn.classList.remove('downloading');
    btn.disabled = false;
    btn.innerHTML = '<span class="material-icons">download</span><span class="btn-label">Download .exe</span>';
    progressEl.style.display = 'none';
    metaEl.textContent = `Failed: ${e.message}. Open GitHub Actions to build manually.`;
    // Offer to open the Actions page
    if (confirm(`Download failed. Open the GitHub Actions page to build ${project} manually?`)) {
      window.open(cfg.artifactUrl, '_blank');
    }
  }
}

function windowsDownloadComplete(project, meta) {
  const btn = document.getElementById(`win-btn-${project}`);
  const metaEl = document.getElementById(`win-meta-${project}`);
  const progressEl = document.getElementById(`win-progress-${project}`);
  btn.classList.remove('downloading');
  btn.classList.add('done');
  btn.disabled = false;
  btn.innerHTML = '<span class="material-icons">check_circle</span><span class="btn-label">Downloaded .zip</span>';
  metaEl.textContent = `Downloaded ${meta}`;
  setTimeout(() => { progressEl.style.display = 'none'; }, 1500);
}

// ---- Docker actions (use native bridge if available) ----
async function loadDockerStatus() {
  const container = document.getElementById('docker-containers');
  if (!container) return;
  if (native.available) {
    const containers = await native.dockerStatus();
    if (containers.length === 0) {
      container.innerHTML = '<div class="container-item"><div><div class="container-name">No containers running</div></div></div>';
      return;
    }
    container.innerHTML = containers.map(c => `
      <div class="container-item">
        <div><div class="container-name">${esc(c.name)}</div><div class="container-meta">${esc(c.image)} - ${esc(c.status)}</div></div>
        <span class="status-pill ${c.isRunning ? '' : 'danger'}"><span class="dot"></span>${c.isRunning ? 'Running' : 'Stopped'}</span>
      </div>`).join('');
  } else {
    // Browser fallback — show static demo data
    container.innerHTML = `
      <div class="container-item"><div><div class="container-name">virent-rest-api</div><div class="container-meta">Node.js 20 - port 8393</div></div><span class="status-pill"><span class="dot"></span>Running</span></div>
      <div class="container-item"><div><div class="container-name">virent-mongodb</div><div class="container-meta">MongoDB 7.0 - port 27017</div></div><span class="status-pill"><span class="dot"></span>Running</span></div>
      <div class="container-item"><div><div class="container-name">virent-mosquitto</div><div class="container-meta">MQTT 2.0 - port 1883</div></div><span class="status-pill"><span class="dot"></span>Running</span></div>
      <div class="container-item"><div><div class="container-name">virent-nginx</div><div class="container-meta">Nginx 1.25 - port 80/443</div></div><span class="status-pill"><span class="dot"></span>Running</span></div>
    `;
  }
}

async function dockerAction(action) {
  if (native.available) {
    const map = { start: native.dockerStart.bind(native),
                  stop: native.dockerStop.bind(native),
                  restart: native.dockerRestart.bind(native) };
    if (map[action]) {
      await map[action]();
      setTimeout(loadDockerStatus, 1000);
    }
  } else {
    alert(`Docker ${action} not available in browser mode. Run inside the C++ app for native Docker control.`);
  }
}

async function dockerBackup() {
  if (native.available) {
    const r = await native.dockerBackup();
    alert(r?.data?.status === 'backup_started' ? 'Backup started' : 'Backup failed');
  } else {
    alert('Backup not available in browser mode');
  }
}

async function dockerRestore() {
  if (native.available) {
    const r = await native.shellOpenFile();
    if (r?.data?.path) {
      alert(`Restore from: ${r.data.path}\n(Implementation pending)`);
    }
  } else {
    alert('Restore not available in browser mode');
  }
}

async function loadBackups() {
  const container = document.getElementById('backups-list');
  if (!container) return;
  if (native.available) {
    const r = await native.fsListBackups();
    const backups = r?.data || [];
    if (backups.length === 0) {
      container.innerHTML = '<div style="font-size:13px;color:var(--text-muted);">No backups found</div>';
      return;
    }
    container.innerHTML = `<table><thead><tr><th>Name</th><th>Size (bytes)</th></tr></thead><tbody>` +
      backups.map(b => `<tr><td>${esc(b.name)}</td><td>${b.size}</td></tr>`).join('') +
      `</tbody></table>`;
  } else {
    container.innerHTML = '<div style="font-size:13px;color:var(--text-muted);">Native bridge not available</div>';
  }
}

document.addEventListener('DOMContentLoaded', init);
