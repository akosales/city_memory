-- ================================================
-- City Memory System - MDT Server
-- Mobile Data Terminal für Polizei
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================
-- Helper Functions
-- ================================================

local function IsPolice(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    return IsPoliceJob(xPlayer.job.name)
end

local function IsAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.group == 'admin' or xPlayer.group == 'superadmin' or IsAdminJob(xPlayer.job.name)
end

local function GetPlayerGrade(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    return xPlayer.job.grade or 0
end

-- ================================================
-- Personen-Suche
-- ================================================

RegisterNetEvent('mdt:searchPerson', function(searchQuery)
    local source = source
    if not IsPolice(source) then return end

    local results = {}

    -- Suche nach Name in player_profiles (JOIN mit users für Namen)
    -- Da wir keinen direkten Zugriff auf Spielernamen in der DB haben,
    -- suchen wir erst online Spieler, dann in der DB

    -- Online Spieler durchsuchen
    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(players) do
        local name = xPlayer.getName():lower()
        local query = searchQuery:lower()

        if name:find(query) then
            local profile = exports['city_memory']:GetPlayerProfile(xPlayer.identifier)
            local risk = exports['city_memory']:GetRiskLevel(xPlayer.identifier)

            table.insert(results, {
                id = xPlayer.source,
                identifier = xPlayer.identifier,
                name = xPlayer.getName(),
                online = true,
                job = xPlayer.job.label or xPlayer.job.name,
                risk = risk,
                profile = profile,
            })
        end
    end

    -- Offline Spieler aus DB (profile mit Ereignissen)
    local dbResults = PG.query([[
        SELECT DISTINCT p.identifier, p.reputation, p.violence_tendency, p.flee_tendency, p.cooperation
        FROM player_profiles p
        JOIN player_events e ON p.identifier = e.identifier
        WHERE p.identifier LIKE ?
        LIMIT 20
    ]], { '%' .. searchQuery .. '%' })

    if dbResults then
        for _, row in ipairs(dbResults) do
            -- Prüfen ob nicht schon in Online-Liste
            local found = false
            for _, r in ipairs(results) do
                if r.identifier == row.identifier then
                    found = true
                    break
                end
            end

            if not found then
                local risk = 'low'
                local rep = tonumber(row.reputation) or 0.5
                if rep < Config.RiskLevels.high then
                    risk = 'high'
                elseif rep < Config.RiskLevels.medium then
                    risk = 'medium'
                end

                table.insert(results, {
                    identifier = row.identifier,
                    name = 'Offline (' .. row.identifier:sub(1, 20) .. '...)',
                    online = false,
                    risk = risk,
                    profile = {
                        reputation = tonumber(row.reputation),
                        violence_tendency = tonumber(row.violence_tendency),
                        flee_tendency = tonumber(row.flee_tendency),
                        cooperation = tonumber(row.cooperation),
                    },
                })
            end
        end
    end

    TriggerClientEvent('mdt:personSearchResults', source, results)
end)

-- ================================================
-- Personen-Details abrufen
-- ================================================

RegisterNetEvent('mdt:getPersonDetails', function(identifier)
    local source = source
    if not IsPolice(source) then return end

    local profile = exports['city_memory']:GetPlayerProfile(identifier)
    local risk = exports['city_memory']:GetRiskLevel(identifier)

    -- Letzte Events abrufen
    local events = PG.query([[
        SELECT event_type, impact, context, created_at
        FROM player_events
        WHERE identifier = ?
        ORDER BY created_at DESC
        LIMIT 20
    ]], { identifier })

    -- Fahrzeuge des Spielers (falls in vehicle_events)
    local vehicles = PG.query([[
        SELECT DISTINCT v.plate, v.heat, v.chase_count, v.crime_association
        FROM vehicle_history v
        JOIN vehicle_events e ON v.plate = e.plate
        WHERE e.driver_identifier = ?
    ]], { identifier })

    -- Online-Status prüfen
    local online = false
    local onlinePlayer = nil
    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(players) do
        if xPlayer.identifier == identifier then
            online = true
            onlinePlayer = {
                id = xPlayer.source,
                name = xPlayer.getName(),
                job = xPlayer.job.label or xPlayer.job.name,
            }
            break
        end
    end

    TriggerClientEvent('mdt:personDetails', source, {
        identifier = identifier,
        profile = profile,
        risk = risk,
        events = events or {},
        vehicles = vehicles or {},
        online = online,
        onlinePlayer = onlinePlayer,
    })
end)

-- ================================================
-- Fahrzeug-Suche
-- ================================================

RegisterNetEvent('mdt:searchVehicle', function(plate)
    local source = source
    if not IsPolice(source) then return end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    local history = exports['city_memory']:GetVehicleHistory(plate)
    local risk = exports['city_memory']:GetVehicleRiskLevel(plate)
    local flagged = exports['city_memory']:IsVehicleFlagged(plate)

    -- Events abrufen
    local events = PG.query([[
        SELECT event_type, driver_identifier, zone_id, created_at
        FROM vehicle_events
        WHERE plate = ?
        ORDER BY created_at DESC
        LIMIT 20
    ]], { plate })

    TriggerClientEvent('mdt:vehicleSearchResults', source, {
        plate = plate,
        history = history,
        risk = risk,
        flagged = flagged,
        events = events or {},
    })
end)

-- ================================================
-- Notizen zu Person hinzufügen
-- ================================================

RegisterNetEvent('mdt:addPersonNote', function(identifier, note)
    local source = source
    if not IsPolice(source) then return end

    local xPlayer = ESX.GetPlayerFromId(source)

    PG.insert([[
        INSERT INTO mdt_notes (identifier, note, created_by, created_by_name, created_at)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
    ]], { identifier, note, xPlayer.identifier, xPlayer.getName() })

    TriggerClientEvent('mdt:noteAdded', source, true)
    Log('MDT', ('%s fügte Notiz zu %s hinzu'):format(xPlayer.getName(), identifier))
end)

-- ================================================
-- Notizen abrufen
-- ================================================

RegisterNetEvent('mdt:getPersonNotes', function(identifier)
    local source = source
    if not IsPolice(source) then return end

    local notes = PG.query([[
        SELECT id, note, created_by_name, created_at
        FROM mdt_notes
        WHERE identifier = ?
        ORDER BY created_at DESC
        LIMIT 50
    ]], { identifier })

    TriggerClientEvent('mdt:personNotes', source, notes or {})
end)

-- ================================================
-- Fahndung erstellen
-- ================================================

RegisterNetEvent('mdt:createWanted', function(data)
    local source = source
    if not IsPolice(source) then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Eingaben validieren/säubern
    local function trim(s) return type(s) == 'string' and (s:gsub('^%s+', ''):gsub('%s+$', '')) or '' end
    local wtype = trim(data and data.type or '')
    local target = trim(data and data.target or '')
    local reason = trim(data and data.reason or '')

    if wtype ~= 'person' and wtype ~= 'vehicle' then wtype = 'person' end
    if #target == 0 or #reason == 0 then
        TriggerClientEvent('mdt:error', source, 'Bitte Ziel und Grund angeben.')
        return
    end
    if #target > 100 then target = target:sub(1, 100) end
    if #reason > 500 then reason = reason:sub(1, 500) end

    -- Berechtigungen prüfen (boss immer erlaubt)
    local grade = (xPlayer.job and xPlayer.job.grade) or 0
    local gradeName = (xPlayer.job and xPlayer.job.grade_name) or ''
    local minGrade = Config.MinGrades.markVehicle or 2
    local hasRight = (gradeName == 'boss') or (grade >= minGrade)

    if not hasRight then
        local msg = ('Nicht genug Berechtigung (Job: %s, Grad: %s, benötigt: %d)')
            :format(xPlayer.job and xPlayer.job.name or 'unbekannt', tostring(grade), minGrade)
        TriggerClientEvent('mdt:error', source, msg)
        Log('MDT', ('Fahndung abgelehnt für %s: %s'):format(xPlayer.getName(), msg))
        return
    end

    PG.insert([[
        INSERT INTO mdt_wanted (type, target, reason, created_by, created_by_name, created_at, active)
        VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, true)
    ]], { wtype, target, reason, xPlayer.identifier, xPlayer.getName() })

    -- Alle Polizisten benachrichtigen
    local cops = ESX.GetExtendedPlayers()
    for _, cop in pairs(cops) do
        if IsPoliceJob(cop.job.name) then
            TriggerClientEvent('mdt:newWanted', cop.source, {
                type = wtype,
                target = target,
                reason = reason,
                createdBy = xPlayer.getName(),
            })
        end
    end

    Log('MDT', ('%s erstellte Fahndung: %s - %s'):format(xPlayer.getName(), wtype, target))

    -- Liste dem Ersteller aktualisieren
    TriggerClientEvent('mdt:wantedList', source, PG.query([[
        SELECT id, type, target, reason, created_by_name, created_at
        FROM mdt_wanted
        WHERE active = true
        ORDER BY created_at DESC
        LIMIT 50
    ]] ) or {})
end)

-- ================================================
-- Aktive Fahndungen abrufen
-- ================================================

RegisterNetEvent('mdt:getWantedList', function()
    local source = source
    if not IsPolice(source) then return end

    local wanted = PG.query([[
        SELECT id, type, target, reason, created_by_name, created_at
        FROM mdt_wanted
        WHERE active = true
        ORDER BY created_at DESC
        LIMIT 50
    ]])

    TriggerClientEvent('mdt:wantedList', source, wanted or {})
end)

-- ================================================
-- Fahndung aufheben
-- ================================================

RegisterNetEvent('mdt:removeWanted', function(wantedId)
    local source = source
    if not IsPolice(source) then return end

    PG.update([[
        UPDATE mdt_wanted
        SET active = false
        WHERE id = ?
    ]], { wantedId })

    TriggerClientEvent('mdt:wantedRemoved', source, wantedId)
end)

-- ================================================
-- Statistiken abrufen
-- ================================================

RegisterNetEvent('mdt:getStatistics', function()
    local source = source
    if not IsPolice(source) then return end

    local stats = {}

    -- Notrufe heute
    local callsToday = PG.scalar([[
        SELECT COUNT(*) FROM dispatch_history
        WHERE created_at >= CURRENT_DATE
    ]])
    stats.callsToday = callsToday or 0

    -- Notrufe diese Woche
    local callsWeek = PG.scalar([[
        SELECT COUNT(*) FROM dispatch_history
        WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
    ]])
    stats.callsWeek = callsWeek or 0

    -- Aktivste Zonen
    local hotZones = PG.query([[
        SELECT zone_id, heat, total_incidents
        FROM zone_memory
        WHERE heat > 0
        ORDER BY heat DESC
        LIMIT 5
    ]])
    stats.hotZones = hotZones or {}

    -- High-Risk Personen
    local highRiskCount = PG.scalar([[
        SELECT COUNT(*) FROM player_profiles
        WHERE reputation < ?
    ]], { Config.RiskLevels.high })
    stats.highRiskPersons = highRiskCount or 0

    -- Markierte Fahrzeuge
    local flaggedVehicles = PG.scalar([[
        SELECT COUNT(*) FROM vehicle_history
        WHERE heat > 0.4 OR chase_count > 2 OR crime_association > 0.3
    ]])
    stats.flaggedVehicles = flaggedVehicles or 0

    -- Notrufe nach Kategorie
    local byCategory = PG.query([[
        SELECT category, COUNT(*) as count
        FROM dispatch_history
        WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY category
        ORDER BY count DESC
    ]])
    stats.byCategory = byCategory or {}

    TriggerClientEvent('mdt:statistics', source, stats)
end)

-- ================================================
-- ADMIN: Erweiterte Statistiken
-- ================================================

RegisterNetEvent('admin:getFullStatistics', function()
    local source = source
    if not IsAdmin(source) then return end

    local stats = {}

    -- Gesamt-Statistiken
    stats.totalProfiles = PG.scalar('SELECT COUNT(*) FROM player_profiles') or 0
    stats.totalVehicles = PG.scalar('SELECT COUNT(*) FROM vehicle_history') or 0
    local historyCount = PG.scalar('SELECT COUNT(*) FROM dispatch_history') or 0
    local activeCount = 0
    if exports['city_memory'] and exports['city_memory'].GetActiveCalls then
        local ok, calls = pcall(function() return exports['city_memory']:GetActiveCalls() end)
        if ok and type(calls) == 'table' then
            activeCount = #calls
        end
    end
    stats.totalCalls = historyCount + activeCount
    stats.totalZoneEvents = PG.scalar('SELECT COUNT(*) FROM zone_events') or 0
    stats.totalPlayerEvents = PG.scalar('SELECT COUNT(*) FROM player_events') or 0

    -- Aktivste Spieler (meiste Events)
stats.topPlayers = PG.query('SELECT identifier, COUNT(*) as event_count FROM player_events GROUP BY identifier ORDER BY event_count DESC LIMIT 10') or {}

local enrichedPlayers = {}
for _, p in ipairs(stats.topPlayers) do
    local name = p.identifier
    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(players) do
        if xPlayer.identifier == p.identifier then
            name = xPlayer.getName()
            break
        end
    end
    table.insert(enrichedPlayers, {
        identifier = p.identifier,
        name = name,
        event_count = p.event_count
    })
end
stats.topPlayers = enrichedPlayers

    -- Aktivste Zonen
    stats.topZones = PG.query([[
        SELECT zone_id, total_incidents, heat
        FROM zone_memory
        ORDER BY total_incidents DESC
        LIMIT 10
    ]]) or {}

    -- Notrufe pro Tag (letzte 7 Tage)
    stats.callsPerDay = PG.query([[
        SELECT DATE(created_at) as date, COUNT(*) as count
        FROM dispatch_history
        WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY DATE(created_at)
        ORDER BY date
    ]]) or {}

    -- System-Info
    stats.cacheInfo = {
        zoneCacheSize = 0,
        profileCacheSize = 0,
        vehicleCacheSize = 0,
    }

    for _ in pairs(ZoneCache) do stats.cacheInfo.zoneCacheSize = stats.cacheInfo.zoneCacheSize + 1 end
    for _ in pairs(ProfileCache) do stats.cacheInfo.profileCacheSize = stats.cacheInfo.profileCacheSize + 1 end
    for _ in pairs(VehicleCache) do stats.cacheInfo.vehicleCacheSize = stats.cacheInfo.vehicleCacheSize + 1 end

    TriggerClientEvent('admin:fullStatistics', source, stats)
end)

-- ================================================
-- ADMIN: Daten Reset
-- ================================================

RegisterNetEvent('admin:resetData', function(dataType)
    local source = source
    if not IsAdmin(source) then return end

    if not Config.Admin.allowDataReset then
        TriggerClientEvent('admin:error', source, 'Daten-Reset ist deaktiviert')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)

    if dataType == 'zones' then
        PG.execute('UPDATE zone_memory SET heat = 0, total_incidents = 0')
        PG.execute('DELETE FROM zone_events')
        ZoneCache = {}
        Log('ADMIN', ('%s hat Zone-Daten zurückgesetzt'):format(xPlayer.getName()))

    elseif dataType == 'profiles' then
        PG.execute('UPDATE player_profiles SET reputation = 0.5, volatility = 0, violence_tendency = 0, flee_tendency = 0')
        PG.execute('DELETE FROM player_events')
        ProfileCache = {}
        Log('ADMIN', ('%s hat Profil-Daten zurückgesetzt'):format(xPlayer.getName()))

    elseif dataType == 'vehicles' then
        PG.execute('DELETE FROM vehicle_events')
        PG.execute('DELETE FROM vehicle_history')
        VehicleCache = {}
        Log('ADMIN', ('%s hat Fahrzeug-Daten zurückgesetzt'):format(xPlayer.getName()))

    elseif dataType == 'dispatch' then
        PG.execute('DELETE FROM dispatch_history')
        Log('ADMIN', ('%s hat Dispatch-Historie zurückgesetzt'):format(xPlayer.getName()))
    end

    TriggerClientEvent('admin:resetSuccess', source, dataType)
end)

