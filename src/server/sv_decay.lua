-- ================================================
-- City Memory System - Decay Management
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================
-- Zone Decay
-- ================================================

local function DecayZones()
    local decayRate = Config.ZoneHeat.decayRate
    local acceleratedRate = Config.ZoneHeat.decayAccelerated
    
    -- Alle Zonen mit Heat > 0 abrufen
    local zones = PG.query([[
        SELECT zone_id, heat, last_incident,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - last_incident)) * 1000 as ms_since_incident
        FROM zone_memory 
        WHERE heat > 0
    ]])
    
    if not zones then return end
    
    for _, zone in ipairs(zones) do
        local msSinceIncident = tonumber(zone.ms_since_incident) or 0
        local rate = decayRate
        
        -- Beschleunigter Decay wenn lange kein Event
        if msSinceIncident > Config.ZoneHeat.acceleratedThreshold then
            rate = acceleratedRate
        end
        
        local currentHeat = tonumber(zone.heat) or 0
        local newHeat = math.max(0, currentHeat - rate)
        
        PG.update([[
            UPDATE zone_memory
            SET heat = ?, updated_at = CURRENT_TIMESTAMP
            WHERE zone_id = ?
        ]], { newHeat, zone.zone_id })
        
        -- Cache aktualisieren
        if ZoneCache[zone.zone_id] then
            ZoneCache[zone.zone_id].heat = newHeat
            ZoneCache[zone.zone_id].timestamp = GetGameTimer()
        end
        
        if Config.Debug and newHeat ~= currentHeat then
            Log('DECAY', ('Zone %s: %.3f -> %.3f'):format(zone.zone_id, currentHeat, newHeat))
        end
    end
end

-- ================================================
-- Player Profile Decay
-- ================================================

local function DecayProfiles()
    local decayRate = Config.PlayerProfile.decayRate
    local defaultRep = Config.PlayerProfile.defaultReputation
    
    -- Nur negative Reputationen erholen sich
    PG.update([[
        UPDATE player_profiles
        SET reputation = LEAST(?, reputation + ?),
            volatility = GREATEST(0, volatility - 0.01),
            violence_tendency = GREATEST(0, violence_tendency - 0.005),
            flee_tendency = GREATEST(0, flee_tendency - 0.005),
            updated_at = CURRENT_TIMESTAMP
        WHERE reputation < ?
    ]], { defaultRep, decayRate, defaultRep })
    
    -- Cache leeren
    ProfileCache = {}
    
    Log('DECAY', 'Player profiles decay ausgeführt')
end

-- ================================================
-- Vehicle Decay
-- ================================================

local function DecayVehicles()
    PG.update([[
        UPDATE vehicle_history
        SET heat = GREATEST(0, heat - 0.005),
            crime_association = GREATEST(0, crime_association - 0.003),
            updated_at = CURRENT_TIMESTAMP
        WHERE heat > 0 OR crime_association > 0
    ]])
    
    -- Cache leeren
    VehicleCache = {}
    
    Log('DECAY', 'Vehicle decay ausgeführt')
end

-- ================================================
-- Peaceful Day Bonus
-- ================================================

local function CheckPeacefulDay()
    local players = PG.query([[
        SELECT identifier 
        FROM player_profiles
        WHERE reputation < 1.0
        AND (last_negative_event IS NULL 
             OR last_negative_event < CURRENT_TIMESTAMP - INTERVAL '24 hours')
        AND (last_positive_event IS NULL 
             OR last_positive_event < CURRENT_TIMESTAMP - INTERVAL '24 hours')
    ]])
    
    if not players then return end
    
    for _, player in ipairs(players) do
        local bonus = Config.ReputationModifiers['peaceful_day'] or 0.01
        
        PG.update([[
            UPDATE player_profiles
            SET reputation = LEAST(1.0, reputation + ?),
                last_positive_event = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE identifier = ?
        ]], { bonus, player.identifier })
        
        Log('DECAY', ('Peaceful day bonus für: %s'):format(player.identifier))
    end
end

-- ================================================
-- Main Decay Thread
-- ================================================

CreateThread(function()
    Wait(5000)
    
    Log('DECAY', 'Decay-System gestartet')
    
    while true do
        Wait(Config.DecayInterval)
        
        local success, err = pcall(function()
            DecayZones()
            DecayProfiles()
            DecayVehicles()
        end)
        
        if not success then
            Log('DECAY', ('Fehler im Decay-System: %s'):format(tostring(err)))
        end
    end
end)

-- ================================================
-- Peaceful Day Check (einmal pro Stunde)
-- ================================================

CreateThread(function()
    Wait(10000)
    
    while true do
        Wait(3600000) -- 1 Stunde
        
        local success, err = pcall(CheckPeacefulDay)
        if not success then
            Log('DECAY', ('Fehler bei peaceful day check: %s'):format(tostring(err)))
        end
    end
end)

-- ================================================
-- Admin Commands
-- ================================================

RegisterCommand('cm_force_decay', function(source)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.group ~= 'admin' then
            return
        end
    end
    
    DecayZones()
    DecayProfiles()
    DecayVehicles()
    
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^2[City Memory]', 'Force decay ausgeführt.' }
        })
    end
    
    Log('DECAY', 'Force decay durch Admin ausgeführt')
end, true)

RegisterCommand('cm_reset_zone', function(source, args)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.group ~= 'admin' then
            return
        end
    end
    
    local zoneId = args[1]
    if not zoneId then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1[City Memory]', 'Usage: /cm_reset_zone [zone_id]' }
            })
        end
        return
    end
    
    PG.update([[
        UPDATE zone_memory
        SET heat = 0, total_incidents = 0, updated_at = CURRENT_TIMESTAMP
        WHERE zone_id = ?
    ]], { zoneId })
    
    ZoneCache[zoneId] = nil
    
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^2[City Memory]', ('Zone %s zurückgesetzt.'):format(zoneId) }
        })
    end
    
    Log('DECAY', ('Zone %s durch Admin zurückgesetzt'):format(zoneId))
end, true)

RegisterCommand('cm_reset_player', function(source, args)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.group ~= 'admin' then
            return
        end
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1[City Memory]', 'Usage: /cm_reset_player [player_id]' }
            })
        end
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1[City Memory]', 'Spieler nicht gefunden.' }
            })
        end
        return
    end
    
    PG.update([[
        UPDATE player_profiles
        SET reputation = 0.5, volatility = 0, cooperation = 0.5, 
            violence_tendency = 0, flee_tendency = 0, updated_at = CURRENT_TIMESTAMP
        WHERE identifier = ?
    ]], { xTarget.identifier })
    
    ProfileCache[xTarget.identifier] = nil
    
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^2[City Memory]', ('Profil von %s zurückgesetzt.'):format(xTarget.getName()) }
        })
    end
    
    Log('DECAY', ('Profil %s durch Admin zurückgesetzt'):format(xTarget.identifier))
end, true)

Log('DECAY', 'sv_decay.lua geladen')
