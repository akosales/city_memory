-- ================================================
-- City Memory System - Zone Heat Management
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Cooldown-Tracking pro Zone/Event
local EventCooldowns = {}
-- Request-Rate-Limit pro Spieler (Heatmap anfordern)
local HeatRequestCooldown = {}

-- ================================================
-- Helper: Cooldown Check
-- ================================================

local function IsOnCooldown(zoneId, eventType)
    local key = zoneId .. ':' .. eventType
    local cooldownEnd = EventCooldowns[key]

    if cooldownEnd and GetGameTimer() < cooldownEnd then
        return true
    end
    return false
end

local function SetCooldown(zoneId, eventType)
    local key = zoneId .. ':' .. eventType
    local cooldownMs = (Config.EventCooldowns[eventType] or 60) * 1000
    EventCooldowns[key] = GetGameTimer() + cooldownMs
end

-- ================================================
-- Heat erhöhen
-- ================================================

local function AddZoneHeat(zoneId, eventType, severity, sourceIdentifier)
    if not Config.Zones[zoneId] then
        Log('ZONE', ('Unbekannte Zone: %s'):format(zoneId))
        return false
    end

    -- Cooldown prüfen
    if IsOnCooldown(zoneId, eventType) then
        Log('ZONE', ('Event auf Cooldown: %s in %s'):format(eventType, zoneId))
        return false
    end

    -- Heat-Modifier aus Config oder übergebene Severity
    local heatIncrease = severity or Config.HeatModifiers[eventType] or 0.10

    -- Zone aus Cache holen
    local zone = GetCachedZone(zoneId)
    local currentHeat = zone and zone.heat or 0.0
    local newHeat = math.min(Config.ZoneHeat.max, currentHeat + heatIncrease)

    -- DB Update
    PG.update([[
        UPDATE zone_memory
        SET heat = ?,
            last_incident = CURRENT_TIMESTAMP,
            total_incidents = total_incidents + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE zone_id = ?
    ]], { newHeat, zoneId })

    -- Event loggen
    PG.insert([[
        INSERT INTO zone_events (zone_id, event_type, severity, source_identifier)
        VALUES (?, ?, ?, ?)
    ]], { zoneId, eventType, heatIncrease, sourceIdentifier })

    -- Cache aktualisieren
    ZoneCache[zoneId] = {
        heat = newHeat,
        lastIncident = os.time(),
        totalIncidents = (zone and zone.totalIncidents or 0) + 1,
        timestamp = GetGameTimer()
    }

    -- Cooldown setzen
    SetCooldown(zoneId, eventType)

    Log('ZONE', ('Heat erhöht: %s %.3f -> %.3f (%s)'):format(zoneId, currentHeat, newHeat, eventType))

    -- Client-Effekte triggern für Spieler in der Zone
    TriggerZoneEffects(zoneId, newHeat)

    return true
end

-- ================================================
-- Heat abfragen
-- ================================================

local function GetZoneHeat(zoneId)
    local zone = GetCachedZone(zoneId)
    return zone and zone.heat or 0.0
end

-- ================================================
-- Alle "heißen" Zonen abrufen
-- ================================================

local function GetHotZones(threshold)
    threshold = threshold or 0.3
    local hotZones = {}

    for zoneId, zone in pairs(ZoneCache) do
        if zone.heat >= threshold then
            hotZones[zoneId] = {
                heat = zone.heat,
                label = Config.Zones[zoneId] and Config.Zones[zoneId].label or zoneId,
                lastIncident = zone.lastIncident
            }
        end
    end

    return hotZones
end

-- ================================================
-- Zone von Koordinaten ermitteln (Server-Version)
-- ================================================

local function GetZoneFromCoordsServer(coords)
    for zoneId, zone in pairs(Config.Zones) do
        local distance = #(coords - zone.coords)
        if distance <= zone.radius then
            return zoneId
        end
    end
    return nil
end

-- ================================================
-- Client-Effekte triggern
-- ================================================

