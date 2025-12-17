Config = {}

-- ================================================
-- DEBUG & LOGGING
-- ================================================
Config.Debug = true
Config.PersistentLogs = true

-- ================================================
-- MENÜ SYSTEM (NEU)
-- ================================================
Config.Menu = {
    -- Radial Menu aktivieren (benötigt ox_lib)
    useRadialMenu = true,
    
    -- ox_target Interaktionen aktivieren (benötigt ox_target)
    useOxTarget = true,
    
    -- Optionaler Keybind für schnellen Zugriff aufs Menü
    -- Wenn false, nur über Radial Menu oder Commands erreichbar
    enableKeybind = false,
    keybind = 'F5',  -- Nur wenn enableKeybind = true
    
    -- Commands immer verfügbar:
    -- /citymemory oder /cm - Hauptmenü
    -- /notruf - Notruf direkt
    -- /dispatch - Dispatch direkt
    -- /mdt - MDT direkt
    -- /heatmap - Heatmap toggle
    -- /cityadmin - Admin Panel
}

-- ================================================
-- ALTE KEYBINDS (DEPRECATED - nur für Fallback)
-- ================================================
Config.Keys = {
    -- Diese werden NICHT mehr verwendet wenn Config.Menu.useRadialMenu = true
    -- Nur als Fallback wenn ox_lib nicht vorhanden
    openDispatch = 'J',
    openCall = 'F5',
    openMDT = 'F6',
    openAdmin = 'F7',
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
        'sahp',
        'ranger',
    },

    -- EMS Jobs (sehen medizinische & Unfälle)
    ems = {
        'ambulance',
        'ems',
        'firefighter',
        'fire',
        'lsfd',
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
    markVehicle = 2,
    viewFullProfile = 2,
    accessAdminPanel = 0,
    closeOthersCalls = 3,
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
    callTimeout = 15 * 60,
    maxActiveCalls = 50,
    autoDeleteCompleted = 30,
    allowAnonymous = true,
    notifyOnNewCall = true,
    notifyOnBackup = true,
    autoSetWaypoint = true,
}

-- ================================================
-- MDT EINSTELLUNGEN
-- ================================================
Config.MDT = {
    enabled = true,
    searchCooldown = 2,
    maxSearchResults = 20,
    showPlayerPhotos = true,
    allowNotesEdit = true,
}

-- ================================================
-- ZONE HEAT EINSTELLUNGEN
-- ================================================
Config.ZoneHeat = {
    max = 1.0,
    min = 0.0,
    decayRate = 0.01,
    decayAccelerated = 0.02,
    acceleratedThreshold = 1800000,
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
    copMin = 0.10,
    civMin = 0.50,
    radius = 150.0,
    interval = 30000,
    requestCooldownMs = 5000,
    maxZones = 80
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
Config.DecayInterval = 300000

-- ================================================
-- SOUNDS
-- ================================================
Config.Sounds = {
    enabled = true,

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
}

-- ================================================
-- UI FARBEN
-- ================================================
Config.UI = {
    primaryColor = '#1976d2',
    dangerColor = '#f44336',
    warningColor = '#ff9800',
    successColor = '#4caf50',
    backgroundColor = '#0a1628',
    priorityHigh = '#f44336',
    priorityMedium = '#ff9800',
    priorityLow = '#4caf50',
}

-- ================================================
-- ADMIN DASHBOARD
-- ================================================
Config.Admin = {
    enabled = true,
    refreshInterval = 30,
    maxLogEntries = 100,
    allowDataExport = true,
    allowDataReset = true,
}

-- ================================================
-- OX_TARGET POSITIONEN (anpassbar)
-- ================================================
Config.TargetLocations = {
    -- Polizei Computer (MDT)
    mdt = {
        { coords = vec3(441.79, -982.08, 30.69), label = 'Mission Row PD' },
        { coords = vec3(-1093.84, -809.13, 19.29), label = 'Vespucci PD' },
        { coords = vec3(1853.18, 3686.63, 34.27), label = 'Sandy Shores' },
        { coords = vec3(-448.22, 6012.85, 31.72), label = 'Paleto Bay' },
    },
    
    -- Dispatch Terminals
    dispatch = {
        { coords = vec3(441.16, -979.43, 30.69), label = 'Mission Row Leitstelle' },
    },
    
    -- EMS Terminals
    ems = {
        { coords = vec3(311.67, -592.76, 43.29), label = 'Pillbox Hospital' },
    },
    
    -- Öffentliche Telefone
    phones = {
        vec3(232.28, -899.35, 30.09),
        vec3(-1037.97, -2733.82, 13.76),
        vec3(1693.44, 4788.22, 41.99),
        vec3(-379.53, 6118.32, 31.85),
        vec3(1960.17, 3740.48, 32.34),
    },
}
