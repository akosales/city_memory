/* ================================================
   City Memory Dispatch System - JavaScript
   ================================================ */

let categories = {};
let calls = [];
let myCalls = [];
let selectedCategory = null;
let currentJob = null;

// ================================================
// Message Handler
// ================================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'openCallUI':
            openCallUI();
            break;

        case 'openDispatchUI':
            currentJob = data.job;
            openDispatchUI();
            break;

        case 'closeAll':
            closeAll();
            break;

        case 'setCategories':
            categories = data.categories;
            renderCategories();
            break;

        case 'setCalls':
            calls = data.calls;
            renderCalls();
            break;

        case 'setMyCalls':
            myCalls = data.calls;
            renderMyCalls();
            break;

        case 'setOnlineUnits':
            updateOnlineUnits(data.units);
            break;

        case 'newCall':
            addNewCall(data.call);
            break;

        case 'updateCall':
            updateCall(data.call);
            break;

        case 'removeCall':
            removeCall(data.callId);
            break;

        case 'showNotification':
            showNotification(data.title, data.message, data.urgent);
            break;

        case 'showCallNotification':
            showCallNotification(data.call);
            break;
    }
});

// ================================================
// Call UI (Zivilist)
// ================================================

function openCallUI() {
    document.getElementById('call-ui').classList.remove('hidden');
    selectedCategory = null;
    document.getElementById('call-message').value = '';
    document.getElementById('anonymous-check').checked = false;
    document.getElementById('submit-call').disabled = true;
}

function renderCategories() {
    const grid = document.getElementById('category-grid');
    grid.innerHTML = '';

    const categoryOrder = ['shooting', 'robbery', 'assault', 'medical', 'accident', 'fire', 'theft', 'suspicious', 'other'];

    categoryOrder.forEach(key => {
        if (categories[key]) {
            const cat = categories[key];
            const item = document.createElement('div');
            item.className = 'category-item';
            item.dataset.category = key;
            item.innerHTML = `
                <div class="category-icon">${cat.icon}</div>
                <div class="category-label">${cat.label}</div>
            `;
            item.onclick = () => selectCategory(key, item);
            grid.appendChild(item);
        }
    });
}

function selectCategory(key, element) {
    document.querySelectorAll('.category-item').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');
    selectedCategory = key;
    document.getElementById('submit-call').disabled = false;
}

function submitCall() {
    if (!selectedCategory) return;

    const message = document.getElementById('call-message').value.trim();
    const anonymous = document.getElementById('anonymous-check').checked;

    fetch('https://city_memory/submitCall', {
        method: 'POST',
        body: JSON.stringify({
            category: selectedCategory,
            message: message,
            anonymous: anonymous
        })
    });
}

document.getElementById('submit-call').addEventListener('click', submitCall);

// ================================================
// Dispatch UI
// ================================================

function openDispatchUI() {
    document.getElementById('dispatch-ui').classList.remove('hidden');
    updateDateTime();
    setInterval(updateDateTime, 1000);
}

function updateDateTime() {
    const now = new Date();
    const formatted = now.toLocaleDateString('de-DE') + ' ' + now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
    document.getElementById('datetime').textContent = formatted;
}

function updateOnlineUnits(units) {
    document.getElementById('police-count').textContent = units.police;
    document.getElementById('ems-count').textContent = units.ems;
}

function renderCalls() {
    const container = document.getElementById('calls-container');

    // Apply filters
    const priorityFilter = document.getElementById('filter-priority').value;
    const statusFilter = document.getElementById('filter-status').value;

    let filteredCalls = calls.filter(call => {
        if (priorityFilter !== 'all' && call.priority !== priorityFilter) return false;
        if (statusFilter !== 'all' && call.status !== statusFilter) return false;
        return true;
    });

    document.getElementById('calls-count').textContent = filteredCalls.length;

    if (filteredCalls.length === 0) {
        container.innerHTML = `
            <div class="no-calls-main">
                <div class="no-calls-icon">📭</div>
                <div class="no-calls-text">Keine aktiven Notrufe</div>
            </div>
        `;
        return;
    }

    container.innerHTML = filteredCalls.map(call => renderCallCard(call)).join('');
}