function TriggerZoneEffects(zoneId, heat)
    local zone = Config.Zones[zoneId]
    if not zone then return end

    -- Bestimme Atmosphäre basierend auf Heat
    local atmosphere = 'calm'
    if heat >= 0.7 then
        atmosphere = 'heated'
    elseif heat >= 0.4 then
        atmosphere = 'tense'
    end

    -- Trigger für alle Spieler in der Zone
    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(players) do
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - zone.coords)

            if distance <= zone.radius then
                TriggerClientEvent('city_memory:zoneAtmosphere', xPlayer.source, atmosphere, zoneId)
            end
        end
    end
end

-- ================================================
-- Events von anderen Scripts
-- ================================================

-- Schusswaffengebrauch
RegisterNetEvent('city_memory:reportShooting', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = GetZoneFromCoordsServer(coords)

    if zoneId then
        AddZoneHeat(zoneId, 'shooting', nil, xPlayer.identifier)
    end
end)

-- Polizeieinsatz
RegisterNetEvent('city_memory:reportPoliceDispatch', function(coords)
    local zoneId = GetZoneFromCoordsServer(coords)
    if zoneId then
        AddZoneHeat(zoneId, 'police_dispatch', nil, nil)
    end
end)

-- Verfolgungsjagd
RegisterNetEvent('city_memory:reportChase', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = GetZoneFromCoordsServer(coords)

    if zoneId then
        AddZoneHeat(zoneId, 'chase', nil, xPlayer.identifier)
    end
end)

-- Notruf
RegisterNetEvent('city_memory:reportEmergencyCall', function(coords)
    local zoneId = GetZoneFromCoordsServer(coords)
    if zoneId then
        AddZoneHeat(zoneId, 'emergency_call', nil, nil)
    end
end)

-- Gewaltdelikt
RegisterNetEvent('city_memory:reportViolentCrime', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = GetZoneFromCoordsServer(coords)

    if zoneId then
        AddZoneHeat(zoneId, 'violent_crime', nil, xPlayer.identifier)
    end
end)

-- ================================================
-- Exports registrieren
-- ================================================

exports('GetZoneHeat', GetZoneHeat)
exports('GetHotZones', GetHotZones)
exports('RegisterZoneEvent', function(zoneId, eventType, severity, sourceIdentifier)
    return AddZoneHeat(zoneId, eventType, severity, sourceIdentifier)
end)
exports('GetZoneFromCoords', GetZoneFromCoordsServer)

Log('ZONES', 'sv_zones.lua geladen')


-- ================================================
-- Client: Zone-Heat anfordern (Heatmap)
-- ================================================

RegisterNetEvent('city_memory:requestZoneHeat', function()
    local src = source

    -- Rate Limit
    local now = GetGameTimer()
    local minInterval = (Config.ZoneHeatmap and Config.ZoneHeatmap.requestCooldownMs) or 5000
    local last = HeatRequestCooldown[src] or 0
    if (now - last) < minInterval then
        return
    end
    HeatRequestCooldown[src] = now

    local xPlayer = ESX.GetPlayerFromId(src)
    local jobName = xPlayer and xPlayer.job and xPlayer.job.name or nil
    local isCop = jobName and IsPoliceJob(jobName) or false

    local copMin = (Config.ZoneHeatmap and Config.ZoneHeatmap.copMin) or 0.10
    local civMin = (Config.ZoneHeatmap and Config.ZoneHeatmap.civMin) or 0.50
    local minHeat = isCop and copMin or civMin

    local zones = {}

    for zoneId, z in pairs(Config.Zones) do
        local heat = GetZoneHeat(zoneId)
        if heat and heat >= (minHeat or 0.1) then
            local c = (z.center or z.coords)
            if c then
                zones[zoneId] = {
                    heat = heat,
                    coords = { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0 }
                }
            end
        end
    end

    TriggerClientEvent('city_memory:receiveZoneHeat', src, zones)
end)
