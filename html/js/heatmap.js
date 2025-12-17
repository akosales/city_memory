// ================================================
// City Memory - Heatmap UI Handler
// ================================================

// ================================================
// DOM Elements erstellen
// ================================================

function createHeatmapUI() {
    // Legende
    if (!document.getElementById('heatmap-legend')) {
        const legend = document.createElement('div');
        legend.id = 'heatmap-legend';
        legend.className = 'heatmap-legend';
        legend.innerHTML = `
            <div class="heatmap-legend-title">Kriminalität</div>
            <div class="heatmap-legend-items">
                <div class="heatmap-legend-item">
                    <div class="heatmap-legend-color green"></div>
                    <span class="heatmap-legend-label">Ruhig</span>
                </div>
                <div class="heatmap-legend-item">
                    <div class="heatmap-legend-color orange"></div>
                    <span class="heatmap-legend-label">Erhöht</span>
                </div>
                <div class="heatmap-legend-item">
                    <div class="heatmap-legend-color red"></div>
                    <span class="heatmap-legend-label">Gefährlich</span>
                </div>
            </div>
            <div class="heatmap-legend-police-note" id="police-note" style="display: none;">
                🚔 Polizei-Ansicht aktiv
            </div>
        `;
        document.body.appendChild(legend);
    }

    // Zone Warning
    if (!document.getElementById('zone-warning')) {
        const warning = document.createElement('div');
        warning.id = 'zone-warning';
        warning.className = 'zone-warning';
        warning.innerHTML = `
            <div class="zone-warning-icon">⚠️</div>
            <div class="zone-warning-title"></div>
            <div class="zone-warning-message"></div>
            <div class="zone-warning-incidents"></div>
        `;
        document.body.appendChild(warning);
    }

    // Intro Overlay
    if (!document.getElementById('intro-overlay')) {
        const overlay = document.createElement('div');
        overlay.id = 'intro-overlay';
        overlay.className = 'intro-overlay';
        overlay.innerHTML = `
            <div class="intro-modal">
                <div class="intro-icon">🗺️</div>
                <div class="intro-title">City Memory Heatmap</div>
                <div class="intro-subtitle">Die Stadt merkt sich alles</div>
                <div class="intro-legend">
                    <div class="intro-legend-item">
                        <div class="intro-legend-color green"></div>
                        <span class="intro-legend-label">Ruhig</span>
                    </div>
                    <div class="intro-legend-item">
                        <div class="intro-legend-color orange"></div>
                        <span class="intro-legend-label">Erhöht</span>
                    </div>
                    <div class="intro-legend-item">
                        <div class="intro-legend-color red"></div>
                        <span class="intro-legend-label">Gefährlich</span>
                    </div>
                </div>
                <div class="intro-description">
                    Die Karte zeigt dir Gebiete mit hoher Kriminalität.<br>
                    Die Daten basieren auf echten Vorfällen im Spiel.<br><br>
                    <strong>Rote Zonen</strong> = Vorsicht, hier passiert viel!
                </div>
                <button class="intro-button" onclick="closeIntro()">Verstanden</button>
                <div class="intro-key-hint">oder drücke <kbd>Enter</kbd> / <kbd>ESC</kbd></div>
            </div>
        `;
        document.body.appendChild(overlay);
    }

    // Notruf Hint
    if (!document.getElementById('notruf-hint')) {
        const hint = document.createElement('div');
        hint.id = 'notruf-hint';
        hint.className = 'notruf-hint';
        hint.innerHTML = `
            <div class="notruf-hint-icon">📞</div>
            <div class="notruf-hint-title">Notruf verfügbar</div>
            <div class="notruf-hint-text">
                Du kannst jederzeit einen Notruf absetzen um Hilfe zu rufen.
            </div>
            <div class="notruf-hint-command">/notruf</div>
        `;
        document.body.appendChild(hint);
    }
}

// Bei DOM Ready erstellen
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createHeatmapUI);
} else {
    createHeatmapUI();
}

// ================================================
// Legende anzeigen/verstecken
// ================================================

function toggleHeatmapLegend(show, isPolice) {
    const legend = document.getElementById('heatmap-legend');
    const policeNote = document.getElementById('police-note');

    if (!legend) return;

    if (show) {
        legend.classList.add('visible');
        if (policeNote) {
            policeNote.style.display = isPolice ? 'flex' : 'none';
        }
    } else {
        legend.classList.remove('visible');
    }
}

// ================================================
// Zone Warning anzeigen
// ================================================

let zoneWarningTimeout = null;

function showZoneWarning(data) {
    const warning = document.getElementById('zone-warning');
    if (!warning) return;

    // Clear previous timeout
    if (zoneWarningTimeout) {
        clearTimeout(zoneWarningTimeout);
    }

    // Update content
    warning.querySelector('.zone-warning-icon').textContent = data.icon || '⚠️';
    warning.querySelector('.zone-warning-title').textContent = data.zoneName || 'Unbekannte Zone';
    warning.querySelector('.zone-warning-message').textContent = data.message || '';

    const incidents = warning.querySelector('.zone-warning-incidents');
    if (data.incidents && data.incidents > 0) {
        incidents.textContent = `${data.incidents} Vorfälle in letzter Zeit`;
        incidents.style.display = 'block';
    } else {
        incidents.style.display = 'none';
    }

    // Set level class
    warning.className = 'zone-warning';
    if (data.level === 'high') {
        warning.classList.add('level-high');
    } else if (data.level === 'medium') {
        warning.classList.add('level-medium');
    }

    // Show
    warning.classList.add('visible');

    // Auto-hide after 5 seconds
    zoneWarningTimeout = setTimeout(() => {
        warning.classList.remove('visible');
    }, 5000);
}

