Config = {}

-- ================================================
-- LANGUAGE / SPRACHE
-- ================================================
-- 'de' = German / Deutsch
-- 'en' = English / Englisch
Config.Language = 'en'

-- ================================================
-- DEBUG & LOGGING
-- ================================================
Config.Debug = true
Config.PersistentLogs = true

-- ================================================
-- MENU SYSTEM
-- ================================================
Config.Menu = {
    useRadialMenu = true,
    useOxTarget = true,
    enableKeybind = false,
    keybind = 'F5',
}

-- ================================================
-- LEGACY KEYBINDS (DEPRECATED)
-- ================================================
Config.Keys = {
    openDispatch = 'J',
    openCall = 'F5',
    openMDT = 'F6',
    openAdmin = 'F7',
}

-- ================================================
-- JOBS CONFIGURATION
-- ================================================
Config.Jobs = {
    police = {
        'police',
        'sheriff',
        'fib',
        'lspd',
        'bcso',
        'sahp',
        'ranger',
    },
    ems = {
        'ambulance',
        'ems',
        'firefighter',
        'fire',
        'lsfd',
    },
    admin = {
        'admin',
        'superadmin',
        'developer',
    },
}

Config.MinGrades = {
    markVehicle = 2,
    viewFullProfile = 2,
    accessAdminPanel = 0,
    closeOthersCalls = 3,
}

