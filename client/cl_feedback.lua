-- ================================================
-- City Memory System - Client Feedback
-- v2.2 - Zone-Warnungen & Onboarding für Zivilisten
-- ================================================

-- ================================================
-- Onboarding Flags (persistent via KVP)
-- ================================================

local hasSeenZoneWarningIntro = GetResourceKvpInt('city_memory:zone_warning_intro') == 1
local hasSeenNotrufHint = GetResourceKvpInt('city_memory:notruf_hint') == 1

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
    elseif soundType == 'danger' then
        PlaySoundFrontend(-1, 'FLIGHT_SCHOOL_LESSON_FAILED', 'HUD_AWARDS', false)
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
-- Zone-Warnung beim Betreten (für Zivilisten)
-- ================================================

local lastZoneWarning = nil
local ZONE_WARNING_COOLDOWN = 600000 -- 10 Minuten pro Zone

RegisterNetEvent('city_memory:zoneWarning', function(zoneId, zoneName, heatValue, recentIncidents)
    -- Cooldown prüfen
    if lastZoneWarning == zoneId then return end
    lastZoneWarning = zoneId

    SetTimeout(ZONE_WARNING_COOLDOWN, function()
        if lastZoneWarning == zoneId then
            lastZoneWarning = nil
        end
    end)

    -- Warnstufe bestimmen
    local level = 'low'
    local icon = '🟢'
    local title = zoneName or 'Unbekannte Zone'
    local message = ''

    if heatValue >= 0.7 then
        level = 'high'
        icon = '🔴'
        message = 'Gefährliche Gegend! Hier passiert viel Kriminalität.'
        PlaySoundFrontend(-1, 'FLIGHT_SCHOOL_LESSON_FAILED', 'HUD_AWARDS', false)
    elseif heatValue >= 0.4 then
        level = 'medium'
        icon = '🟠'
        message = 'Vorsicht! Erhöhte Kriminalität in dieser Gegend.'
        PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    else
        -- Keine Warnung für ruhige Zonen
        return
    end

    -- Onboarding beim ersten Mal
    if not hasSeenZoneWarningIntro then
        hasSeenZoneWarningIntro = true
        SetResourceKvpInt('city_memory:zone_warning_intro', 1)

        -- Erweiterte Erklärung beim ersten Mal
        SendNUIMessage({
            type = 'showZoneWarningIntro',
            zoneName = title,
            level = level,
            message = message,
            incidents = recentIncidents or 0
        })
        return
    end

    -- Normale Warnung (NUI Toast)
    SendNUIMessage({
        type = 'showZoneWarning',
        zoneName = title,
        level = level,
        icon = icon,
        message = message,
        incidents = recentIncidents or 0
    })

    -- Auch als ox_lib Notification
    if lib and lib.notify then
        local notifyType = level == 'high' and 'error' or 'warning'
        lib.notify({
            title = icon .. ' ' .. title,
            description = message,
            type = notifyType,
            duration = 5000,
            position = 'top'
        })
    end
end)

-- ================================================
-- Zone-Hinweis (subtiler, für alle Levels)
-- ================================================

local lastZoneHint = nil
local ZONE_HINT_COOLDOWN = 300000 -- 5 Minuten

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
-- Notruf-Hinweis nach Vorfall
-- ================================================

RegisterNetEvent('city_memory:emergencyHint', function(reason)
    -- Nur beim ersten Mal ausführliche Erklärung
    if not hasSeenNotrufHint then
        hasSeenNotrufHint = true
        SetResourceKvpInt('city_memory:notruf_hint', 1)

        SendNUIMessage({
            type = 'showNotrufHint',
            firstTime = true,
            reason = reason
        })
        return
    end

    -- Kurzer Hinweis
    if lib and lib.notify then
        lib.notify({
            title = '📞 Notruf verfügbar',
            description = 'Nutze /notruf oder das City Memory Menü',
            type = 'inform',
            duration = 5000
        })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('Notruf: /notruf oder City Memory Menü')
        EndTextCommandThefeedPostTicker(false, false)
    end
end)

-- ================================================
-- Allgemeine Hinweise
-- ================================================

RegisterNetEvent('city_memory:hint', function(message, hintType)
    hintType = hintType or 'info'

    if lib and lib.notify then
        lib.notify({
            description = message,
            type = hintType == 'warning' and 'warning' or 'inform',
            duration = 4000
        })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end
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
        if lib and lib.notify then
            lib.notify({
                title = '⚠️ Einsatzhinweis',
                description = hint,
                type = riskLevel == 'high' and 'error' or 'warning',
                duration = 5000
            })
        else
            TriggerEvent('chat:addMessage', {
                color = { 255, 200, 100 },
                args = { '[Einsatzhinweis]', hint }
            })
        end
    end
end)

