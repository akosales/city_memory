/* ================================================
   City Memory - MDT & Admin JavaScript
   v2.4 - Mit Event-Labels und Fahndungs-Button
   ================================================ */

let searchType = 'person';
let currentPersonDetail = null;
let currentPersonName = null;
let confirmAction = null;

// ================================================
// MDT Functions
// ================================================

function switchMDTTab(tab) {
    document.querySelectorAll('.mdt-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.mdt-nav-btn').forEach(b => b.classList.remove('active'));

    document.getElementById('tab-' + tab).classList.add('active');
    document.querySelector(`.mdt-nav-btn[data-tab="${tab}"]`).classList.add('active');
}

function setSearchType(type) {
    searchType = type;
    document.querySelectorAll('.search-type-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`.search-type-btn[data-type="${type}"]`).classList.add('active');

    const input = document.getElementById('mdt-search-input');
    if (type === 'person') {
        input.placeholder = 'Name oder ID eingeben...';
    } else {
        input.placeholder = 'Kennzeichen eingeben...';
    }
}

function handleSearchKeyup(event) {
    if (event.key === 'Enter') {
        performSearch();
    }
}

function performSearch() {
    const query = document.getElementById('mdt-search-input').value.trim();
    if (!query) return;

    const resultsContainer = document.getElementById('search-results');
    resultsContainer.innerHTML = '<div class="search-placeholder"><div class="placeholder-icon">⏳</div><div class="placeholder-text">Suche läuft...</div></div>';

    if (searchType === 'person') {
        fetch('https://city_memory/mdt:searchPerson', {
            method: 'POST',
            body: JSON.stringify({ query: query })
        });
    } else {
        fetch('https://city_memory/mdt:searchVehicle', {
            method: 'POST',
            body: JSON.stringify({ plate: query })
        });
    }
}

function openPersonDetail(identifier, name) {
    currentPersonDetail = identifier;
    currentPersonName = name || 'Unbekannt';
    fetch('https://city_memory/mdt:getPersonDetails', {
        method: 'POST',
        body: JSON.stringify({ identifier: identifier })
    });
    fetch('https://city_memory/mdt:getPersonNotes', {
        method: 'POST',
        body: JSON.stringify({ identifier: identifier })
    });
}

function closePersonDetail() {
    document.getElementById('person-detail').classList.add('hidden');
    currentPersonDetail = null;
    currentPersonName = null;
}

function openCreateWanted() {
    document.getElementById('create-wanted-modal').classList.remove('hidden');
}

function closeCreateWanted() {
    document.getElementById('create-wanted-modal').classList.add('hidden');
}

function openCreateWantedForPerson() {
    if (!currentPersonName) return;

    document.getElementById('wanted-type').value = 'person';
    document.getElementById('wanted-target').value = currentPersonName;
    document.getElementById('wanted-reason').value = '';
    openCreateWanted();
}

function submitWanted() {
    const type = document.getElementById('wanted-type').value;
    const target = document.getElementById('wanted-target').value.trim();
    const reason = document.getElementById('wanted-reason').value.trim();

    if (!target || !reason) {
        alert('Bitte alle Felder ausfüllen');
        return;
    }

    fetch('https://city_memory/mdt:createWanted', {
        method: 'POST',
        body: JSON.stringify({ type, target, reason })
    });

    closeCreateWanted();
    document.getElementById('wanted-target').value = '';
    document.getElementById('wanted-reason').value = '';
}

function removeWanted(id) {
    fetch('https://city_memory/mdt:removeWanted', {
        method: 'POST',
        body: JSON.stringify({ id: id })
    });
}

function addNote() {
    const input = document.getElementById('note-input');
    const note = input.value.trim();
    if (!note || !currentPersonDetail) return;

    fetch('https://city_memory/mdt:addNote', {
        method: 'POST',
        body: JSON.stringify({ identifier: currentPersonDetail, note: note })
    });

    input.value = '';
}

// ================================================
// Admin Functions
// ================================================

function switchAdminTab(tab) {
    document.querySelectorAll('.admin-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.admin-nav-btn').forEach(b => b.classList.remove('active'));

    document.getElementById('admin-tab-' + tab).classList.add('active');
    document.querySelector(`.admin-nav-btn[data-tab="${tab}"]`).classList.add('active');
}

function refreshAdminStats() {
    fetch('https://city_memory/admin:refreshStats', { method: 'POST', body: '{}' });
}

function refreshLogs() {
    const limit = document.getElementById('logs-limit').value;
    fetch('https://city_memory/admin:refreshLogs', { method: 'POST', body: JSON.stringify({ limit: parseInt(limit) }) });
}

function confirmReset(dataType) {
    confirmAction = dataType;
    document.getElementById('confirm-title').textContent = 'Daten zurücksetzen?';
    document.getElementById('confirm-message').textContent = `Möchtest du wirklich alle ${dataType}-Daten zurücksetzen? Diese Aktion kann nicht rückgängig gemacht werden!`;
    document.getElementById('confirm-modal').classList.remove('hidden');
}

function closeConfirm() {
    document.getElementById('confirm-modal').classList.add('hidden');
    confirmAction = null;
}

function executeConfirm() {
    if (confirmAction) {
        fetch('https://city_memory/admin:resetData', {
            method: 'POST',
            body: JSON.stringify({ dataType: confirmAction })
        });
    }
    closeConfirm();
}

function closeMDT() {
    fetch('https://city_memory/closeMDT', { method: 'POST', body: '{}' });
}

function closeAdmin() {
    fetch('https://city_memory/closeAdmin', { method: 'POST', body: '{}' });
}

// ================================================
// Message Handler Extensions
// ================================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'openMDT':
            document.getElementById('mdt-ui').classList.remove('hidden');
            updateMDTDateTime();
            break;

        case 'closeMDT':
            document.getElementById('mdt-ui').classList.add('hidden');
            break;

        case 'openAdmin':
            document.getElementById('admin-ui').classList.remove('hidden');
            break;

        case 'closeAdmin':
            document.getElementById('admin-ui').classList.add('hidden');
            break;

        case 'mdt:personResults':
            renderPersonResults(data.results);
            break;

        case 'mdt:personDetails':
            renderPersonDetail(data.data);
            break;

        case 'mdt:vehicleResults':
            renderVehicleResult(data.data);
            break;

        case 'mdt:personNotes':
            renderNotes(data.notes);
            break;

        case 'mdt:wantedList':
            renderWantedList(data.wanted);
            break;

        case 'mdt:wantedRemoved':
            document.querySelector(`.wanted-card[data-id="${data.id}"]`)?.remove();
            break;

        case 'mdt:statistics':
            renderMDTStats(data.stats);
            break;

        case 'admin:statistics':
            renderAdminStats(data.stats);
            break;

        case 'admin:logs':
            renderLogs(data.logs);
            break;

        case 'admin:allCalls':
            renderAdminCalls(data.calls);
            break;
    }
});