-- ================================================
-- LOCALES / ÜBERSETZUNGEN
-- ================================================
Config.Locales = {
    ['de'] = {
        -- Categories
        shooting = 'Schüsse',
        robbery = 'Überfall',
        assault = 'Körperverletzung',
        pursuit = 'Verfolgung',
        kidnapping = 'Entführung',
        medical = 'Medizinisch',
        accident = 'Unfall',
        fire = 'Feuer',
        theft = 'Diebstahl',
        suspicious = 'Verdächtige Person',
        drugs = 'Drogenhandel',
        noise = 'Ruhestörung',
        other = 'Sonstiges',

        -- Priorities
        priority_high = 'Hoch',
        priority_medium = 'Mittel',
        priority_low = 'Niedrig',

        -- Risk Levels
        risk_high = 'Hohes Risiko',
        risk_medium = 'Mittleres Risiko',
        risk_low = 'Geringes Risiko',
        risk_clean = 'Unauffällig',
        risk_unknown = 'Unbekannt',

        -- Events
        event_weapon_vs_npc = 'Waffengebrauch (NPC)',
        event_weapon_vs_player = 'Waffengebrauch (Spieler)',
        event_flee_police = 'Flucht vor Polizei',
        event_cooperate = 'Kooperation',
        event_surrender = 'Selbststellung',
        event_shooting = 'Schussabgabe',
        event_chase = 'Verfolgungsjagd',
        event_peaceful_day = 'Friedlicher Tag',

        -- UI Labels
        emergency_call = 'Notruf',
        dispatch = 'Leitstelle',
        search = 'Suche',
        person = 'Person',
        vehicle = 'Fahrzeug',
        warrants = 'Fahndungen',
        statistics = 'Statistiken',
        notes = 'Notizen',
        reputation = 'Reputation',
        violence_tendency = 'Gewaltbereitschaft',
        flee_tendency = 'Fluchtgefahr',
        cooperation = 'Kooperation',
        last_incidents = 'Letzte Vorfälle',
        no_incidents = 'Keine Vorfälle',
        add_note = 'Notiz hinzufügen',
        create_warrant = 'Zur Fahndung ausschreiben',
        hotspots = 'Aktive Hotspots',

        -- Menu Labels
        menu_main = 'City Memory',
        menu_heatmap = 'Heatmap',
        menu_heatmap_show = 'Heatmap anzeigen',
        menu_heatmap_hide = 'Heatmap ausblenden',
        menu_emergency = 'Notruf absetzen',
        menu_dispatch = 'Leitstelle öffnen',
        menu_mdt = 'MDT öffnen',
        menu_police_actions = 'Polizei-Aktionen',
        menu_check_person = 'Person überprüfen',
        menu_check_plate = 'Kennzeichen abfragen',
        menu_new_warrant = 'Neue Fahndung',

        -- Zone Warnings
        zone_warning_high = 'Gefährliche Gegend! Hier passiert viel Kriminalität.',
        zone_warning_medium = 'Vorsicht! Erhöhte Kriminalität in dieser Gegend.',

        -- Target Labels
        target_check_person = 'Person überprüfen',
        target_mark_cooperate = 'Kooperation vermerken',
        target_mark_surrender = 'Selbststellung vermerken',
        target_check_plate = 'Kennzeichen abfragen',
        target_flag_vehicle = 'Fahrzeug zur Fahndung',
    },

    ['en'] = {
        -- Categories
        shooting = 'Shots Fired',
        robbery = 'Robbery',
        assault = 'Assault',
        pursuit = 'Pursuit',
        kidnapping = 'Kidnapping',
        medical = 'Medical',
        accident = 'Accident',
        fire = 'Fire',
        theft = 'Theft',
        suspicious = 'Suspicious Person',
        drugs = 'Drug Dealing',
        noise = 'Noise Complaint',
        other = 'Other',

        -- Priorities
        priority_high = 'High',
        priority_medium = 'Medium',
        priority_low = 'Low',

        -- Risk Levels
        risk_high = 'High Risk',
        risk_medium = 'Medium Risk',
        risk_low = 'Low Risk',
        risk_clean = 'Clean',
        risk_unknown = 'Unknown',

        -- Events
        event_weapon_vs_npc = 'Weapon Use (NPC)',
        event_weapon_vs_player = 'Weapon Use (Player)',
        event_flee_police = 'Fleeing Police',
        event_cooperate = 'Cooperation',
        event_surrender = 'Surrender',
        event_shooting = 'Shots Fired',
        event_chase = 'Chase',
        event_peaceful_day = 'Peaceful Day',

        -- UI Labels
        emergency_call = 'Emergency Call',
        dispatch = 'Dispatch',
        search = 'Search',
        person = 'Person',
        vehicle = 'Vehicle',
        warrants = 'Warrants',
        statistics = 'Statistics',
        notes = 'Notes',
        reputation = 'Reputation',
        violence_tendency = 'Violence Tendency',
        flee_tendency = 'Flight Risk',
        cooperation = 'Cooperation',
        last_incidents = 'Recent Incidents',
        no_incidents = 'No incidents',
        add_note = 'Add note',
        create_warrant = 'Create Warrant',
        hotspots = 'Active Hotspots',

        -- Menu Labels
        menu_main = 'City Memory',
        menu_heatmap = 'Heatmap',
        menu_heatmap_show = 'Show Heatmap',
        menu_heatmap_hide = 'Hide Heatmap',
        menu_emergency = 'Emergency Call',
        menu_dispatch = 'Open Dispatch',
        menu_mdt = 'Open MDT',
        menu_police_actions = 'Police Actions',
        menu_check_person = 'Check Person',
        menu_check_plate = 'Check Plate',
        menu_new_warrant = 'New Warrant',

        -- Zone Warnings
        zone_warning_high = 'Dangerous area! High crime activity.',
        zone_warning_medium = 'Caution! Elevated crime in this area.',

        -- Target Labels
        target_check_person = 'Check Person',
        target_mark_cooperate = 'Mark as Cooperative',
        target_mark_surrender = 'Mark as Surrendered',
        target_check_plate = 'Check Plate',
        target_flag_vehicle = 'Flag Vehicle',
    },
}

-- Helper function to get locale string
function L(key)
    local lang = Config.Language or 'en'
    if Config.Locales[lang] and Config.Locales[lang][key] then
        return Config.Locales[lang][key]
    elseif Config.Locales['en'] and Config.Locales['en'][key] then
        return Config.Locales['en'][key]
    end
    return key
end