function renderCallCard(call) {
    const timeAgo = getTimeAgo(call.createdAt);
    const statusText = getStatusText(call.status);
    const isMyCall = myCalls.some(c => c.id === call.id);

    let actionsHtml = '';
    if (call.status === 'open') {
        actionsHtml = `
            <button class="btn btn-small btn-accept" onclick="acceptCall(${call.id})">🚔 Annehmen</button>
            <button class="btn btn-small btn-route" onclick="setWaypoint(${call.location.coords.x}, ${call.location.coords.y})">📍 Route</button>
        `;
    } else if (isMyCall) {
        if (call.status === 'accepted' || call.status === 'enroute') {
            actionsHtml = `
                <button class="btn btn-small btn-route" onclick="updateStatus(${call.id}, 'onscene')">🏁 Vor Ort</button>
                <button class="btn btn-small btn-backup" onclick="requestBackup(${call.id})">👥 Backup</button>
            `;
        } else if (call.status === 'onscene') {
            actionsHtml = `
                <button class="btn btn-small btn-complete" onclick="closeCall(${call.id})">✅ Abschließen</button>
                <button class="btn btn-small btn-backup" onclick="requestBackup(${call.id})">👥 Backup</button>
            `;
        }
    } else {
        actionsHtml = `
            <button class="btn btn-small btn-accept" onclick="acceptCall(${call.id})">🚔 Übernehmen</button>
            <button class="btn btn-small btn-route" onclick="setWaypoint(${call.location.coords.x}, ${call.location.coords.y})">📍 Route</button>
        `;
    }

    // Assigned units
    let unitsHtml = '';
    if (call.assignedUnits && call.assignedUnits.length > 0) {
        unitsHtml = `
            <div class="assigned-units">
                ${call.assignedUnits.map(unit => `
                    <span class="unit-badge status-${unit.status}">${unit.name}</span>
                `).join('')}
            </div>
        `;
    }

    return `
        <div class="call-card priority-${call.priority}">
            <div class="call-card-header">
                <div class="call-priority">
                    <span class="priority-badge">${getPriorityText(call.priority)}</span>
                    <span style="font-size: 18px;">${call.categoryIcon}</span>
                    <span style="font-weight: 600; color: #fff;">${call.categoryLabel}</span>
                </div>
                <div class="call-id">ID: #${call.id}</div>
            </div>
            <div class="call-card-body">
                <div class="call-info-item">
                    <div class="call-info-icon">📍</div>
                    <div class="call-info-content">
                        <div class="call-info-label">Standort</div>
                        <div class="call-info-value">${call.location.zone}</div>
                        ${call.location.street && call.location.street.trim() !== '' ? `<div class="call-info-value" style="color: #888; font-size: 11px;">${call.location.street}</div>` : ''}
                    </div>
                </div>
                <div class="call-info-item">
                    <div class="call-info-icon">👤</div>
                    <div class="call-info-content">
                        <div class="call-info-label">Anrufer</div>
                        <div class="call-info-value">${call.caller.name}</div>
                    </div>
                </div>
                <div class="call-info-item">
                    <div class="call-info-icon">⏱️</div>
                    <div class="call-info-content">
                        <div class="call-info-label">Zeit</div>
                        <div class="call-info-value">${timeAgo}</div>
                    </div>
                </div>
                <div class="call-info-item">
                    <div class="call-info-icon">👥</div>
                    <div class="call-info-content">
                        <div class="call-info-label">Einheiten</div>
                        ${unitsHtml || '<div class="call-info-value" style="color: #888;">Keine</div>'}
                    </div>
                </div>
                ${call.message ? `
                    <div class="call-info-item full-width">
                        <div class="call-info-icon">💬</div>
                        <div class="call-info-content">
                            <div class="call-info-label">Meldung</div>
                            <div class="call-info-value call-message">"${call.message}"</div>
                        </div>
                    </div>
                ` : ''}
            </div>
            <div class="call-card-footer">
                <div class="call-status status-${call.status}">
                    <span class="status-dot"></span>
                    <span>${statusText}</span>
                </div>
                <div class="call-actions">
                    ${actionsHtml}
                </div>
            </div>
        </div>
    `;
}

function renderMyCalls() {
    const container = document.getElementById('my-calls-list');

    if (myCalls.length === 0) {
        container.innerHTML = '<div class="no-calls">Keine aktiven Einsätze</div>';
        return;
    }

    container.innerHTML = myCalls.map(call => {
        const myUnit = call.assignedUnits.find(u => u.status !== 'completed');
        const status = myUnit ? myUnit.status : call.status;

        return `
            <div class="my-call-item" onclick="scrollToCall(${call.id})">
                <div class="my-call-id">#${call.id}</div>
                <div class="my-call-category">${call.categoryIcon} ${call.categoryLabel}</div>
                <div class="my-call-status status-${status}">${getStatusText(status)}</div>
            </div>
        `;
    }).join('');
}

