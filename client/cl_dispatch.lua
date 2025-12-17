-- ================================================
-- City Memory System - Dispatch Client
-- Notruf & Einsatzverwaltung UI Controller
-- HINWEIS: Keybinds wurden nach cl_menu.lua verschoben
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Variablen
local isDispatchOpen = false
local isCallUIOpen = false
local currentCalls = {}
local myCalls = {}
local categories = {}
local isDispatcher = false
local currentJob = nil

-- Job Status
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    isDispatcher = IsDispatcherJob(currentJob)
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    isDispatcher = IsDispatcherJob(currentJob)
end)

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
-- UI Funktionen (werden von cl_menu.lua aufgerufen)
-- ================================================

function OpenCallUI()
    if isCallUIOpen or isDispatchOpen then return end
    isCallUIOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('dispatch:getCategories')
    SendNUIMessage({ type = 'openCallUI' })
end

function OpenDispatchUI()
    if isCallUIOpen or isDispatchOpen then return end
    if not isDispatcher then return end
    
    isDispatchOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('dispatch:getCalls')
    TriggerServerEvent('dispatch:getMyCalls')
    TriggerServerEvent('dispatch:getOnlineUnits')
    SendNUIMessage({ type = 'openDispatchUI', job = currentJob })
end

function CloseAllUI()
    isDispatchOpen = false
    isCallUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeAll' })
end

-- Exports für cl_menu.lua
exports('OpenCallUI', OpenCallUI)
exports('OpenDispatchUI', OpenDispatchUI)
exports('CloseAllUI', CloseAllUI)
exports('IsDispatchOpen', function() return isDispatchOpen end)
exports('IsCallUIOpen', function() return isCallUIOpen end)

-- ================================================
-- Event Handler (von cl_menu.lua)
-- ================================================

RegisterNetEvent('city_memory:openCallUI', function()
    OpenCallUI()
end)

RegisterNetEvent('city_memory:openDispatch', function()
    OpenDispatchUI()
end)

-- ================================================
-- NUI Callbacks
-- ================================================

RegisterNUICallback('closeUI', function(data, cb)
    CloseAllUI()
    cb('ok')
end)

RegisterNUICallback('submitCall', function(data, cb)
    local function trim(s)
        if not s then return '' end
        return (s:gsub('^%s+', ''):gsub('%s+$', ''))
    end

    local function normalizeStreet(mainName, crossName)
        mainName = trim(mainName or '')
        crossName = trim(crossName or '')
        if mainName ~= '' and crossName ~= '' and mainName:lower() == crossName:lower() then
            crossName = ''
        end
        local name
        if mainName ~= '' and crossName ~= '' then
            name = mainName .. ' / ' .. crossName
        else
            name = mainName ~= '' and mainName or ''
        end
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
    SendNUIMessage({ type = 'setCategories', categories = cats })
end)

RegisterNetEvent('dispatch:receiveCalls', function(calls)
    currentCalls = calls
    SendNUIMessage({ type = 'setCalls', calls = calls })
end)

RegisterNetEvent('dispatch:receiveMyCalls', function(calls)
    myCalls = calls
    SendNUIMessage({ type = 'setMyCalls', calls = calls })
end)

RegisterNetEvent('dispatch:receiveOnlineUnits', function(units)
    SendNUIMessage({ type = 'setOnlineUnits', units = units })
end)

RegisterNetEvent('dispatch:newCall', function(call)
    PlaySound(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', false, 0, true)
    ShowCallNotification(call)
    
    if isDispatchOpen then
        table.insert(currentCalls, 1, call)
        SendNUIMessage({ type = 'newCall', call = call })
    end
end)

RegisterNetEvent('dispatch:callUpdated', function(call)
    for i, c in ipairs(currentCalls) do
        if c.id == call.id then
            currentCalls[i] = call
            break
        end
    end
    
    if isDispatchOpen then
        SendNUIMessage({ type = 'updateCall', call = call })
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
        SendNUIMessage({ type = 'removeCall', callId = callId })
    end
end)

RegisterNetEvent('dispatch:callAccepted', function(data)
    ShowNotification('~g~Einsatz angenommen', 'Notruf #' .. data.callId .. ' zugewiesen.')
    local coords = data.call.location.coords
    SetNewWaypoint(coords.x, coords.y)
end)

RegisterNetEvent('dispatch:backupRequested', function(data)
    PlaySound(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false, 0, true)
    ShowNotification('~o~BACKUP ANGEFORDERT', data.requestedBy .. ' braucht Verstärkung!\n' .. data.call.location.zone, true)
end)

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
    -- Versuche ox_lib, sonst NUI fallback
    if lib and lib.notify then
        lib.notify({
            title = title:gsub('~%w~', ''),
            description = message,
            type = urgent and 'error' or 'inform'
        })
    else
        SendNUIMessage({
            type = 'showNotification',
            title = title,
            message = message,
            urgent = urgent or false
        })
    end
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
-- ESC Handling
-- ================================================

CreateThread(function()
    while true do
        Wait(0)
        
        if isDispatchOpen or isCallUIOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 199, true)

            if IsDisabledControlJustReleased(0, 322) then
                CloseAllUI()
            end
        end
    end
end)

-- ================================================
-- Auto-Refresh
-- ================================================

CreateThread(function()
    while true do
        Wait(10000)
        if isDispatchOpen then
            TriggerServerEvent('dispatch:getCalls')
            TriggerServerEvent('dispatch:getMyCalls')
            TriggerServerEvent('dispatch:getOnlineUnits')
        end
    end
end)