-- ================================================
-- EMERGENCY CATEGORIES
-- ================================================
Config.Categories = {
    ['shooting'] = {
        label = L('shooting'),
        priority = 'high',
        icon = '🔫',
        police = true,
        ems = true,
        heatModifier = 0.15,
    },
    ['robbery'] = {
        label = L('robbery'),
        priority = 'high',
        icon = '💰',
        police = true,
        ems = false,
        heatModifier = 0.12,
    },
    ['assault'] = {
        label = L('assault'),
        priority = 'high',
        icon = '👊',
        police = true,
        ems = true,
        heatModifier = 0.10,
    },
    ['pursuit'] = {
        label = L('pursuit'),
        priority = 'high',
        icon = '🚗',
        police = true,
        ems = false,
        heatModifier = 0.20,
    },
    ['kidnapping'] = {
        label = L('kidnapping'),
        priority = 'high',
        icon = '🚐',
        police = true,
        ems = false,
        heatModifier = 0.18,
    },
    ['medical'] = {
        label = L('medical'),
        priority = 'medium',
        icon = '🏥',
        police = false,
        ems = true,
        heatModifier = 0.03,
    },
    ['accident'] = {
        label = L('accident'),
        priority = 'medium',
        icon = '💥',
        police = true,
        ems = true,
        heatModifier = 0.08,
    },
    ['fire'] = {
        label = L('fire'),
        priority = 'medium',
        icon = '🔥',
        police = true,
        ems = true,
        heatModifier = 0.10,
    },
    ['theft'] = {
        label = L('theft'),
        priority = 'low',
        icon = '🦹',
        police = true,
        ems = false,
        heatModifier = 0.05,
    },
    ['suspicious'] = {
        label = L('suspicious'),
        priority = 'low',
        icon = '👤',
        police = true,
        ems = false,
        heatModifier = 0.03,
    },
    ['drugs'] = {
        label = L('drugs'),
        priority = 'medium',
        icon = '💊',
        police = true,
        ems = false,
        heatModifier = 0.08,
    },
    ['noise'] = {
        label = L('noise'),
        priority = 'low',
        icon = '📢',
        police = true,
        ems = false,
        heatModifier = 0.02,
    },
    ['other'] = {
        label = L('other'),
        priority = 'low',
        icon = '❓',
        police = true,
        ems = true,
        heatModifier = 0.03,
    },
}

-- ================================================
-- DISPATCH SETTINGS
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
-- MDT SETTINGS
-- ================================================
Config.MDT = {
    enabled = true,
    searchCooldown = 2,
    maxSearchResults = 20,
    showPlayerPhotos = true,
    allowNotesEdit = true,
}

-- ================================================
-- ZONE HEAT SETTINGS
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
-- HEATMAP (Zone Visualization)
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
-- PLAYER PROFILE SETTINGS (RP-Optimized)
-- ================================================
Config.PlayerProfile = {
    defaultReputation = 0.5,
    decayRate = 0.0005,
    maxReputation = 1.0,
    minReputation = 0.0,
}

Config.ReputationModifiers = {
    ['flee_police'] = -0.12,
    ['weapon_vs_player'] = -0.15,
    ['weapon_vs_npc'] = -0.02,
    ['chase'] = -0.08,
    ['shooting'] = -0.05,
    ['cooperate'] = 0.05,
    ['surrender'] = 0.08,
    ['peaceful_day'] = 0.003,
}

Config.RiskLevels = {
    high = 0.25,
    medium = 0.40,
}

-- ================================================
-- DECAY SETTINGS
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
-- UI COLORS
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
-- OX_TARGET LOCATIONS (customizable)
-- ================================================
Config.TargetLocations = {
    mdt = {
        { coords = vec3(441.79, -982.08, 30.69), label = 'Mission Row PD' },
        { coords = vec3(-1093.84, -809.13, 19.29), label = 'Vespucci PD' },
        { coords = vec3(1853.18, 3686.63, 34.27), label = 'Sandy Shores' },
        { coords = vec3(-448.22, 6012.85, 31.72), label = 'Paleto Bay' },
    },
    dispatch = {
        { coords = vec3(441.16, -979.43, 30.69), label = 'Mission Row Dispatch' },
    },
    ems = {
        { coords = vec3(311.67, -592.76, 43.29), label = 'Pillbox Hospital' },
    },
    phones = {
        vec3(232.28, -899.35, 30.09),
        vec3(-1037.97, -2733.82, 13.76),
        vec3(1693.44, 4788.22, 41.99),
        vec3(-379.53, 6118.32, 31.85),
        vec3(1960.17, 3740.48, 32.34),
    },
}
