-- ================================================
-- City Memory System - Main Server Entry
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Cache für Performance
ZoneCache = {}
ProfileCache = {}
VehicleCache = {}

local CACHE_TTL = 60000 -- 1 Minute

-- ================================================
-- Logging
-- ================================================

function Log(category, message, data)
    if Config.Debug then
        print(('[^3CITY_MEMORY^7][^5%s^7] %s'):format(category, message))
        if data then
            print(json.encode(data))
        end
    end

    if Config.PersistentLogs then
        local jsonData = data and json.encode(data) or '{}'
        PG.insert([[INSERT INTO city_memory_logs (category, message, data) VALUES (?, ?, ?::jsonb)]], {
            category, message, jsonData
        })
    end
end

-- ================================================
-- Initialisierung
-- ================================================

CreateThread(function()
    Wait(2000) -- Warte auf DB-Verbindung

    Log('INIT', 'City Memory System wird gestartet...')

    -- Zonen aus Config in DB initialisieren
    for zoneId, zone in pairs(Config.Zones) do
        PG.execute([[
            INSERT INTO zone_memory (zone_id)
            VALUES (?)
            ON CONFLICT (zone_id) DO NOTHING
        ]], { zoneId })
    end

    -- Zonen-Cache laden
    local zones = PG.query('SELECT * FROM zone_memory')
    if zones then
        for _, zone in ipairs(zones) do
            ZoneCache[zone.zone_id] = {
                heat = tonumber(zone.heat) or 0.0,
                lastIncident = zone.last_incident,
                totalIncidents = zone.total_incidents or 0,
                timestamp = GetGameTimer()
            }
        end
        Log('INIT', ('System gestartet. %d Zonen geladen.'):format(#zones))
    else
        Log('INIT', 'Keine Zonen geladen - DB Verbindung prüfen!')
    end
end)

-- ================================================
-- Spieler-Session Management
-- ================================================

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local identifier = xPlayer.identifier

    -- Profil laden oder erstellen
    PG.execute([[
        INSERT INTO player_profiles (identifier, reputation)
        VALUES (?, ?)
        ON CONFLICT (identifier) DO NOTHING
    ]], { identifier, Config.PlayerProfile.defaultReputation })

    -- In Cache laden
    local profile = PG.query('SELECT * FROM player_profiles WHERE identifier = ?', { identifier })
    if profile and profile[1] then
        ProfileCache[identifier] = {
            data = profile[1],
            timestamp = GetGameTimer()
        }
    end

    Log('PLAYER', ('Spieler geladen: %s'):format(identifier))
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        -- Cache leeren
        ProfileCache[xPlayer.identifier] = nil
        Log('PLAYER', ('Spieler disconnected: %s'):format(xPlayer.identifier))
    end
end)

-- ================================================
-- Utility: Cache mit TTL
-- ================================================

function GetCachedProfile(identifier)
    local cached = ProfileCache[identifier]
    if cached and (GetGameTimer() - cached.timestamp) < CACHE_TTL then
        return cached.data
    end

    local result = PG.query('SELECT * FROM player_profiles WHERE identifier = ?', { identifier })
    if result and result[1] then
        ProfileCache[identifier] = {
            data = result[1],
            timestamp = GetGameTimer()
        }
        return result[1]
    end
    return nil
end

function GetCachedZone(zoneId)
    local cached = ZoneCache[zoneId]
    if cached and (GetGameTimer() - cached.timestamp) < CACHE_TTL then
        return cached
    end

    local result = PG.query('SELECT * FROM zone_memory WHERE zone_id = ?', { zoneId })
    if result and result[1] then
        ZoneCache[zoneId] = {
            heat = tonumber(result[1].heat) or 0.0,
            lastIncident = result[1].last_incident,
            totalIncidents = result[1].total_incidents or 0,
            timestamp = GetGameTimer()
        }
        return ZoneCache[zoneId]
    end
    return nil
end

-- ================================================
-- Admin Debug Command
-- ================================================

RegisterCommand('cm_status', function(source)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.group ~= 'admin' then
            return
        end
    end

    local zoneCount = 0
    local hotZones = 0
    for zoneId, zone in pairs(ZoneCache) do
        zoneCount = zoneCount + 1
        if zone.heat > 0.3 then
            hotZones = hotZones + 1
        end
    end

    local profileCount = 0
    for _ in pairs(ProfileCache) do
        profileCount = profileCount + 1
    end

    local msg = ('Zonen: %d (Hot: %d) | Profile cached: %d'):format(zoneCount, hotZones, profileCount)

    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^2[City Memory]', msg }
        })
    else
        print('[City Memory] ' .. msg)
    end
end, true)

Log('INIT', 'main.lua geladen')