-- ================================================
-- ADMIN: Logs abrufen
-- ================================================

RegisterNetEvent('admin:getLogs', function(limit)
    local source = source
    if not IsAdmin(source) then return end

    limit = limit or Config.Admin.maxLogEntries

    local logs = PG.query([[
        SELECT category, message, data, created_at
        FROM city_memory_logs
        ORDER BY created_at DESC
        LIMIT ?
    ]], { limit })

    TriggerClientEvent('admin:logs', source, logs or {})
end)

-- ================================================
-- ADMIN: Alle Notrufe (History + aktive Einsätze)
-- ================================================

RegisterNetEvent('admin:getAllCalls', function(limit)
    local source = source
    if not IsAdmin(source) then return end

    limit = tonumber(limit) or 100

    -- Aktive Notrufe aus Dispatch holen (Export)
    local activeCalls = {}
    if exports['city_memory'] and exports['city_memory'].GetActiveCalls then
        local ok, res = pcall(function()
            return exports['city_memory']:GetActiveCalls()
        end)
        if ok and type(res) == 'table' then
            activeCalls = res
        end
    end

    -- Historie (zuletzt abgeschlossen)
    local history = PG.query([[
        SELECT id, call_id, category, priority, message, caller_name, location_zone, location_street,
               coords_x, coords_y, coords_z, created_at, closed_at, units_count
        FROM dispatch_history
        ORDER BY created_at DESC
        LIMIT ?
    ]], { limit }) or {}

    TriggerClientEvent('admin:allCalls', source, {
        active = activeCalls,
        history = history
    })
end)

Log('MDT', 'sv_mdt.lua geladen')
