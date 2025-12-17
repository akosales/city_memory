-- ================================================
-- City Memory System - Vehicle History Management
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Vehicle Cache
local VEHICLE_CACHE_TTL = 120000 -- 2 Minuten

-- ================================================
-- Helper: Cache
-- ================================================

local function GetCachedVehicle(plate)
    local cached = VehicleCache[plate]
    if cached and (GetGameTimer() - cached.timestamp) < VEHICLE_CACHE_TTL then
        return cached.data
    end
    
    local result = PG.query('SELECT * FROM vehicle_history WHERE plate = ?', { plate })
    if result and result[1] then
        VehicleCache[plate] = {
            data = result[1],
            timestamp = GetGameTimer()
        }
        return result[1]
    end
    return nil
end

-- ================================================
-- Fahrzeug registrieren (falls neu)
-- ================================================

local function EnsureVehicleExists(plate)
    PG.execute([[
        INSERT INTO vehicle_history (plate)
        VALUES (?)
        ON CONFLICT (plate) DO NOTHING
    ]], { plate })
end

-- ================================================
-- Event registrieren
-- ================================================

local function RegisterVehicleEvent(plate, eventType, driverIdentifier, zoneId)
    if not plate or plate == '' then
        Log('VEHICLE', 'Ungültiges Kennzeichen')
        return false
    end
    
    -- Normalisieren
    plate = string.upper(string.gsub(plate, '%s+', ''))
    
    -- Fahrzeug sicherstellen
    EnsureVehicleExists(plate)
    
    -- Heat-Modifikator je nach Event
    local heatIncrease = 0.10
    local chaseIncrement = 0
    local crimeIncrement = 0.0
    
    if eventType == 'chase' then
        heatIncrease = 0.20
        chaseIncrement = 1
        crimeIncrement = 0.15
    elseif eventType == 'shooting' then
        heatIncrease = 0.25
        crimeIncrement = 0.20
    elseif eventType == 'flee' then
        heatIncrease = 0.15
        crimeIncrement = 0.10
    elseif eventType == 'traffic_stop' then
        heatIncrease = 0.02
    elseif eventType == 'crime_scene' then
        heatIncrease = 0.18
        crimeIncrement = 0.15
    end
    
    -- Aktuelles Fahrzeug holen
    local vehicle = GetCachedVehicle(plate)
    local currentHeat = vehicle and tonumber(vehicle.heat) or 0.0
    local newHeat = math.min(1.0, currentHeat + heatIncrease)
    
    local currentCrime = vehicle and tonumber(vehicle.crime_association) or 0.0
    local newCrime = math.min(1.0, currentCrime + crimeIncrement)
    
    -- DB Update
    PG.update([[
        UPDATE vehicle_history
        SET heat = ?,
            chase_count = chase_count + ?,
            crime_association = ?,
            last_incident = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE plate = ?
    ]], { newHeat, chaseIncrement, newCrime, plate })
    
    -- Event loggen
    PG.insert([[
        INSERT INTO vehicle_events (plate, event_type, driver_identifier, zone_id)
        VALUES (?, ?, ?, ?)
    ]], { plate, eventType, driverIdentifier, zoneId })
    
    -- Cache invalidieren
    VehicleCache[plate] = nil
    
    Log('VEHICLE', ('Event registriert: %s - %s (Heat: %.3f -> %.3f)'):format(
        plate, eventType, currentHeat, newHeat
    ))
    
    return true
end

-- ================================================
-- Fahrzeug-Historie abrufen
-- ================================================

local function GetVehicleHistory(plate)
    if not plate then return nil end
    
    plate = string.upper(string.gsub(plate, '%s+', ''))
    local vehicle = GetCachedVehicle(plate)
    
    if not vehicle then return nil end
    
    return {
        plate = vehicle.plate,
        heat = tonumber(vehicle.heat) or 0.0,
        chaseCount = vehicle.chase_count or 0,
        crimeAssociation = tonumber(vehicle.crime_association) or 0.0,
        lastIncident = vehicle.last_incident,
        firstSeen = vehicle.first_seen
    }
end

-- ================================================
-- Fahrzeug geflaggt?
-- ================================================

local function IsVehicleFlagged(plate)
    if not plate then return false end
    
    plate = string.upper(string.gsub(plate, '%s+', ''))
    local vehicle = GetCachedVehicle(plate)
    
    if not vehicle then return false end
    
    -- Geflaggt wenn: Heat > 0.4 ODER chase_count > 2 ODER crime_association > 0.3
    local heat = tonumber(vehicle.heat) or 0.0
    local chases = vehicle.chase_count or 0
    local crime = tonumber(vehicle.crime_association) or 0.0
    
    return heat > 0.4 or chases > 2 or crime > 0.3
end

-- ================================================
-- Fahrzeug-Risiko-Level
-- ================================================

local function GetVehicleRiskLevel(plate)
    if not plate then return 'unknown' end
    
    plate = string.upper(string.gsub(plate, '%s+', ''))
    local vehicle = GetCachedVehicle(plate)
    
    if not vehicle then return 'clean' end
    
    local heat = tonumber(vehicle.heat) or 0.0
    local crime = tonumber(vehicle.crime_association) or 0.0
    local score = (heat + crime) / 2
    
    if score >= 0.6 then
        return 'high'
    elseif score >= 0.3 then
        return 'medium'
    elseif score > 0 then
        return 'low'
    else
        return 'clean'
    end
end

-- ================================================
-- Events von anderen Scripts
-- ================================================

-- Verfolgungsjagd mit Fahrzeug
RegisterNetEvent('city_memory:reportVehicleChase', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    RegisterVehicleEvent(plate, 'chase', xPlayer.identifier, zoneId)
end)

-- Schüsse aus Fahrzeug
RegisterNetEvent('city_memory:reportVehicleShooting', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    RegisterVehicleEvent(plate, 'shooting', xPlayer.identifier, zoneId)
end)

-- Fahrzeug flüchtet
RegisterNetEvent('city_memory:reportVehicleFlee', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    RegisterVehicleEvent(plate, 'flee', xPlayer.identifier, zoneId)
end)

-- Verkehrskontrolle (von Polizei gemeldet)
RegisterNetEvent('city_memory:reportTrafficStop', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'police' then return end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    RegisterVehicleEvent(plate, 'traffic_stop', nil, zoneId)
end)

-- Fahrzeug an Tatort (von Polizei gemeldet)
RegisterNetEvent('city_memory:reportVehicleAtCrimeScene', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'police' then return end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    RegisterVehicleEvent(plate, 'crime_scene', nil, zoneId)
end)

-- ================================================
-- Polizei: Kennzeichen-Abfrage
-- ================================================

RegisterNetEvent('city_memory:queryPlate', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'police' then return end
    
    local history = GetVehicleHistory(plate)
    local risk = GetVehicleRiskLevel(plate)
    
    TriggerClientEvent('city_memory:plateQueryResult', source, {
        plate = plate,
        history = history,
        risk = risk,
        flagged = IsVehicleFlagged(plate)
    })
end)

-- ================================================
-- Exports registrieren
-- ================================================

exports('GetVehicleHistory', GetVehicleHistory)
exports('IsVehicleFlagged', IsVehicleFlagged)
exports('GetVehicleRiskLevel', GetVehicleRiskLevel)
exports('RegisterVehicleEvent', RegisterVehicleEvent)

Log('VEHICLES', 'sv_vehicles.lua geladen')
