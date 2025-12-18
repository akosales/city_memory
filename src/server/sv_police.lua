-- ================================================
-- City Memory System - Polizei Integration
-- Commands und Funktionen für Polizeiarbeit
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================
-- Helper: Ist Spieler Polizei?
-- ================================================

local function IsPolice(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    local job = xPlayer.job.name
    return job == 'police' or job == 'sheriff' or job == 'fib' or job == 'lspd' or job == 'bcso'
end

local function GetPoliceGrade(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    return xPlayer.job.grade or 0
end

-- ================================================
-- Command: /risiko [id]
-- Zeigt Risiko-Einschätzung einer Person
-- ================================================

RegisterCommand('risiko', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args = { '[Dispatch]', 'Verwendung: /risiko [Spieler-ID]' }
        })
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[Dispatch]', 'Person nicht gefunden.' }
        })
        return
    end
    
    local identifier = xTarget.identifier
    local profile = exports['city_memory']:GetPlayerProfile(identifier)
    local risk = exports['city_memory']:GetRiskLevel(identifier)
    
    -- Nachricht aufbauen
    local targetName = xTarget.getName()
    local messages = {}
    
    table.insert(messages, '^3═══════════════════════════════')
    table.insert(messages, '^3PERSONENABFRAGE^7')
    table.insert(messages, '^3═══════════════════════════════')
    table.insert(messages, ('Name: ^5%s^7'):format(targetName))
    
    -- Risiko-Einschätzung
    if risk == 'high' then
        table.insert(messages, 'Einschätzung: ^1HOHES RISIKO^7')
        table.insert(messages, '^1⚠ Erhöhte Vorsicht geboten!^7')
    elseif risk == 'medium' then
        table.insert(messages, 'Einschätzung: ^3MITTLERES RISIKO^7')
        table.insert(messages, '^3Person ist polizeilich bekannt.^7')
    else
        table.insert(messages, 'Einschätzung: ^2GERINGES RISIKO^7')
        table.insert(messages, '^2Keine besonderen Hinweise.^7')
    end
    
    -- Detaillierte Infos für höhere Dienstgrade
    if profile and GetPoliceGrade(source) >= 2 then
        table.insert(messages, '^3───────────────────────────────')
        table.insert(messages, '^3DETAILS (Dienstgrad 2+):^7')
        
        if profile.violence_tendency and profile.violence_tendency > 0.3 then
            table.insert(messages, '^1• Gewaltbereitschaft erhöht^7')
        end
        if profile.flee_tendency and profile.flee_tendency > 0.3 then
            table.insert(messages, '^3• Fluchtgefahr erhöht^7')
        end
        if profile.cooperation and profile.cooperation > 0.6 then
            table.insert(messages, '^2• Kooperationsbereit^7')
        end
    end
    
    table.insert(messages, '^3═══════════════════════════════')
    
    -- Alle Nachrichten senden
    for _, msg in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, {
            color = { 100, 150, 255 },
            args = { '', msg }
        })
    end
    
    -- Sound abspielen
    TriggerClientEvent('city_memory:playSound', source, 'query')
    
    -- Loggen
    Log('POLICE', ('Risiko-Abfrage: %s fragte %s ab (Risk: %s)'):format(
        ESX.GetPlayerFromId(source).getName(), targetName, risk
    ))
    
end, false)

-- ================================================
-- Command: /kennzeichen [plate]
-- Zeigt Fahrzeug-Historie
-- ================================================