// ================================================
// Actions
// ================================================

function acceptCall(callId) {
    fetch('https://city_memory/acceptCall', {
        method: 'POST',
        body: JSON.stringify({ callId: callId })
    });
}

function updateStatus(callId, status) {
    fetch('https://city_memory/updateStatus', {
        method: 'POST',
        body: JSON.stringify({ callId: callId, status: status })
    });
}

function closeCall(callId) {
    fetch('https://city_memory/closeCall', {
        method: 'POST',
        body: JSON.stringify({ callId: callId })
    });
}

function requestBackup(callId) {
    fetch('https://city_memory/requestBackup', {
        method: 'POST',
        body: JSON.stringify({ callId: callId })
    });
}

function setWaypoint(x, y) {
    fetch('https://city_memory/setWaypoint', {
        method: 'POST',
        body: JSON.stringify({ x: x, y: y })
    });
}

function refreshCalls() {
    fetch('https://city_memory/refreshCalls', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function scrollToCall(callId) {
    const container = document.getElementById('calls-container');
    const card = container.querySelector(`[data-callid="${callId}"]`);
    if (card) {
        card.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
}

// ================================================
// Live Updates
// ================================================

function addNewCall(call) {
    calls.unshift(call);
    renderCalls();
}

function updateCall(call) {
    const index = calls.findIndex(c => c.id === call.id);
    if (index !== -1) {
        calls[index] = call;
    } else {
        calls.unshift(call);
    }
    renderCalls();

    // Update my calls too
    const myIndex = myCalls.findIndex(c => c.id === call.id);
    if (myIndex !== -1) {
        myCalls[myIndex] = call;
        renderMyCalls();
    }
}

function removeCall(callId) {
    calls = calls.filter(c => c.id !== callId);
    myCalls = myCalls.filter(c => c.id !== callId);
    renderCalls();
    renderMyCalls();
}

// ================================================
// Notifications
// ================================================

function showNotification(title, message, urgent) {
    const container = document.getElementById('notification-container');

    const notif = document.createElement('div');
    notif.className = 'notification' + (urgent ? ' urgent' : '');
    notif.innerHTML = `
        <div class="notification-title">${escapeHtml(title)}</div>
        <div class="notification-message">${escapeHtml(message)}</div>
    `;

    container.appendChild(notif);

    setTimeout(() => {
        notif.style.opacity = '0';
        notif.style.transform = 'translateX(100%)';
        setTimeout(() => notif.remove(), 300);
    }, 5000);
}

function showCallNotification(call) {
    const notif = document.getElementById('call-notification');

    notif.querySelector('.call-notif-category').textContent = call.categoryIcon + ' ' + call.categoryLabel;
    notif.querySelector('.call-notif-location').textContent = '📍 ' + call.location.zone;
    notif.querySelector('.call-notif-message').textContent = call.message ? '"' + call.message + '"' : '';

    notif.classList.remove('hidden');

    setTimeout(() => {
        notif.classList.add('hidden');
    }, 8000);
}

// ================================================
// Close UI
// ================================================

function closeUI() {
    fetch('https://city_memory/closeUI', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function closeAll() {
    document.getElementById('call-ui').classList.add('hidden');
    document.getElementById('dispatch-ui').classList.add('hidden');
    document.getElementById('call-notification').classList.add('hidden');
}

// ================================================
// Helpers
// ================================================

function getTimeAgo(timestamp) {
    const now = Math.floor(Date.now() / 1000);
    const diff = now - timestamp;

    if (diff < 60) return 'vor ' + diff + ' Sek';
    if (diff < 3600) return 'vor ' + Math.floor(diff / 60) + ' Min';
    return 'vor ' + Math.floor(diff / 3600) + ' Std';
}

function getPriorityText(priority) {
    switch(priority) {
        case 'high': return '🔴 HOCH';
        case 'medium': return '🟡 MITTEL';
        case 'low': return '🟢 NIEDRIG';
        default: return priority;
    }
}

function getStatusText(status) {
    switch(status) {
        case 'open': return 'Offen';
        case 'accepted': return 'Angenommen';
        case 'enroute': return 'Unterwegs';
        case 'onscene': return 'Vor Ort';
        case 'completed': return 'Abgeschlossen';
        default: return status;
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ================================================
// Filter Events
// ================================================

document.getElementById('filter-priority').addEventListener('change', renderCalls);
document.getElementById('filter-status').addEventListener('change', renderCalls);

// ================================================
// Keyboard
// ================================================

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeUI();
    }
});
