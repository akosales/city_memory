-- ================================================
-- City Memory System - Client Effects
-- ================================================

local currentZone = nil
local currentAtmosphere = 'calm'

-- ================================================
-- Zone Atmosphere Handler
-- ================================================

RegisterNetEvent('city_memory:zoneAtmosphere', function(atmosphere, zoneId)
    if atmosphere == currentAtmosphere and zoneId == currentZone then
        return
    end
    
    currentZone = zoneId
    currentAtmosphere = atmosphere
    
    if atmosphere == 'heated' then
        PlayHeatedEffect()
    elseif atmosphere == 'tense' then
        PlayTenseEffect()
    else
        ClearAtmosphereEffects()
    end
end)

-- ================================================
-- Effekt: Heated (hohe Anspannung)
-- ================================================

function PlayHeatedEffect()
    PlaySoundFrontend(-1, 'MP_WAVE_COMPLETE', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    
    SetTimecycleModifier('REDMIST')
    SetTimecycleModifierStrength(0.1)
    
    SetTimeout(2000, function()
        ClearTimecycleModifier()
    end)
end

-- ================================================
-- Effekt: Tense (mittlere Anspannung)
-- ================================================

function PlayTenseEffect()
    PlaySoundFrontend(-1, 'HIGHLIGHT_NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(0.05)
    
    SetTimeout(1000, function()
        ClearTimecycleModifier()
    end)
end

-- ================================================
-- Effekte zurücksetzen
-- ================================================

function ClearAtmosphereEffects()
    ClearTimecycleModifier()
    currentAtmosphere = 'calm'
end

-- ================================================
-- Schusswaffengebrauch erkennen
-- ================================================

local lastShotReport = 0
local SHOT_REPORT_COOLDOWN = 60000

CreateThread(function()
    while true do
        Wait(500)
        
        local playerPed = PlayerPedId()
        
        if IsPedShooting(playerPed) then
            local now = GetGameTimer()
            
            if now - lastShotReport > SHOT_REPORT_COOLDOWN then
                lastShotReport = now
                TriggerServerEvent('city_memory:reportShooting')
            end
        end
    end
end)

-- ================================================
-- Waffengebrauch gegen Spieler/NPC erkennen
-- ================================================

local lastWeaponReport = 0
local WEAPON_REPORT_COOLDOWN = 30000

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    
    local victim = args[1]
    local attacker = args[2]
    local playerPed = PlayerPedId()
    
    if attacker ~= playerPed then return end
    if not IsPedAPlayer(attacker) then return end
    
    local now = GetGameTimer()
    if now - lastWeaponReport < WEAPON_REPORT_COOLDOWN then return end
    
    lastWeaponReport = now
    
    if IsPedAPlayer(victim) then
        local victimPlayer = NetworkGetPlayerIndexFromPed(victim)
        local victimServerId = GetPlayerServerId(victimPlayer)
        TriggerServerEvent('city_memory:reportWeaponUsePlayer', victimServerId)
    else
        TriggerServerEvent('city_memory:reportWeaponUseNPC')
    end
end)

-- ================================================
-- Verfolgungsjagd erkennen
-- ================================================

local lastChaseReport = 0
local CHASE_REPORT_COOLDOWN = 90000

CreateThread(function()
    while true do
        Wait(2000)
        
        local playerPed = PlayerPedId()
        local wantedLevel = GetPlayerWantedLevel(PlayerId())
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and wantedLevel > 0 then
            local speed = GetEntitySpeed(vehicle) * 3.6
            
            if speed > 80 then
                local now = GetGameTimer()
                
                if now - lastChaseReport > CHASE_REPORT_COOLDOWN then
                    lastChaseReport = now
                    
                    local plate = GetVehicleNumberPlateText(vehicle)
                    TriggerServerEvent('city_memory:reportChase')
                    TriggerServerEvent('city_memory:reportVehicleChase', plate)
                end
            end
        end
    end
end)

-- ================================================
-- Flucht erkennen
-- ================================================

local wasWanted = false

CreateThread(function()
    while true do
        Wait(5000)
        
        local wantedLevel = GetPlayerWantedLevel(PlayerId())
        
        if wasWanted and wantedLevel == 0 then
            TriggerServerEvent('city_memory:reportFlee')
            
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= 0 then
                local plate = GetVehicleNumberPlateText(vehicle)
                TriggerServerEvent('city_memory:reportVehicleFlee', plate)
            end
        end
        
        wasWanted = wantedLevel > 0
    end
end)

-- ================================================
-- Cleanup
-- ================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ClearAtmosphereEffects()
end)