RegisterCommand('kennzeichen', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local plate = args[1]
    if not plate then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args = { '[Dispatch]', 'Verwendung: /kennzeichen [Kennzeichen]' }
        })
        return
    end
    
    -- Normalisieren
    plate = string.upper(string.gsub(plate, '%s+', ''))
    
    local history = exports['city_memory']:GetVehicleHistory(plate)
    local risk = exports['city_memory']:GetVehicleRiskLevel(plate)
    local flagged = exports['city_memory']:IsVehicleFlagged(plate)
    
    local messages = {}
    
    table.insert(messages, '^3═══════════════════════════════')
    table.insert(messages, '^3KENNZEICHENABFRAGE^7')
    table.insert(messages, '^3═══════════════════════════════')
    table.insert(messages, ('Kennzeichen: ^5%s^7'):format(plate))
    
    if not history then
        table.insert(messages, 'Status: ^2Keine Einträge^7')
        table.insert(messages, '^2Fahrzeug ist nicht bekannt.^7')
    else
        -- Flagged Status
        if flagged then
            table.insert(messages, 'Status: ^1MARKIERT^7')
            table.insert(messages, '^1⚠ Fahrzeug zur Fahndung ausgeschrieben!^7')
        elseif risk == 'high' then
            table.insert(messages, 'Status: ^1HOHES RISIKO^7')
        elseif risk == 'medium' then
            table.insert(messages, 'Status: ^3AUFFÄLLIG^7')
        elseif risk == 'low' then
            table.insert(messages, 'Status: ^3VEREINZELTE EINTRÄGE^7')
        else
            table.insert(messages, 'Status: ^2UNAUFFÄLLIG^7')
        end
        
        -- Details
        table.insert(messages, '^3───────────────────────────────')
        
        if history.chaseCount and history.chaseCount > 0 then
            table.insert(messages, ('Verfolgungsjagden: ^1%d^7'):format(history.chaseCount))
        end
        
        if history.crimeAssociation and history.crimeAssociation > 0.2 then
            local crimeLevel = 'niedrig'
            if history.crimeAssociation > 0.6 then
                crimeLevel = '^1hoch^7'
            elseif history.crimeAssociation > 0.4 then
                crimeLevel = '^3mittel^7'
            end
            table.insert(messages, ('Kriminalitätsbezug: %s'):format(crimeLevel))
        end
        
        if history.lastIncident then
            table.insert(messages, ('Letzter Vorfall: %s'):format(history.lastIncident))
        end
    end
    
    table.insert(messages, '^3═══════════════════════════════')
    
    for _, msg in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, {
            color = { 100, 150, 255 },
            args = { '', msg }
        })
    end
    
    TriggerClientEvent('city_memory:playSound', source, 'query')
    
    Log('POLICE', ('Kennzeichen-Abfrage: %s fragte %s ab'):format(
        ESX.GetPlayerFromId(source).getName(), plate
    ))
    
end, false)

-- ================================================
-- Command: /gebiet
-- Zeigt Heat-Status des aktuellen Gebiets
-- ================================================

RegisterCommand('gebiet', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    local messages = {}
    
    table.insert(messages, '^3═══════════════════════════════')
    table.insert(messages, '^3GEBIETSANALYSE^7')
    table.insert(messages, '^3═══════════════════════════════')
    
    if zoneId then
        local zone = Config.Zones[zoneId]
        local heat = exports['city_memory']:GetZoneHeat(zoneId)
        
        table.insert(messages, ('Gebiet: ^5%s^7'):format(zone.label))
        
        -- Heat-Anzeige
        local heatBar = ''
        local heatBlocks = math.floor(heat * 10)
        for i = 1, 10 do
            if i <= heatBlocks then
                if heat > 0.7 then
                    heatBar = heatBar .. '^1█^7'
                elseif heat > 0.4 then
                    heatBar = heatBar .. '^3█^7'
                else
                    heatBar = heatBar .. '^2█^7'
                end
            else
                heatBar = heatBar .. '░'
            end
        end
        
        table.insert(messages, ('Aktivität: [%s] %.0f%%'):format(heatBar, heat * 100))
        
        if heat >= 0.7 then
            table.insert(messages, '^1⚠ HOHE AKTIVITÄT - Verstärkung empfohlen!^7')
        elseif heat >= 0.4 then
            table.insert(messages, '^3⚠ Erhöhte Aktivität - Wachsamkeit geboten^7')
        else
            table.insert(messages, '^2Normale Aktivität^7')
        end
    else
        table.insert(messages, '^7Gebiet: ^5Außerhalb definierter Zonen^7')
        table.insert(messages, '^7Keine Daten verfügbar.^7')
    end
    
    table.insert(messages, '^3═══════════════════════════════')
    
    for _, msg in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, {
            color = { 100, 150, 255 },
            args = { '', msg }
        })
    end
    
