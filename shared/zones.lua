-- ================================================
-- GTA V Zone Configuration - City Memory System
-- Vollständige Zonenliste basierend auf FiveM/Rockstar Game Files
-- Quelle: update\update.rpf\common\data\levels\gta5\popzone.ipl
-- ================================================

Config.Zones = {

    -- ═══════════════════════════════════════════════════════════════════
    -- SOUTH LOS SANTOS
    -- ═══════════════════════════════════════════════════════════════════

    ['grove_street'] = {
        label = 'Grove Street',
        coords = vector3(95.0, -1955.0, 21.0),
        radius = 120.0,
        category = 'residential',
        gangTerritory = true
    },
    ['davis'] = {
        label = 'Davis',
        coords = vector3(113.0, -1768.0, 29.0),
        radius = 250.0,
        category = 'residential',
        gangTerritory = true
    },
    ['chamberlain_hills'] = {
        label = 'Chamberlain Hills',
        coords = vector3(-145.0, -1648.0, 33.0),
        radius = 200.0,
        category = 'residential',
        gangTerritory = true
    },
    ['strawberry'] = {
        label = 'Strawberry',
        coords = vector3(253.0, -1302.0, 29.0),
        radius = 250.0,
        category = 'residential',
        gangTerritory = true
    },
    ['rancho'] = {
        label = 'Rancho',
        coords = vector3(468.0, -1894.0, 26.0),
        radius = 250.0,
        category = 'residential',
        gangTerritory = true
    },
    ['banning'] = {
        label = 'Banning',
        coords = vector3(961.0, -1825.0, 31.0),
        radius = 300.0,
        category = 'industrial'
    },
    ['cypress_flats'] = {
        label = 'Cypress Flats',
        coords = vector3(820.0, -2160.0, 29.0),
        radius = 250.0,
        category = 'industrial'
    },
    ['el_burro_heights'] = {
        label = 'El Burro Heights',
        coords = vector3(1534.0, -2148.0, 78.0),
        radius = 350.0,
        category = 'residential'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- EAST LOS SANTOS
    -- ═══════════════════════════════════════════════════════════════════

    ['la_mesa'] = {
        label = 'La Mesa',
        coords = vector3(826.0, -1290.0, 28.0),
        radius = 300.0,
        category = 'mixed'
    },
    ['murrieta_heights'] = {
        label = 'Murrieta Heights',
        coords = vector3(1100.0, -1550.0, 35.0),
        radius = 350.0,
        category = 'industrial'
    },
    ['mirror_park'] = {
        label = 'Mirror Park',
        coords = vector3(1078.0, -420.0, 67.0),
        radius = 300.0,
        category = 'residential'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- DOWNTOWN / ZENTRUM
    -- ═══════════════════════════════════════════════════════════════════

    ['downtown'] = {
        label = 'Downtown',
        coords = vector3(-250.0, -900.0, 31.0),
        radius = 300.0,
        category = 'commercial'
    },
    ['pillbox_hill'] = {
        label = 'Pillbox Hill',
        coords = vector3(307.0, -590.0, 43.0),
        radius = 250.0,
        category = 'commercial'
    },
    ['mission_row'] = {
        label = 'Mission Row',
        coords = vector3(428.0, -981.0, 30.0),
        radius = 200.0,
        category = 'commercial'
    },
    ['textile_city'] = {
        label = 'Textile City',
        coords = vector3(432.0, -800.0, 29.0),
        radius = 200.0,
        category = 'commercial'
    },
    ['legion_square'] = {
        label = 'Legion Square',
        coords = vector3(195.0, -935.0, 30.0),
        radius = 120.0,
        category = 'commercial'
    },
    ['alta'] = {
        label = 'Alta',
        coords = vector3(-47.0, -579.0, 38.0),
        radius = 250.0,
        category = 'residential'
    },
    ['hawick'] = {
        label = 'Hawick',
        coords = vector3(310.0, -225.0, 54.0),
        radius = 250.0,
        category = 'residential'
    },
    ['burton'] = {
        label = 'Burton',
        coords = vector3(-400.0, -100.0, 38.0),
        radius = 250.0,
        category = 'commercial'
    },
    ['little_seoul'] = {
        label = 'Little Seoul',
        coords = vector3(-740.0, -912.0, 19.0),
        radius = 250.0,
        category = 'commercial'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- VINEWOOD / HILLS
    -- ═══════════════════════════════════════════════════════════════════

    ['vinewood'] = {
        label = 'Vinewood',
        coords = vector3(311.0, 180.0, 103.0),
        radius = 250.0,
        category = 'commercial'
    },
    ['downtown_vinewood'] = {
        label = 'Downtown Vinewood',
        coords = vector3(230.0, 80.0, 97.0),
        radius = 200.0,
        category = 'commercial'
    },
    ['east_vinewood'] = {
        label = 'East Vinewood',
        coords = vector3(685.0, -27.0, 83.0),
        radius = 250.0,
        category = 'residential'
    },
    ['west_vinewood'] = {
        label = 'West Vinewood',
        coords = vector3(-686.0, 309.0, 82.0),
        radius = 300.0,
        category = 'residential'
    },
    ['vinewood_hills'] = {
        label = 'Vinewood Hills',
        coords = vector3(580.0, 570.0, 130.0),
        radius = 500.0,
        category = 'residential'
    },
    ['vinewood_racetrack'] = {
        label = 'Vinewood Racetrack',
        coords = vector3(1207.0, 220.0, 81.0),
        radius = 200.0,
        category = 'entertainment'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- ROCKFORD / RICHMAN
    -- ═══════════════════════════════════════════════════════════════════

    ['rockford_hills'] = {
        label = 'Rockford Hills',
        coords = vector3(-780.0, -96.0, 37.0),
        radius = 400.0,
        category = 'residential'
    },
    ['richman'] = {
        label = 'Richman',
        coords = vector3(-1524.0, 142.0, 56.0),
        radius = 400.0,
        category = 'residential'
    },
    ['richman_glen'] = {
        label = 'Richman Glen',
        coords = vector3(-1267.0, 502.0, 98.0),
        radius = 200.0,
        category = 'residential'
    },
    ['richards_majestic'] = {
        label = 'Richards Majestic',
        coords = vector3(-948.0, -460.0, 37.0),
        radius = 200.0,
        category = 'commercial'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- WESTSIDE / KÜSTE
    -- ═══════════════════════════════════════════════════════════════════

    ['del_perro'] = {
        label = 'Del Perro',
        coords = vector3(-1584.0, -547.0, 35.0),
        radius = 300.0,
        category = 'commercial'
    },
    ['del_perro_beach'] = {
        label = 'Del Perro Beach',
        coords = vector3(-1647.0, -1100.0, 13.0),
        radius = 250.0,
        category = 'recreation'
    },
    ['vespucci'] = {
        label = 'Vespucci',
        coords = vector3(-1174.0, -1493.0, 4.0),
        radius = 300.0,
        category = 'mixed'
    },
    ['vespucci_canals'] = {
        label = 'Vespucci Canals',
        coords = vector3(-1078.0, -1215.0, 2.0),
        radius = 250.0,
        category = 'residential'
    },
    ['vespucci_beach'] = {
        label = 'Vespucci Beach',
        coords = vector3(-1357.0, -1519.0, 4.0),
        radius = 250.0,
        category = 'recreation'
    },
    ['morningwood'] = {
        label = 'Morningwood',
        coords = vector3(-1305.0, -392.0, 36.0),
        radius = 250.0,
        category = 'residential'
    },
    ['pacific_bluffs'] = {
        label = 'Pacific Bluffs',
        coords = vector3(-2047.0, -510.0, 11.0),
        radius = 350.0,
        category = 'residential'
    },
    ['la_puerta'] = {
        label = 'La Puerta',
        coords = vector3(-825.0, -1355.0, 10.0),
        radius = 300.0,
        category = 'residential'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- HAFEN / INDUSTRIE
    -- ═══════════════════════════════════════════════════════════════════

    ['port_of_south_ls'] = {
        label = 'Port of South Los Santos',
        coords = vector3(178.0, -2737.0, 6.0),
        radius = 400.0,
        category = 'industrial'
    },
    ['elysian_island'] = {
        label = 'Elysian Island',
        coords = vector3(-180.0, -2659.0, 6.0),
        radius = 350.0,
        category = 'industrial'
    },
    ['terminal'] = {
        label = 'Terminal',
        coords = vector3(779.0, -2974.0, 6.0),
        radius = 300.0,
        category = 'industrial'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- FLUGHAFEN
    -- ═══════════════════════════════════════════════════════════════════

    ['lsia'] = {
        label = 'Los Santos International Airport',
        coords = vector3(-1037.0, -2962.0, 13.0),
        radius = 600.0,
        category = 'airport'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- GALILEO / OBSERVATORIUM
    -- ═══════════════════════════════════════════════════════════════════

    ['galileo_park'] = {
        label = 'Galileo Park',
        coords = vector3(-475.0, 1102.0, 348.0),
        radius = 200.0,
        category = 'recreation'
    },
    ['galileo_observatory'] = {
        label = 'Galileo Observatory',
        coords = vector3(-430.0, 1111.0, 325.0),
        radius = 150.0,
        category = 'landmark'
    },
    ['baytree_canyon'] = {
        label = 'Baytree Canyon',
        coords = vector3(-370.0, 800.0, 172.0),
        radius = 250.0,
        category = 'nature'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- BLAINE COUNTY - WESTKÜSTE
    -- ═══════════════════════════════════════════════════════════════════

    ['banham_canyon'] = {
        label = 'Banham Canyon',
        coords = vector3(-2670.0, 1830.0, 160.0),
        radius = 400.0,
        category = 'nature'
    },
    ['tongva_hills'] = {
        label = 'Tongva Hills',
        coords = vector3(-1850.0, 760.0, 165.0),
        radius = 400.0,
        category = 'nature'
    },
    ['tongva_valley'] = {
        label = 'Tongva Valley',
        coords = vector3(-1168.0, 530.0, 100.0),
        radius = 350.0,
        category = 'nature'
    },
    ['great_chaparral'] = {
        label = 'Great Chaparral',
        coords = vector3(-533.0, 1830.0, 190.0),
        radius = 500.0,
        category = 'nature'
    },
    ['chumash'] = {
        label = 'Chumash',
        coords = vector3(-3165.0, 1087.0, 20.0),
        radius = 300.0,
        category = 'residential'
    },
    ['north_chumash'] = {
        label = 'North Chumash',
        coords = vector3(-2600.0, 2500.0, 10.0),
        radius = 400.0,
        category = 'rural'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- BLAINE COUNTY - ZANCUDO
    -- ═══════════════════════════════════════════════════════════════════

    ['fort_zancudo'] = {
        label = 'Fort Zancudo',
        coords = vector3(-2350.0, 3270.0, 32.0),
        radius = 500.0,
        category = 'military'
    },
    ['lago_zancudo'] = {
        label = 'Lago Zancudo',
        coords = vector3(-2083.0, 2610.0, 3.0),
        radius = 400.0,
        category = 'nature'
    },
    ['zancudo_river'] = {
        label = 'Zancudo River',
        coords = vector3(-1045.0, 2713.0, 20.0),
        radius = 400.0,
        category = 'nature'
    },
    ['raton_canyon'] = {
        label = 'Raton Canyon',
        coords = vector3(-525.0, 4330.0, 75.0),
        radius = 500.0,
        category = 'nature'
    },
    ['cassidy_creek'] = {
        label = 'Cassidy Creek',
        coords = vector3(-530.0, 4150.0, 98.0),
        radius = 200.0,
        category = 'nature'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- BLAINE COUNTY - CHILIAD
    -- ═══════════════════════════════════════════════════════════════════

    ['mount_chiliad'] = {
        label = 'Mount Chiliad',
        coords = vector3(450.0, 5566.0, 795.0),
        radius = 800.0,
        category = 'nature'
    },
    ['chiliad_state_wilderness'] = {
        label = 'Chiliad Mountain State Wilderness',
        coords = vector3(340.0, 5200.0, 500.0),
        radius = 700.0,
        category = 'nature'
    },
    ['mount_josiah'] = {
        label = 'Mount Josiah',
        coords = vector3(-960.0, 4200.0, 190.0),
        radius = 400.0,
        category = 'nature'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- BLAINE COUNTY - PALETO
    -- ═══════════════════════════════════════════════════════════════════

    ['paleto_bay'] = {
        label = 'Paleto Bay',
        coords = vector3(-379.0, 6118.0, 31.0),
        radius = 400.0,
        category = 'town'
    },
    ['paleto_forest'] = {
        label = 'Paleto Forest',
        coords = vector3(43.0, 6586.0, 32.0),
        radius = 500.0,
        category = 'nature'
    },
    ['paleto_cove'] = {
        label = 'Paleto Cove',
        coords = vector3(-1580.0, 5150.0, 7.0),
        radius = 200.0,
        category = 'nature'
    },
    ['procopio_beach'] = {
        label = 'Procopio Beach',
        coords = vector3(-1240.0, 5480.0, 4.0),
        radius = 250.0,
        category = 'recreation'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- BLAINE COUNTY - SANDY SHORES / DESERT
    -- ═══════════════════════════════════════════════════════════════════

    ['sandy_shores'] = {
        label = 'Sandy Shores',
        coords = vector3(1870.0, 3714.0, 33.0),
        radius = 400.0,
        category = 'town'
    },
    ['alamo_sea'] = {
        label = 'Alamo Sea',
        coords = vector3(1350.0, 4320.0, 33.0),
        radius = 600.0,
        category = 'nature'
    },
    ['grapeseed'] = {
        label = 'Grapeseed',
        coords = vector3(1700.0, 4800.0, 42.0),
        radius = 350.0,
        category = 'rural'
    },
    ['stab_city'] = {
        label = 'Stab City',
        coords = vector3(67.0, 3728.0, 39.0),
        radius = 150.0,
        category = 'residential',
        gangTerritory = true
    },
    ['harmony'] = {
        label = 'Harmony',
        coords = vector3(546.0, 2663.0, 42.0),
        radius = 250.0,
        category = 'rural'
    },
    ['grand_senora_desert'] = {
        label = 'Grand Senora Desert',
        coords = vector3(2544.0, 2918.0, 43.0),
        radius = 700.0,
        category = 'nature'
    },
    ['ron_wind_farm'] = {
        label = 'Ron Alternates Wind Farm',
        coords = vector3(2354.0, 1830.0, 101.0),
        radius = 400.0,
        category = 'industrial'
    },
    ['davis_quartz'] = {
        label = 'Davis Quartz',
        coords = vector3(608.0, 2737.0, 45.0),
        radius = 200.0,
        category = 'industrial'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- BLAINE COUNTY - OSTKÜSTE / BERGE
    -- ═══════════════════════════════════════════════════════════════════

    ['san_chianski_range'] = {
        label = 'San Chianski Mountain Range',
        coords = vector3(2850.0, 4547.0, 50.0),
        radius = 700.0,
        category = 'nature'
    },
    ['mount_gordo'] = {
        label = 'Mount Gordo',
        coords = vector3(2925.0, 5450.0, 100.0),
        radius = 500.0,
        category = 'nature'
    },
    ['el_gordo_lighthouse'] = {
        label = 'El Gordo Lighthouse',
        coords = vector3(3430.0, 5175.0, 7.0),
        radius = 100.0,
        category = 'landmark'
    },
    ['galilee'] = {
        label = 'Galilee',
        coords = vector3(1370.0, 4385.0, 45.0),
        radius = 200.0,
        category = 'rural'
    },
    ['palomino_highlands'] = {
        label = 'Palomino Highlands',
        coords = vector3(2725.0, 840.0, 50.0),
        radius = 500.0,
        category = 'nature'
    },
    ['tataviam_mountains'] = {
        label = 'Tataviam Mountains',
        coords = vector3(2100.0, 1250.0, 80.0),
        radius = 500.0,
        category = 'nature'
    },
    ['braddock_pass'] = {
        label = 'Braddock Pass',
        coords = vector3(680.0, 3100.0, 40.0),
        radius = 300.0,
        category = 'nature'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- SPEZIELLE EINRICHTUNGEN
    -- ═══════════════════════════════════════════════════════════════════

    ['humane_labs'] = {
        label = 'Humane Labs and Research',
        coords = vector3(3616.0, 3752.0, 28.0),
        radius = 250.0,
        category = 'industrial'
    },
    ['palmer_taylor_power'] = {
        label = 'Palmer-Taylor Power Station',
        coords = vector3(2700.0, 1500.0, 25.0),
        radius = 300.0,
        category = 'industrial'
    },
    ['noose_hq'] = {
        label = 'N.O.O.S.E. Headquarters',
        coords = vector3(2524.0, -384.0, 93.0),
        radius = 200.0,
        category = 'government'
    },
    ['bolingbroke_prison'] = {
        label = 'Bolingbroke Penitentiary',
        coords = vector3(1856.0, 2604.0, 45.0),
        radius = 400.0,
        category = 'government'
    },
    ['land_act_reservoir'] = {
        label = 'Land Act Reservoir',
        coords = vector3(450.0, 2095.0, 51.0),
        radius = 200.0,
        category = 'nature'
    },
    ['land_act_dam'] = {
        label = 'Land Act Dam',
        coords = vector3(616.0, 1828.0, 225.0),
        radius = 150.0,
        category = 'industrial'
    },
    ['calafia_bridge'] = {
        label = 'Calafia Bridge',
        coords = vector3(-163.0, 4258.0, 75.0),
        radius = 150.0,
        category = 'landmark'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- SPEZIELLE ORTE (Los Santos)
    -- ═══════════════════════════════════════════════════════════════════

    ['diamond_casino'] = {
        label = 'Diamond Casino & Resort',
        coords = vector3(924.0, 47.0, 81.0),
        radius = 150.0,
        category = 'entertainment'
    },
    ['maze_bank_tower'] = {
        label = 'Maze Bank Tower',
        coords = vector3(-75.0, -818.0, 326.0),
        radius = 80.0,
        category = 'commercial'
    },
    ['maze_bank_arena'] = {
        label = 'Maze Bank Arena',
        coords = vector3(-254.0, -2019.0, 30.0),
        radius = 250.0,
        category = 'entertainment'
    },
    ['golf_club'] = {
        label = 'GWC and Golfing Society',
        coords = vector3(-1360.0, 51.0, 54.0),
        radius = 300.0,
        category = 'recreation'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- KRANKENHÄUSER
    -- ═══════════════════════════════════════════════════════════════════

    ['pillbox_hospital'] = {
        label = 'Pillbox Hill Medical Center',
        coords = vector3(311.0, -590.0, 43.0),
        radius = 80.0,
        category = 'medical'
    },
    ['sandy_clinic'] = {
        label = 'Sandy Shores Medical Center',
        coords = vector3(1839.0, 3672.0, 34.0),
        radius = 60.0,
        category = 'medical'
    },
    ['paleto_clinic'] = {
        label = 'Paleto Bay Medical Center',
        coords = vector3(-248.0, 6331.0, 32.0),
        radius = 60.0,
        category = 'medical'
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- POLIZEISTATIONEN
    -- ═══════════════════════════════════════════════════════════════════

    ['pd_mission_row'] = {
        label = 'LSPD Mission Row',
        coords = vector3(428.0, -981.0, 30.0),
        radius = 60.0,
        category = 'police'
    },
    ['pd_vespucci'] = {
        label = 'LSPD Vespucci',
        coords = vector3(-1093.0, -809.0, 19.0),
        radius = 60.0,
        category = 'police'
    },
    ['pd_vinewood'] = {
        label = 'LSPD Vinewood',
        coords = vector3(640.0, 1.0, 83.0),
        radius = 60.0,
        category = 'police'
    },
    ['pd_davis'] = {
        label = 'Davis Sheriff Station',
        coords = vector3(360.0, -1584.0, 29.0),
        radius = 60.0,
        category = 'police'
    },
    ['pd_sandy'] = {
        label = 'Sandy Shores Sheriff',
        coords = vector3(1853.0, 3687.0, 34.0),
        radius = 60.0,
        category = 'police'
    },
    ['pd_paleto'] = {
        label = 'Paleto Bay Sheriff',
        coords = vector3(-448.0, 6012.0, 31.0),
        radius = 60.0,
        category = 'police'
    },
}

-- ═══════════════════════════════════════════════════════════════════
-- HELPER FUNKTIONEN
-- ═══════════════════════════════════════════════════════════════════

-- Zone anhand von Koordinaten finden (optimiert)
function GetZoneFromCoords(coords)
    local closestZone = nil
    local closestDistance = math.huge

    for zoneId, zone in pairs(Config.Zones) do
        local distance = #(coords - zone.coords)
        if distance <= zone.radius and distance < closestDistance then
            closestZone = zoneId
            closestDistance = distance
        end
    end

    return closestZone, closestZone and Config.Zones[closestZone] or nil
end

-- Alle Zonen einer Kategorie abrufen
function GetZonesByCategory(category)
    local zones = {}
    for zoneId, zone in pairs(Config.Zones) do
        if zone.category == category then
            zones[zoneId] = zone
        end
    end
    return zones
end

-- Alle Gang-Territorien abrufen
function GetGangTerritories()
    local zones = {}
    for zoneId, zone in pairs(Config.Zones) do
        if zone.gangTerritory then
            zones[zoneId] = zone
        end
    end
    return zones
end

-- Nächste Zone zu Koordinaten finden (auch außerhalb des Radius)
function GetNearestZone(coords)
    local nearestZone = nil
    local nearestDistance = math.huge

    for zoneId, zone in pairs(Config.Zones) do
        local distance = #(coords - zone.coords)
        if distance < nearestDistance then
            nearestZone = zoneId
            nearestDistance = distance
        end
    end

    return nearestZone, Config.Zones[nearestZone], nearestDistance
end

-- ═══════════════════════════════════════════════════════════════════
-- ZONE KATEGORIEN REFERENZ
-- ═══════════════════════════════════════════════════════════════════
--[[
    Kategorien:
    - residential   = Wohngebiete
    - commercial    = Geschäfts-/Bürogebiete
    - industrial    = Industrie/Hafen
    - entertainment = Unterhaltung (Casino, Arena, etc.)
    - recreation    = Erholung (Parks, Strände)
    - nature        = Natur/Wildnis
    - rural         = Ländlich
    - town          = Kleinstadt (Sandy, Paleto)
    - military      = Militär (Fort Zancudo)
    - airport       = Flughafen
    - medical       = Krankenhäuser
    - police        = Polizeistationen
    - government    = Regierung (Gefängnis, NOOSE)
    - landmark      = Sehenswürdigkeiten
    - mixed         = Gemischt
]]

CreateThread(function()
    Wait(3000) -- Warte bis main.lua geladen ist
    if Log then
        local count = 0
        for _ in pairs(Config.Zones) do count = count + 1 end
        Log('ZONES', ('zones.lua - %d Zonen registriert'):format(count))
    end
end)
