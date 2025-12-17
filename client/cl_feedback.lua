-- ================================================
-- City Memory System - Client Feedback
-- ================================================

-- ================================================
-- Sound abspielen
-- ================================================

RegisterNetEvent('city_memory:playSound', function(soundType)
    if soundType == 'query' then
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    elseif soundType == 'alert' then
        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false)
    elseif soundType == 'warning' then
        PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    elseif soundType == 'success' then
        PlaySoundFrontend(-1, 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET', false)
    end
end)

-- ================================================
-- Kennzeichen-Abfrage Ergebnis (für Polizei)
-- ================================================

RegisterNetEvent('city_memory:plateQueryResult', function(data)
    if not data then return end
    
    local plate = data.plate
    local risk = data.risk
    local flagged = data.flagged
    local history = data.history
    
    local message = ('Kennzeichen: %s\n'):format(plate)
    
    if risk == 'high' then
        message = message .. '^1Vorsicht empfohlen^7\n'
    elseif risk == 'medium' then
        message = message .. '^3Auffälligkeiten bekannt^7\n'
    elseif risk == 'low' then
        message = message .. '^7Vereinzelte Einträge^7\n'
    else
        message = message .. '^2Keine Einträge^7\n'
    end
    
    if flagged then
        message = message .. '^1Fahrzeug ist markiert^7\n'
    end
    
    if history and history.chaseCount and history.chaseCount > 0 then
        message = message .. ('Verfolgungen: %d\n'):format(history.chaseCount)
    end
    
    TriggerEvent('chat:addMessage', {
        color = { 100, 150, 255 },
        multiline = true,
        args = { '[Kennzeichen-Abfrage]', message }
    })
    
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
end)

-- ================================================
-- Zone-Hinweis beim Betreten
-- ================================================

local lastZoneHint = nil
local ZONE_HINT_COOLDOWN = 300000

RegisterNetEvent('city_memory:zoneHint', function(zoneId, label, heatLevel)
    local key = zoneId
    if lastZoneHint == key then return end
    lastZoneHint = key
    
    SetTimeout(ZONE_HINT_COOLDOWN, function()
        if lastZoneHint == key then
            lastZoneHint = nil
        end
    end)
    
    local hint = nil
    
    if heatLevel == 'heated' then
        hint = 'Die Stimmung hier ist angespannt.'
    elseif heatLevel == 'tense' then
        hint = 'In letzter Zeit gab es hier Vorfälle.'
    end
    
    if hint then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(hint)
        EndTextCommandThefeedPostTicker(false, false)
    end
end)

-- ================================================
-- Allgemeine Hinweise
-- ================================================

RegisterNetEvent('city_memory:hint', function(message, hintType)
    hintType = hintType or 'info'
    
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end)

-- ================================================
-- Polizei: Risiko-Hinweis bei Kontrolle
-- ================================================

RegisterNetEvent('city_memory:playerRiskHint', function(targetId, riskLevel)
    local hint = nil
    
    if riskLevel == 'high' then
        hint = 'Person ist polizeibekannt. Erhöhte Vorsicht.'
        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false)
    elseif riskLevel == 'medium' then
        hint = 'Person hat vereinzelte Einträge.'
    end
    
    if hint then
        TriggerEvent('chat:addMessage', {
            color = { 255, 200, 100 },
            args = { '[Einsatzhinweis]', hint }
        })
    end
end)

-- ================================================
-- Debug: Zone Info
-- ================================================

RegisterNetEvent('city_memory:debugZoneInfo', function(zoneId, heat, incidents)
    TriggerEvent('chat:addMessage', {
        color = { 150, 150, 150 },
        args = { 
            '[CM Debug]', 
            ('Zone: %s | Heat: %.3f | Vorfälle: %d'):format(zoneId, heat, incidents)
        }
    })
end)