-- ================================================
-- Polizei: Personen-Check Ergebnis (ox_target)
-- ================================================

RegisterNetEvent('city_memory:personCheckResult', function(data)
    if not data then return end

    -- ox_lib Context Menu mit Ergebnissen
    if lib and lib.registerContext then
        local profile = data.profile or {}
        local risk = data.risk or 'unknown'

        -- Risk-Farbe
        local riskColor = '#4CAF50' -- Grün
        local riskLabel = 'Unauffällig'
        local riskIcon = '🟢'

        if risk == 'high' then
            riskColor = '#f44336'
            riskLabel = 'HOHES RISIKO'
            riskIcon = '🔴'
        elseif risk == 'medium' then
            riskColor = '#FF9800'
            riskLabel = 'Auffällig'
            riskIcon = '🟠'
        elseif risk == 'low' then
            riskColor = '#2196F3'
            riskLabel = 'Vereinzelte Einträge'
            riskIcon = '🔵'
        end

        local options = {
            {
                title = riskIcon .. ' ' .. riskLabel,
                description = ('Reputation: %.0f%%'):format((profile.reputation or 0.5) * 100),
                disabled = true
            }
        }

        -- Tendenzen anzeigen wenn vorhanden
        if profile.violence_tendency and profile.violence_tendency > 0.1 then
            options[#options + 1] = {
                title = '⚠️ Gewaltbereitschaft',
                description = ('%.0f%% Tendenz'):format(profile.violence_tendency * 100),
                disabled = true
            }
        end

        if profile.flee_tendency and profile.flee_tendency > 0.1 then
            options[#options + 1] = {
                title = '🏃 Fluchtgefahr',
                description = ('%.0f%% Tendenz'):format(profile.flee_tendency * 100),
                disabled = true
            }
        end

        if profile.cooperation and profile.cooperation > 0.6 then
            options[#options + 1] = {
                title = '✅ Kooperativ',
                description = ('%.0f%% Kooperationsrate'):format(profile.cooperation * 100),
                disabled = true
            }
        end

        -- Letzte Events
        if data.events and #data.events > 0 then
            options[#options + 1] = {
                title = '📋 Letzte Vorfälle',
                disabled = true
            }

            for i, event in ipairs(data.events) do
                if i <= 3 then
                    local eventLabels = {
                        flee_police = '🏃 Flucht vor Polizei',
                        weapon_vs_player = '🔫 Waffengebrauch (Spieler)',
                        weapon_vs_npc = '🔫 Waffengebrauch (NPC)',
                        cooperate = '🤝 Kooperation',
                        surrender = '🙌 Selbststellung',
                        shooting = '💥 Schussabgabe',
                        chase = '🚗 Verfolgungsjagd'
                    }

                    options[#options + 1] = {
                        title = eventLabels[event.event_type] or event.event_type,
                        description = event.created_at and event.created_at:sub(1, 16) or '',
                        disabled = true
                    }
                end
            end
        end

        -- Aktionen
        options[#options + 1] = {
            title = '🔍 Im MDT öffnen',
            description = 'Detaillierte Akte anzeigen',
            onSelect = function()
                TriggerEvent('city_memory:openMDT')
                -- TODO: Direkt zur Person navigieren
            end
        }

        lib.registerContext({
            id = 'city_memory_person_check',
            title = '👤 ' .. (data.name or 'Unbekannt'),
            options = options
        })

        lib.showContext('city_memory_person_check')

        -- Sound bei hohem Risiko
        if risk == 'high' then
            PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false)
        end
    end
end)

-- ================================================
-- Debug: Zone Info
-- ================================================

RegisterNetEvent('city_memory:debugZoneInfo', function(zoneId, heat, incidents)
    if not Config.Debug then return end

    TriggerEvent('chat:addMessage', {
        color = { 150, 150, 150 },
        args = {
            '[CM Debug]',
            ('Zone: %s | Heat: %.3f | Vorfälle: %d'):format(zoneId, heat, incidents)
        }
    })
end)

-- ================================================
-- Reset Onboarding (für Tests)
-- ================================================

RegisterCommand('cm_reset_onboarding', function()
    SetResourceKvpInt('city_memory:zone_warning_intro', 0)
    SetResourceKvpInt('city_memory:notruf_hint', 0)
    SetResourceKvpInt('city_memory:heatmap_intro', 0)
    hasSeenZoneWarningIntro = false
    hasSeenNotrufHint = false

    if lib and lib.notify then
        lib.notify({
            title = 'Onboarding zurückgesetzt',
            description = 'Alle Einführungs-Hinweise werden erneut angezeigt.',
            type = 'success'
        })
    end
end, false)

print('^2[City Memory] Feedback System v2.2 geladen^7')