end, false)

-- ================================================
-- Command: /hotspots
-- Zeigt alle aktiven Hotspots
-- ================================================

RegisterCommand('hotspots', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local hotZones = exports['city_memory']:GetHotZones(0.3)
    
    local messages = {}
    
    table.insert(messages, '^3═══════════════════════════════')
    table.insert(messages, '^3AKTIVE HOTSPOTS^7')
    table.insert(messages, '^3═══════════════════════════════')
    
    local count = 0
    for zoneId, data in pairs(hotZones) do
        count = count + 1
        local heatPercent = math.floor(data.heat * 100)
        local color = '^2'
        if data.heat >= 0.7 then
            color = '^1'
        elseif data.heat >= 0.4 then
            color = '^3'
        end
        
        table.insert(messages, ('%s• %s: %d%%^7'):format(color, data.label, heatPercent))
    end
    
    if count == 0 then
        table.insert(messages, '^2Keine aktiven Hotspots.^7')
        table.insert(messages, '^2Die Stadt ist ruhig.^7')
    else
        table.insert(messages, '^3───────────────────────────────')
        table.insert(messages, ('Gesamt: %d aktive Hotspots'):format(count))
    end
    
    table.insert(messages, '^3═══════════════════════════════')
    
    for _, msg in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, {
            color = { 100, 150, 255 },
            args = { '', msg }
        })
    end
    
end, false)

-- ================================================
-- Command: /kooperation [id]
-- Meldet kooperatives Verhalten einer Person
-- ================================================

RegisterCommand('kooperation', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args = { '[Dispatch]', 'Verwendung: /kooperation [Spieler-ID]' }
        })
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[Dispatch]', 'Person nicht gefunden.' }
        })
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Event registrieren
    exports['city_memory']:RegisterPlayerEvent(
        xTarget.identifier, 
        'cooperate', 
        nil, 
        { reportedBy = xPlayer.identifier, reportedByName = xPlayer.getName() }
    )
    
    TriggerClientEvent('chat:addMessage', source, {
        color = { 0, 255, 0 },
        args = { '[Dispatch]', ('Kooperation von %s wurde vermerkt.'):format(xTarget.getName()) }
    })
    
    Log('POLICE', ('%s meldete Kooperation von %s'):format(xPlayer.getName(), xTarget.getName()))
    
end, false)

-- ================================================
-- Command: /selbststellung [id]
-- Meldet Selbststellung einer Person
-- ================================================

RegisterCommand('selbststellung', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args = { '[Dispatch]', 'Verwendung: /selbststellung [Spieler-ID]' }
        })
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[Dispatch]', 'Person nicht gefunden.' }
        })
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    exports['city_memory']:RegisterPlayerEvent(
        xTarget.identifier, 
        'surrender', 
        nil, 
        { reportedBy = xPlayer.identifier }
    )
    
    TriggerClientEvent('chat:addMessage', source, {
        color = { 0, 255, 0 },
        args = { '[Dispatch]', ('Selbststellung von %s wurde vermerkt.'):format(xTarget.getName()) }
    })
    
    Log('POLICE', ('%s meldete Selbststellung von %s'):format(xPlayer.getName(), xTarget.getName()))
    
end, false)

-- ================================================
-- Command: /markieren [plate]
-- Markiert ein Fahrzeug zur Fahndung
-- ================================================