// ================================================
// Intro Modal
// ================================================

function showHeatmapIntro(isPolice) {
    const overlay = document.getElementById('intro-overlay');
    if (overlay) {
        // Titel je nach Job
        const title = isPolice ? 'Lagebildkarte' : 'Die Stadt vergisst nie';
        const subtitle = isPolice ? 'Kriminalitäts-Hotspots im Überblick' : 'Die Stadt merkt sich alles';

        const modal = overlay.querySelector('.intro-modal');
        modal.querySelector('.intro-title').textContent = title;
        modal.querySelector('.intro-subtitle').textContent = subtitle;

        overlay.classList.add('visible');
    }
}

function closeIntro() {
    const overlay = document.getElementById('intro-overlay');
    if (overlay) {
        overlay.classList.remove('visible');
    }

    // Notify Lua
    fetch('https://city_memory/introComplete', {
        method: 'POST',
        body: JSON.stringify({})
    }).catch(() => {});
}

// ================================================
// Zone Warning Intro (erweitert)
// ================================================

function showZoneWarningIntro(data) {
    const overlay = document.getElementById('intro-overlay');
    if (!overlay) return;

    // Content anpassen für Zone-Warnung
    const modal = overlay.querySelector('.intro-modal');
    modal.innerHTML = `
        <div class="intro-icon">${data.level === 'high' ? '🔴' : '🟠'}</div>
        <div class="intro-title">${data.zoneName}</div>
        <div class="intro-subtitle">Warnung: ${data.level === 'high' ? 'Gefährliche' : 'Auffällige'} Gegend</div>
        <div class="intro-legend">
            <div class="intro-legend-item">
                <div class="intro-legend-color green"></div>
                <span class="intro-legend-label">Ruhig</span>
            </div>
            <div class="intro-legend-item">
                <div class="intro-legend-color orange"></div>
                <span class="intro-legend-label">Erhöht</span>
            </div>
            <div class="intro-legend-item">
                <div class="intro-legend-color red"></div>
                <span class="intro-legend-label">Gefährlich</span>
            </div>
        </div>
        <div class="intro-description">
            ${data.message}<br><br>
            <strong>City Memory</strong> merkt sich alle Vorfälle in der Stadt.<br>
            Du wirst gewarnt wenn du gefährliche Gebiete betrittst.
            ${data.incidents > 0 ? `<br><br>📊 ${data.incidents} Vorfälle hier in letzter Zeit` : ''}
        </div>
        <button class="intro-button" onclick="closeIntro()">Verstanden</button>
        <div class="intro-key-hint">oder drücke <kbd>Enter</kbd> / <kbd>ESC</kbd></div>
    `;

    overlay.classList.add('visible');
}

// ================================================
// Notruf Hint
// ================================================

let notrufHintTimeout = null;

function showNotrufHint(firstTime) {
    const hint = document.getElementById('notruf-hint');
    if (!hint) return;

    if (notrufHintTimeout) {
        clearTimeout(notrufHintTimeout);
    }

    if (firstTime) {
        hint.innerHTML = `
            <div class="notruf-hint-icon">📞</div>
            <div class="notruf-hint-title">Notruf verfügbar</div>
            <div class="notruf-hint-text">
                Brauchst du Hilfe? Du kannst jederzeit einen Notruf absetzen.<br>
                Polizei und Rettungsdienst werden informiert.
            </div>
            <div class="notruf-hint-command">/notruf</div>
        `;
    }

    hint.classList.add('visible');

    notrufHintTimeout = setTimeout(() => {
        hint.classList.remove('visible');
    }, firstTime ? 8000 : 5000);
}

// ================================================
// NUI Message Handler
// ================================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'toggleHeatmapLegend':
            toggleHeatmapLegend(data.show, data.isPolice);
            break;

        case 'showHeatmapIntro':
            showHeatmapIntro(data.isPolice);
            break;

        case 'showZoneWarning':
            showZoneWarning(data);
            break;

        case 'showZoneWarningIntro':
            showZoneWarningIntro(data);
            break;

        case 'showNotrufHint':
            showNotrufHint(data.firstTime);
            break;
    }
});

// ================================================
// Keyboard Support für Intros
// ================================================

document.addEventListener('keydown', function(e) {
    const overlay = document.getElementById('intro-overlay');
    const isVisible = overlay && overlay.classList.contains('visible');

    if (isVisible) {
        // ESC, Enter, Space, oder Backspace schließt das Intro
        if (e.key === 'Escape' || e.key === 'Enter' || e.key === ' ' || e.key === 'Backspace') {
            e.preventDefault();
            closeIntro();
        }
    }
});
