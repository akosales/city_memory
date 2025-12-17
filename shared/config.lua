Config = {}

-- ================================================
-- DEBUG & LOGGING
-- ================================================
Config.Debug = true
Config.PersistentLogs = true

-- ================================================
-- TASTEN-BINDINGS
-- ================================================
Config.Keys = {
    openDispatch = 'J',         -- Dispatch UI (Einsatzkräfte)
    openCall = 'F5',            -- Notruf UI (Zivilisten)
    openMDT = 'F6',             -- MDT UI (Polizei)
    openAdmin = 'F7',           -- Admin Dashboard
}

-- ================================================
-- JOBS KONFIGURATION
-- ================================================
Config.Jobs = {
    -- Polizei Jobs (sehen alle Notrufe außer rein medizinische)
    police = {
        'police',
        'sheriff',
        'fib',
        'lspd',
        'bcso',
        'sahp',         -- San Andreas Highway Patrol
        'ranger',       -- Park Ranger
    },

    -- EMS Jobs (sehen medizinische & Unfälle)
    ems = {
        'ambulance',
        'ems',
        'firefighter',
        'fire',
        'lsfd',         -- Los Santos Fire Department
    },

    -- Admin Jobs (sehen Admin-Dashboard)
    admin = {
        'admin',
        'superadmin',
        'developer',
    },
}

-- Mindest-Dienstgrad für bestimmte Aktionen
Config.MinGrades = {
    markVehicle = 2,        -- Fahrzeug zur Fahndung ausschreiben
    viewFullProfile = 2,    -- Detaillierte Spieler-Profile sehen
    accessAdminPanel = 0,   -- Admin-Panel (0 = alle Admins)
    closeOthersCalls = 3,   -- Notrufe anderer abschließen
}

-- ================================================
-- NOTRUF KATEGORIEN
-- ================================================
Config.Categories = {
    ['shooting'] = {
        label = 'Schüsse',
        priority = 'high',
        icon = '🔫',
        police = true,
        ems = true,
        heatModifier = 0.15,
    },
    ['robbery'] = {
        label = 'Überfall',
        priority = 'high',
        icon = '💰',
        police = true,
        ems = false,
        heatModifier = 0.12,
    },
    ['assault'] = {
        label = 'Körperverletzung',
        priority = 'high',
        icon = '👊',
        police = true,
        ems = true,
        heatModifier = 0.10,
    },
    ['pursuit'] = {
        label = 'Verfolgung',
        priority = 'high',
        icon = '🚗',
        police = true,
        ems = false,
        heatModifier = 0.20,
    },
    ['kidnapping'] = {
        label = 'Entführung',
        priority = 'high',
        icon = '🚐',
        police = true,
        ems = false,
        heatModifier = 0.18,
    },
    ['medical'] = {
        label = 'Medizinisch',
        priority = 'medium',
        icon = '🏥',
        police = false,
        ems = true,
        heatModifier = 0.03,
    },
    ['accident'] = {
        label = 'Unfall',
        priority = 'medium',
        icon = '💥',
        police = true,
        ems = true,
        heatModifier = 0.08,
    },
    ['fire'] = {
        label = 'Feuer',
        priority = 'medium',
        icon = '🔥',
        police = true,
        ems = true,
        heatModifier = 0.10,
    },
    ['theft'] = {
        label = 'Diebstahl',
        priority = 'low',
        icon = '🦹',
        police = true,
        ems = false,
        heatModifier = 0.05,
    },
    ['suspicious'] = {
        label = 'Verdächtige Person',
        priority = 'low',
        icon = '👤',
        police = true,
        ems = false,
        heatModifier = 0.03,
    },
    ['drugs'] = {
        label = 'Drogenhandel',
        priority = 'medium',
        icon = '💊',
        police = true,
        ems = false,
        heatModifier = 0.08,
    },
    ['noise'] = {
        label = 'Ruhestörung',
        priority = 'low',
        icon = '📢',
        police = true,
        ems = false,
        heatModifier = 0.02,
    },
    ['other'] = {
        label = 'Sonstiges',
        priority = 'low',
        icon = '❓',
        police = true,
        ems = true,
        heatModifier = 0.03,
    },
}

-- ================================================
-- DISPATCH EINSTELLUNGEN
-- ================================================
Config.Dispatch = {
    callTimeout = 15 * 60,          -- Notruf-Timeout in Sekunden (15 Min)
    maxActiveCalls = 50,            -- Maximale aktive Notrufe
    autoDeleteCompleted = 30,       -- Abgeschlossene Calls nach X Sekunden löschen
    allowAnonymous = true,          -- Anonyme Notrufe erlauben
    notifyOnNewCall = true,         -- Benachrichtigung bei neuem Notruf
    notifyOnBackup = true,          -- Benachrichtigung bei Backup-Anforderung
    autoSetWaypoint = true,         -- Automatisch Route setzen bei Annahme
}

