-- ================================================
-- City Memory System - Dispatch Client
-- Notruf & Einsatzverwaltung UI Controller
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Variablen ZUERST definieren
local isDispatchOpen = false
local isCallUIOpen = false
local currentCalls = {}
local myCalls = {}
local categories = {}
local isDispatcher = false
local currentJob = nil

-- DANN die Events
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    isDispatcher = IsDispatcherJob(currentJob)
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    isDispatcher = IsDispatcherJob(currentJob)
end)

-- ================================================
-- Job Check
-- ================================================

CreateThread(function()
    while true do
        Wait(2000)

        local playerData = ESX.GetPlayerData()
        if playerData and playerData.job then
            currentJob = playerData.job.name
            isDispatcher = IsDispatcherJob(currentJob)
        end
    end
end)

-- ================================================
-- Keybinds
-- ================================================

-- F5 = Notruf UI (für alle)
RegisterCommand('openCallUI', function()
    if isCallUIOpen or isDispatchOpen then return end
    OpenCallUI()
end, false)
RegisterKeyMapping('openCallUI', 'Notruf absetzen', 'keyboard', 'F5')

-- J = Dispatch UI (nur für Einsatzkräfte)
RegisterCommand('openDispatch', function()
    if isCallUIOpen or isDispatchOpen then return end
    if not isDispatcher then
        -- Serverseitigen Fallback prüfen (falls Client-Jobdaten noch nicht geladen sind)
        TriggerServerEvent('dispatch:canOpen')
        ShowNotification('~y~Prüfe Berechtigung', 'Bitte warten...')
        return
    end
    OpenDispatchUI()
end, false)

-- Ergebnis der serverseitigen Berechtigungsprüfung
RegisterNetEvent('dispatch:canOpenResult', function(allowed, job)
    if allowed then
        currentJob = job or currentJob
        isDispatcher = true
        if not isDispatchOpen and not isCallUIOpen then
            OpenDispatchUI()
        end
    else
        ShowNotification('~r~Keine Berechtigung', 'Du bist keine Einsatzkraft.')
    end
end)
RegisterKeyMapping('openDispatch', 'Dispatch öffnen', 'keyboard', 'J')

-- ================================================
-- Notruf UI öffnen (Zivilist)
-- ================================================

function OpenCallUI()
    isCallUIOpen = true
    SetNuiFocus(true, true)

    TriggerServerEvent('dispatch:getCategories')

    SendNUIMessage({
        type = 'openCallUI'
    })
end

-- ================================================
-- Dispatch UI öffnen (Einsatzkräfte)
-- ================================================

function OpenDispatchUI()
    isDispatchOpen = true
    SetNuiFocus(true, true)

    -- Calls laden
    TriggerServerEvent('dispatch:getCalls')
    TriggerServerEvent('dispatch:getMyCalls')
    TriggerServerEvent('dispatch:getOnlineUnits')

    SendNUIMessage({
        type = 'openDispatchUI',
        job = currentJob
    })
end

-- ================================================
-- UIs schließen
-- ================================================

function CloseAllUI()
    isDispatchOpen = false
    isCallUIOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        type = 'closeAll'
    })
end

-- ================================================
-- NUI Callbacks
-- ================================================

RegisterNUICallback('closeUI', function(data, cb)
    CloseAllUI()
    cb('ok')
end)

RegisterNUICallback('submitCall', function(data, cb)
    -- Echten Straßennamen clientseitig ermitteln und normalisieren
    local function trim(s)
        if not s then return '' end
        return (s:gsub('^%s+', ''):gsub('%s+$', ''))
    end

    local function normalizeStreet(mainName, crossName)
        mainName = trim(mainName or '')
        crossName = trim(crossName or '')
        -- Gleiche Namen nicht doppelt anzeigen
        if mainName ~= '' and crossName ~= '' and mainName:lower() == crossName:lower() then
            crossName = ''
        end
        local name
        if mainName ~= '' and crossName ~= '' then
            name = mainName .. ' / ' .. crossName
        else
            name = mainName ~= '' and mainName or ''
        end
        -- Mehrfache Leerzeichen reduzieren
        name = name:gsub('%s+', ' ')
        return trim(name)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local street = ''
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    if streetHash and streetHash ~= 0 then
        local streetName = GetStreetNameFromHashKey(streetHash) or ''
        local crossingName = (crossingHash and crossingHash ~= 0) and (GetStreetNameFromHashKey(crossingHash) or '') or ''
        street = normalizeStreet(streetName, crossingName)
    end

    TriggerServerEvent('dispatch:createCall', {
        category = data.category,
        message = data.message or '',
        anonymous = data.anonymous or false,
        street = street
    })

    CloseAllUI()
    cb('ok')
end)

RegisterNUICallback('acceptCall', function(data, cb)
    TriggerServerEvent('dispatch:acceptCall', data.callId)
    cb('ok')
end)

RegisterNUICallback('updateStatus', function(data, cb)
    TriggerServerEvent('dispatch:updateStatus', data.callId, data.status)
    cb('ok')
end)

RegisterNUICallback('closeCall', function(data, cb)
    TriggerServerEvent('dispatch:closeCall', data.callId)
    cb('ok')
end)