RegisterCommand('markieren', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    -- Mindestens Dienstgrad 2
    if GetPoliceGrade(source) < 2 then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Mindestens Dienstgrad 2 erforderlich.' }
        })
        return
    end
    
    local plate = args[1]
    if not plate then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args = { '[Dispatch]', 'Verwendung: /markieren [Kennzeichen]' }
        })
        return
    end
    
    plate = string.upper(string.gsub(plate, '%s+', ''))
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Fahrzeug-Event registrieren mit hoher Severity
    exports['city_memory']:RegisterVehicleEvent(plate, 'crime_scene', nil, nil)
    exports['city_memory']:RegisterVehicleEvent(plate, 'chase', nil, nil)
    
    TriggerClientEvent('chat:addMessage', source, {
        color = { 0, 255, 0 },
        args = { '[Dispatch]', ('Fahrzeug %s wurde zur Fahndung ausgeschrieben.'):format(plate) }
    })
    
    -- Alle Polizisten benachrichtigen
    local players = ESX.GetExtendedPlayers('job', 'police')
    for _, cop in pairs(players) do
        if cop.source ~= source then
            TriggerClientEvent('chat:addMessage', cop.source, {
                color = { 255, 100, 100 },
                args = { '[FAHNDUNG]', ('Fahrzeug %s zur Fahndung ausgeschrieben von %s'):format(plate, xPlayer.getName()) }
            })
            TriggerClientEvent('city_memory:playSound', cop.source, 'alert')
        end
    end
    
    Log('POLICE', ('%s schrieb %s zur Fahndung aus'):format(xPlayer.getName(), plate))
    
end, false)

-- ================================================
-- Command: /einsatz [zone]
-- Meldet Polizeieinsatz in einer Zone
-- ================================================

RegisterCommand('einsatz', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    
    if zoneId then
        exports['city_memory']:RegisterZoneEvent(zoneId, 'police_dispatch', nil, nil)
        
        local zone = Config.Zones[zoneId]
        TriggerClientEvent('chat:addMessage', source, {
            color = { 0, 255, 0 },
            args = { '[Dispatch]', ('Einsatz in %s wurde registriert.'):format(zone.label) }
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 200, 0 },
            args = { '[Dispatch]', 'Du befindest dich außerhalb definierter Zonen.' }
        })
    end
    
end, false)

-- ================================================
-- Command: /hilfe-polizei
-- Zeigt alle verfügbaren Polizei-Commands
-- ================================================

RegisterCommand('hilfe-polizei', function(source, args)
    if not IsPolice(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            args = { '[System]', 'Keine Berechtigung.' }
        })
        return
    end
    
    local messages = {
        '^3═══════════════════════════════',
        '^3POLIZEI-BEFEHLE (City Memory)^7',
        '^3═══════════════════════════════',
        '^5/risiko [id]^7 - Risiko-Einschätzung Person',
        '^5/kennzeichen [plate]^7 - Fahrzeug-Historie',
        '^5/gebiet^7 - Aktivität im aktuellen Gebiet',
        '^5/hotspots^7 - Alle aktiven Hotspots',
        '^5/kooperation [id]^7 - Kooperation vermerken',
        '^5/selbststellung [id]^7 - Selbststellung vermerken',
        '^5/markieren [plate]^7 - Fahrzeug zur Fahndung (Grad 2+)',
        '^5/einsatz^7 - Einsatz im Gebiet melden',
        '^3═══════════════════════════════',
    }
    
    for _, msg in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', source, {
            color = { 100, 150, 255 },
            args = { '', msg }
        })
    end
    
end, false)

-- ================================================
-- Automatische Benachrichtigung bei High-Risk
-- Wenn Polizist in Nähe eines High-Risk Spielers
-- ================================================

CreateThread(function()
    while true do
        Wait(30000) -- Alle 30 Sekunden prüfen
        
        local cops = ESX.GetExtendedPlayers('job', 'police')
        local allPlayers = ESX.GetExtendedPlayers()
        
        for _, cop in pairs(cops) do
            local copPed = GetPlayerPed(cop.source)
            if copPed and DoesEntityExist(copPed) then
                local copCoords = GetEntityCoords(copPed)
                
                for _, player in pairs(allPlayers) do
                    if player.job.name ~= 'police' then
                        local playerPed = GetPlayerPed(player.source)
                        if playerPed and DoesEntityExist(playerPed) then
                            local playerCoords = GetEntityCoords(playerPed)
                            local distance = #(copCoords - playerCoords)
                            
                            -- Wenn innerhalb 20m
                            if distance < 20.0 then
                                local risk = exports['city_memory']:GetRiskLevel(player.identifier)
                                
                                if risk == 'high' then
                                    TriggerClientEvent('city_memory:playerRiskHint', cop.source, player.source, risk)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

Log('POLICE', 'sv_police.lua geladen - Polizei-Commands aktiv')