-- ================================================
-- MDT EINSTELLUNGEN
-- ================================================
Config.MDT = {
    enabled = true,
    searchCooldown = 2,             -- Sekunden zwischen Suchen
    maxSearchResults = 20,          -- Maximale Suchergebnisse
    showPlayerPhotos = true,        -- Spielerfotos anzeigen (wenn vorhanden)
    allowNotesEdit = true,          -- Notizen bearbeiten erlauben
}

-- ================================================
-- ZONE HEAT EINSTELLUNGEN
-- ================================================
Config.ZoneHeat = {
    max = 1.0,
    min = 0.0,
    decayRate = 0.01,
    decayAccelerated = 0.02,
    acceleratedThreshold = 1800000, -- 30 Min in ms
}

Config.HeatModifiers = {
    ['shooting'] = 0.15,
    ['police_dispatch'] = 0.10,
    ['chase'] = 0.20,
    ['emergency_call'] = 0.05,
    ['violent_crime'] = 0.12,
}

Config.EventCooldowns = {
    ['shooting'] = 60,
    ['police_dispatch'] = 120,
    ['chase'] = 90,
    ['emergency_call'] = 30,
    ['violent_crime'] = 60,
}

-- ================================================
-- HEATMAP (Zonen-Visualisierung)
-- ================================================
Config.ZoneHeatmap = {
    enabled = true,
    copMin = 0.10,              -- Mindest-Heat für Polizei
    civMin = 0.50,              -- Mindest-Heat für Zivilisten
    radius = 150.0,             -- Blip-Radius in Metern
    interval = 30000,           -- Update-Intervall Client (ms)
    requestCooldownMs = 5000,   -- Serverseitiges Rate-Limit pro Spieler (ms)
    maxZones = 80               -- Optional: Max. Zonen gleichzeitig (derzeit clientseitig nicht limitiert)
}

-- ================================================
-- SPIELER-PROFIL EINSTELLUNGEN
-- ================================================
Config.PlayerProfile = {
    defaultReputation = 0.5,
    decayRate = 0.002,
    maxReputation = 1.0,
    minReputation = 0.0,
}

Config.ReputationModifiers = {
    ['flee_police'] = -0.08,
    ['cooperate'] = 0.03,
    ['weapon_vs_player'] = -0.10,
    ['weapon_vs_npc'] = -0.03,
    ['peaceful_day'] = 0.01,
    ['surrender'] = 0.05,
}

Config.RiskLevels = {
    high = 0.3,
    medium = 0.45,
}

-- ================================================
-- DECAY EINSTELLUNGEN
-- ================================================
Config.DecayInterval = 300000 -- 5 Minuten

-- ================================================
-- SOUNDS (für Custom Sounds: Dateien in html/sounds/ ablegen)
-- ================================================
Config.Sounds = {
    enabled = true,

    -- GTA Native Sounds (Standard)
    newCall = {
        type = 'native',
        name = 'TIMER_STOP',
        set = 'HUD_MINI_GAME_SOUNDSET',
    },
    backup = {
        type = 'native',
        name = 'CHECKPOINT_NORMAL',
        set = 'HUD_MINI_GAME_SOUNDSET',
    },
    callAccepted = {
        type = 'native',
        name = 'NAV_UP_DOWN',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
    },
    callCompleted = {
        type = 'native',
        name = 'MEDAL_UP',
        set = 'HUD_MINI_GAME_SOUNDSET',
    },
    alert = {
        type = 'native',
        name = 'ERROR',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
    },

    -- Für Custom Sounds (HTML5 Audio):
    -- newCall = {
    --     type = 'custom',
    --     file = 'sounds/dispatch.mp3',
    --     volume = 0.5,
    -- },
}

-- ================================================
-- UI FARBEN (für Anpassung)
-- ================================================
Config.UI = {
    primaryColor = '#1976d2',       -- Haupt-Blau
    dangerColor = '#f44336',        -- Rot
    warningColor = '#ff9800',       -- Orange
    successColor = '#4caf50',       -- Grün
    backgroundColor = '#0a1628',    -- Hintergrund

    -- Prioritäts-Farben
    priorityHigh = '#f44336',
    priorityMedium = '#ff9800',
    priorityLow = '#4caf50',
}

-- ================================================
-- ADMIN DASHBOARD
-- ================================================
Config.Admin = {
    enabled = true,
    refreshInterval = 30,           -- Auto-Refresh in Sekunden
    maxLogEntries = 100,            -- Maximale Log-Einträge anzeigen
    allowDataExport = true,         -- Daten-Export erlauben
    allowDataReset = true,          -- Daten-Reset erlauben (gefährlich!)
}