// ================================================
// Render Functions
// ================================================

function renderPersonResults(results) {
    const container = document.getElementById('search-results');

    if (!results || results.length === 0) {
        container.innerHTML = '<div class="search-placeholder"><div class="placeholder-icon">❌</div><div class="placeholder-text">Keine Ergebnisse gefunden</div></div>';
        return;
    }

    container.innerHTML = results.map(r => `
        <div class="result-card" onclick="openPersonDetail('${r.identifier}', '${escapeHtml(r.name)}')">
            <div class="result-card-header">
                <div class="result-name">
                    ${escapeHtml(r.name)}
                    ${r.online ? '<span class="online-badge"></span>' : '<span class="offline-badge"></span>'}
                </div>
                <span class="result-risk ${r.risk}">${getRiskLabel(r.risk)}</span>
            </div>
            <div class="result-info">
                ${r.job ? `<span>💼 ${r.job}</span>` : ''}
                ${r.online ? '<span>🟢 Online</span>' : '<span>⚫ Offline</span>'}
            </div>
        </div>
    `).join('');
}

function renderPersonDetail(data) {
    if (!data) return;

    const container = document.getElementById('person-detail-content');
    const profile = data.profile || {};

    // Name speichern für Fahndung
    if (data.onlinePlayer?.name) {
        currentPersonName = data.onlinePlayer.name;
    }

    container.innerHTML = `
        <div class="detail-section">
            <div class="detail-section-title">Grunddaten</div>
            <div class="detail-grid">
                <div class="detail-item">
                    <div class="detail-label">Name</div>
                    <div class="detail-value">${data.onlinePlayer ? data.onlinePlayer.name : 'Unbekannt'}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Status</div>
                    <div class="detail-value">${data.online ? '🟢 Online' : '⚫ Offline'}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Risiko</div>
                    <div class="detail-value" style="color: ${getRiskColor(data.risk)}">${getRiskLabel(data.risk)}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Beruf</div>
                    <div class="detail-value">${data.onlinePlayer?.job || '-'}</div>
                </div>
            </div>
        </div>
        
        <div class="detail-section">
            <div class="detail-section-title">Profil-Analyse</div>
            <div class="detail-grid">
                <div class="detail-item">
                    <div class="detail-label">Reputation</div>
                    <div class="detail-value">${((profile.reputation || 0.5) * 100).toFixed(0)}%</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Gewaltbereitschaft</div>
                    <div class="detail-value">${((profile.violence_tendency || 0) * 100).toFixed(0)}%</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Fluchtgefahr</div>
                    <div class="detail-value">${((profile.flee_tendency || 0) * 100).toFixed(0)}%</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Kooperation</div>
                    <div class="detail-value">${((profile.cooperation || 0.5) * 100).toFixed(0)}%</div>
                </div>
            </div>
        </div>
        
        <div class="detail-section">
            <div class="detail-section-title">Letzte Vorfälle</div>
            <div class="event-list">
                ${data.events.length > 0 ? data.events.map(e => `
                    <div class="event-item">
                        <span class="event-type">${getEventLabel(e.event_type)}</span>
                        <span class="event-time">${formatDate(e.created_at)}</span>
                    </div>
                `).join('') : '<div style="color: #888; padding: 10px;">Keine Vorfälle</div>'}
            </div>
        </div>
        
        <div class="detail-section">
            <div class="detail-section-title">Aktionen</div>
            <div class="detail-actions">
                <button class="btn btn-danger" onclick="openCreateWantedForPerson()">
                    🚨 Zur Fahndung ausschreiben
                </button>
            </div>
        </div>
        
        <div class="detail-section">
            <div class="detail-section-title">Notizen</div>
            <div class="notes-list" id="notes-list"></div>
            <div class="add-note-form">
                <input type="text" id="note-input" placeholder="Notiz hinzufügen...">
                <button class="btn btn-small btn-submit" onclick="addNote()">Hinzufügen</button>
            </div>
        </div>
    `;

    document.getElementById('person-detail').classList.remove('hidden');
}