RegisterNUICallback('requestBackup', function(data, cb)
    TriggerServerEvent('dispatch:requestBackup', data.callId)
    ShowNotification('~g~Backup angefordert', 'Andere Einheiten wurden benachrichtigt.')
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    SetNewWaypoint(data.x, data.y)
    ShowNotification('~g~Route gesetzt', 'Navigation aktiv.')
    cb('ok')
end)

RegisterNUICallback('refreshCalls', function(data, cb)
    TriggerServerEvent('dispatch:getCalls')
    TriggerServerEvent('dispatch:getMyCalls')
    cb('ok')
end)

-- ================================================
-- Server Events
-- ================================================

RegisterNetEvent('dispatch:receiveCategories', function(cats)
    categories = cats
    SendNUIMessage({
        type = 'setCategories',
        categories = cats
    })
end)

RegisterNetEvent('dispatch:receiveCalls', function(calls)
    currentCalls = calls
    SendNUIMessage({
        type = 'setCalls',
        calls = calls
    })
end)

RegisterNetEvent('dispatch:receiveMyCalls', function(calls)
    myCalls = calls
    SendNUIMessage({
        type = 'setMyCalls',
        calls = calls
    })
end)

RegisterNetEvent('dispatch:receiveOnlineUnits', function(units)
    SendNUIMessage({
        type = 'setOnlineUnits',
        units = units
    })
end)

-- ================================================
-- Neue Notrufe / Updates
-- ================================================

RegisterNetEvent('dispatch:newCall', function(call)
    -- Sound abspielen
    PlaySound(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', false, 0, true)

    -- Notification anzeigen
    ShowCallNotification(call)

    -- UI aktualisieren wenn offen
    if isDispatchOpen then
        table.insert(currentCalls, 1, call)
        SendNUIMessage({
            type = 'newCall',
            call = call
        })
    end
end)

RegisterNetEvent('dispatch:callUpdated', function(call)
    -- In lokaler Liste aktualisieren
    for i, c in ipairs(currentCalls) do
        if c.id == call.id then
            currentCalls[i] = call
            break
        end
    end

    if isDispatchOpen then
        SendNUIMessage({
            type = 'updateCall',
            call = call
        })
    end
end)

RegisterNetEvent('dispatch:callRemoved', function(callId)
    for i, c in ipairs(currentCalls) do
        if c.id == callId then
            table.remove(currentCalls, i)
            break
        end
    end

    if isDispatchOpen then
        SendNUIMessage({
            type = 'removeCall',
            callId = callId
        })
    end
end)

RegisterNetEvent('dispatch:callAccepted', function(data)
    ShowNotification('~g~Einsatz angenommen', 'Notruf #' .. data.callId .. ' zugewiesen.')

    -- Route setzen
    local coords = data.call.location.coords
    SetNewWaypoint(coords.x, coords.y)
end)

RegisterNetEvent('dispatch:backupRequested', function(data)
    -- Alarm-Sound
    PlaySound(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false, 0, true)

    ShowNotification('~o~BACKUP ANGEFORDERT', data.requestedBy .. ' braucht Verstärkung!\n' .. data.call.location.zone, true)
end)

-- ================================================
-- Anrufer Benachrichtigungen
-- ================================================

RegisterNetEvent('dispatch:callCreated', function(data)
    ShowNotification('~g~Notruf übermittelt', 'ID: #' .. data.callId .. '\n' .. data.message)
end)

RegisterNetEvent('dispatch:unitsEnroute', function(data)
    ShowNotification('~b~Einsatzkräfte unterwegs', data.unitName .. ' (' .. data.unitJob .. ') ist auf dem Weg.')
    PlaySound(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)
end)

RegisterNetEvent('dispatch:unitsArrived', function()
    ShowNotification('~g~Einsatzkräfte eingetroffen', 'Die Einsatzkräfte sind vor Ort.')
    PlaySound(-1, 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET', false, 0, true)
end)

RegisterNetEvent('dispatch:callCompleted', function()
    ShowNotification('~g~Einsatz abgeschlossen', 'Der Notruf wurde bearbeitet.')
end)

-- ================================================
-- Notification System
-- ================================================

function ShowNotification(title, message, urgent)
    SendNUIMessage({
        type = 'showNotification',
        title = title,
        message = message,
        urgent = urgent or false
    })
end

function ShowCallNotification(call)
    local priorityColor = '#4CAF50'
    if call.priority == 'high' then priorityColor = '#f44336' end
    if call.priority == 'medium' then priorityColor = '#ff9800' end

    SendNUIMessage({
        type = 'showCallNotification',
        call = call,
        priorityColor = priorityColor
    })
end

-- ================================================
-- ESC zum Schließen
-- ================================================

CreateThread(function()
    while true do
        Wait(0)

        if isDispatchOpen or isCallUIOpen then
            DisableControlAction(0, 1, true) -- Look LR
            DisableControlAction(0, 2, true) -- Look UD
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 199, true) -- Pause

            if IsDisabledControlJustReleased(0, 322) then
                CloseAllUI()
            end
        end
    end
end)

-- ================================================
-- Auto-Refresh wenn Dispatch offen
-- ================================================

CreateThread(function()
    while true do
        Wait(10000) -- Alle 10 Sekunden

        if isDispatchOpen then
            TriggerServerEvent('dispatch:getCalls')
            TriggerServerEvent('dispatch:getMyCalls')
            TriggerServerEvent('dispatch:getOnlineUnits')
        end
    end
end)