function renderNotes(notes) {
    const container = document.getElementById('notes-list');
    if (!container) return;

    if (!notes || notes.length === 0) {
        container.innerHTML = '<div style="color: #888; padding: 10px;">Keine Notizen</div>';
        return;
    }

    container.innerHTML = notes.map(n => `
        <div class="note-item">
            <div class="note-text">${escapeHtml(n.note)}</div>
            <div class="note-meta">${n.created_by_name} - ${formatDate(n.created_at)}</div>
        </div>
    `).join('');
}

function renderVehicleResult(data) {
    const container = document.getElementById('search-results');

    if (!data || !data.plate) {
        container.innerHTML = '<div class="search-placeholder"><div class="placeholder-icon">❌</div><div class="placeholder-text">Fahrzeug nicht gefunden</div></div>';
        return;
    }

    const history = data.history || {};

    container.innerHTML = `
        <div class="result-card" style="cursor: default;">
            <div class="result-card-header">
                <div class="result-name">🚗 ${data.plate}</div>
                <span class="result-risk ${data.risk}">${data.flagged ? '🚨 MARKIERT' : getRiskLabel(data.risk)}</span>
            </div>
            <div style="margin-top: 15px;">
                <div class="detail-grid">
                    <div class="detail-item">
                        <div class="detail-label">Heat</div>
                        <div class="detail-value">${((history.heat || 0) * 100).toFixed(0)}%</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Verfolgungen</div>
                        <div class="detail-value">${history.chaseCount || 0}</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Kriminalität</div>
                        <div class="detail-value">${((history.crimeAssociation || 0) * 100).toFixed(0)}%</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Letzter Vorfall</div>
                        <div class="detail-value">${history.lastIncident ? formatDate(history.lastIncident) : '-'}</div>
                    </div>
                </div>
            </div>
            ${data.events && data.events.length > 0 ? `
                <div style="margin-top: 15px;">
                    <div class="detail-section-title">Letzte Events</div>
                    <div class="event-list">
                        ${data.events.slice(0, 5).map(e => `
                            <div class="event-item">
                                <span class="event-type">${getEventLabel(e.event_type)}</span>
                                <span class="event-time">${formatDate(e.created_at)}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            ` : ''}
            <div style="margin-top: 15px;">
                <button class="btn btn-danger" onclick="openCreateWantedForVehicle('${data.plate}')">
                    🚨 Zur Fahndung ausschreiben
                </button>
            </div>
        </div>
    `;
}

function openCreateWantedForVehicle(plate) {
    document.getElementById('wanted-type').value = 'vehicle';
    document.getElementById('wanted-target').value = plate;
    document.getElementById('wanted-reason').value = '';
    openCreateWanted();
}

function renderWantedList(wanted) {
    const container = document.getElementById('wanted-list');

    if (!wanted || wanted.length === 0) {
        container.innerHTML = '<div class="search-placeholder"><div class="placeholder-icon">✅</div><div class="placeholder-text">Keine aktiven Fahndungen</div></div>';
        return;
    }

    container.innerHTML = wanted.map(w => `
        <div class="wanted-card" data-id="${w.id}">
            <div class="wanted-card-header">
                <span class="wanted-type">${w.type === 'person' ? '👤 Person' : '🚗 Fahrzeug'}</span>
                <span class="wanted-id">#${w.id}</span>
            </div>
            <div class="wanted-target">${escapeHtml(w.target)}</div>
            <div class="wanted-reason">${escapeHtml(w.reason)}</div>
            <div class="wanted-meta">
                <span>Erstellt von: ${w.created_by_name}</span>
                <button class="wanted-remove" onclick="removeWanted(${w.id})">❌ Aufheben</button>
            </div>
        </div>
    `).join('');
}

function renderMDTStats(stats) {
    document.getElementById('stat-calls-today').textContent = stats.callsToday || 0;
    document.getElementById('stat-calls-week').textContent = stats.callsWeek || 0;
    document.getElementById('stat-high-risk').textContent = stats.highRiskPersons || 0;
    document.getElementById('stat-flagged-vehicles').textContent = stats.flaggedVehicles || 0;

    // Hotspots
    const hotspotsContainer = document.getElementById('hotspots-list');
    if (stats.hotZones && stats.hotZones.length > 0) {
        hotspotsContainer.innerHTML = stats.hotZones.map(z => {
            const heat = parseFloat(z.heat) || 0;
            const heatClass = heat > 0.6 ? 'high' : (heat > 0.3 ? 'medium' : 'low');
            return `
                <div class="hotspot-item">
                    <span class="hotspot-name">${z.zone_id}</span>
                    <div class="hotspot-heat">
                        <div class="hotspot-heat-fill ${heatClass}" style="width: ${heat * 100}%"></div>
                    </div>
                    <span style="font-size: 12px; color: #888;">${(heat * 100).toFixed(0)}%</span>
                </div>
            `;
        }).join('');
    } else {
        hotspotsContainer.innerHTML = '<div style="color: #888;">Keine aktiven Hotspots</div>';
    }
}

function renderAdminStats(stats) {
    document.getElementById('admin-total-profiles').textContent = stats.totalProfiles || 0;
    document.getElementById('admin-total-vehicles').textContent = stats.totalVehicles || 0;
    document.getElementById('admin-total-calls').textContent = stats.totalCalls || 0;
    document.getElementById('admin-total-zone-events').textContent = stats.totalZoneEvents || 0;
    document.getElementById('admin-total-player-events').textContent = stats.totalPlayerEvents || 0;

    const cacheSize = (stats.cacheInfo?.zoneCacheSize || 0) + (stats.cacheInfo?.profileCacheSize || 0) + (stats.cacheInfo?.vehicleCacheSize || 0);
    document.getElementById('admin-cache-size').textContent = cacheSize;

    // Top Players
    const playersContainer = document.getElementById('admin-top-players');
    if (stats.topPlayers && stats.topPlayers.length > 0) {
        playersContainer.innerHTML = `
            <table class="admin-table">
                <thead><tr><th>Identifier</th><th>Events</th></tr></thead>
                <tbody>
                    ${stats.topPlayers.map(p => `
                        <tr><td>${escapeHtml(p.name || p.identifier)}</td><td>${p.event_count}</td></tr>
                    `).join('')}
                </tbody>
            </table>
        `;
    }

    // Top Zones
    const zonesContainer = document.getElementById('admin-top-zones');
    if (stats.topZones && stats.topZones.length > 0) {
        zonesContainer.innerHTML = `
            <table class="admin-table">
                <thead><tr><th>Zone</th><th>Vorfälle</th><th>Heat</th></tr></thead>
                <tbody>
                    ${stats.topZones.map(z => `
                        <tr><td>${z.zone_id}</td><td>${z.total_incidents}</td><td>${(parseFloat(z.heat) * 100).toFixed(0)}%</td></tr>
                    `).join('')}
                </tbody>
            </table>
        `;
    }
}

function renderLogs(logs) {
    const container = document.getElementById('logs-container');

    if (!logs || logs.length === 0) {
        container.innerHTML = '<div style="color: #888; padding: 20px; text-align: center;">Keine Logs vorhanden</div>';
        return;
    }

    container.innerHTML = logs.map(l => `
        <div class="log-item">
            <span class="log-time">${formatDate(l.created_at)}</span>
            <span class="log-category">${l.category}</span>
            <span class="log-message">${escapeHtml(l.message)}</span>
        </div>
    `).join('');
}

function renderAdminCalls(data) {
    const container = document.getElementById('admin-calls');
    if (!container) return;

    const active = Array.isArray(data?.active) ? data.active : [];
    const history = Array.isArray(data?.history) ? data.history : [];

    let html = '';

    // Aktive Einsätze
    html += '<div class="admin-subtitle">Aktive Einsätze</div>';
    if (active.length === 0) {
        html += '<div class="empty-row">Keine aktiven Einsätze</div>';
    } else {
        html += `
        <table class="admin-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Kategorie</th>
                    <th>Priorität</th>
                    <th>Zone</th>
                    <th>Straße</th>
                    <th>Status</th>
                    <th>Seit</th>
                </tr>
            </thead>
            <tbody>
                ${active.map(c => `
                    <tr>
                        <td>#${c.id}</td>
                        <td>${escapeHtml(c.categoryLabel || c.category || '')}</td>
                        <td>${escapeHtml(c.priority || '')}</td>
                        <td>${escapeHtml(c.location?.zone || '')}</td>
                        <td>${escapeHtml((c.location?.street || '').toString())}</td>
                        <td>${escapeHtml(c.status || '')}</td>
                        <td>${timeAgo(c.createdAt)}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>`;
    }

    // Historie (zuletzt abgeschlossen)
    html += '<div class="admin-subtitle" style="margin-top: 16px;">Zuletzt abgeschlossene Notrufe</div>';
    if (history.length === 0) {
        html += '<div class="empty-row">Noch keine abgeschlossenen Notrufe</div>';
    } else {
        html += `
        <table class="admin-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Kategorie</th>
                    <th>Priorität</th>
                    <th>Zone</th>
                    <th>Straße</th>
                    <th>Einheiten</th>
                    <th>Erstellt</th>
                    <th>Abgeschlossen</th>
                </tr>
            </thead>
            <tbody>
                ${history.map(h => `
                    <tr>
                        <td>#${h.call_id}</td>
                        <td>${escapeHtml(h.category || '')}</td>
                        <td>${escapeHtml(h.priority || '')}</td>
                        <td>${escapeHtml(h.location_zone || '')}</td>
                        <td>${escapeHtml((h.location_street || '').toString())}</td>
                        <td>${h.units_count ?? 0}</td>
                        <td>${formatDate(h.created_at)}</td>
                        <td>${formatDate(h.closed_at)}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>`;
    }

    container.innerHTML = html;
}

// ================================================
// Helper Functions
// ================================================

function timeAgo(dateStr) {
    if (!dateStr) return '-';

    const now = new Date();
    const date = new Date(dateStr);
    const seconds = Math.floor((now - date) / 1000);

    if (seconds < 60) return 'gerade eben';
    if (seconds < 3600) return Math.floor(seconds / 60) + ' Min.';
    if (seconds < 86400) return Math.floor(seconds / 3600) + ' Std.';
    if (seconds < 604800) return Math.floor(seconds / 86400) + ' Tage';

    return formatDate(dateStr);
}

function updateMDTDateTime() {
    const now = new Date();
    const formatted = now.toLocaleDateString('de-DE') + ' ' + now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
    const el = document.getElementById('mdt-datetime');
    if (el) el.textContent = formatted;
}

setInterval(updateMDTDateTime, 1000);

function getRiskLabel(risk) {
    const labels = { high: 'Hohes Risiko', medium: 'Mittleres Risiko', low: 'Geringes Risiko', clean: 'Unauffällig', unknown: 'Unbekannt' };
    return labels[risk] || risk;
}

function getRiskColor(risk) {
    const colors = { high: '#f44336', medium: '#ff9800', low: '#4caf50', clean: '#4caf50', unknown: '#888' };
    return colors[risk] || '#888';
}

function getEventLabel(eventType) {
    const labels = {
        'weapon_vs_npc': '🔫 Waffengebrauch (NPC)',
        'weapon_vs_player': '🔫 Waffengebrauch (Spieler)',
        'flee_police': '🏃 Flucht vor Polizei',
        'cooperate': '🤝 Kooperation',
        'surrender': '🙌 Selbststellung',
        'shooting': '💥 Schussabgabe',
        'chase': '🚗 Verfolgungsjagd',
        'peaceful_day': '✨ Friedlicher Tag',
        'traffic_stop': '🚦 Verkehrskontrolle',
        'crime_scene': '🔍 Am Tatort gesehen',
        'flee': '🏃 Flucht'
    };
    return labels[eventType] || eventType;
}

function formatDate(dateStr) {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    return date.toLocaleDateString('de-DE') + ' ' + date.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
