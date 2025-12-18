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
local isPolice = false
local isEMS = false
local currentJob = nil

-- Persistente Notruf-Blips bis Abschluss
local callBlips = {} -- [callId] = { blip = handle, last = ms }

-- ================================================
-- Persistente Notruf-Ortsmarkierungen (Blips)
-- ================================================

local function CallBlipsEnabled()
    return Config and Config.Dispatch and Config.Dispatch.callBlips and Config.Dispatch.callBlips.enabled
end

local function RoleMaySeeCall(category)
    if not CallBlipsEnabled() then return false end
    if isDispatcher and (Config.Dispatch.callBlips.showForDispatchers ~= false) then return true end
    local cat = categories and categories[category]
    if isPolice and (Config.Dispatch.callBlips.showForPolice ~= false) then
        if not cat or cat.police then return true end
    end
    if isEMS and (Config.Dispatch.callBlips.showForEMS ~= false) then
        if not cat or cat.ems then return true end
    end
    return false
end

local function PriorityColor(priority)
    if not (Config and Config.Dispatch and Config.Dispatch.callBlips) then return 2 end -- green
    if (Config.Dispatch.callBlips.colorByPriority == false) then return 2 end
    if priority == 'high' then return 1 end   -- rot
    if priority == 'medium' then return 17 end -- orange
    return 2 -- grün
end

local function CreateOrUpdateCallBlip(call)
    if not call or not call.location or not call.location.coords then return end
    if not RoleMaySeeCall(call.category) then return end

    local entry = callBlips[call.id]
    local coords = call.location.coords
    local radius = (Config.Dispatch.callBlips.radius or 60.0)
    local alpha = math.floor(math.max(0, math.min(255, Config.Dispatch.callBlips.alpha or 120)))
    local color = PriorityColor(call.priority)

    if entry and entry.blip and DoesBlipExist(entry.blip) then
        -- Wenn Position sich signifikant geändert hat, Blip neu erstellen (Radius-Blips schwer zu verschieben)
        local current = GetBlipCoords(entry.blip)
        local dx, dy = current.x - coords.x, current.y - coords.y
        if (dx*dx + dy*dy) > 4.0 then -- > ~2m
            RemoveBlip(entry.blip)
            entry.blip = nil
        else
            -- Stil aktualisieren
            SetBlipColour(entry.blip, color)
            SetBlipAlpha(entry.blip, alpha)
            entry.last = GetGameTimer()
            return
        end
    end

    -- Neu anlegen
    local blip = AddBlipForRadius(coords.x + 0.0, coords.y + 0.0, (coords.z or 0.0) + 0.0, radius)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, alpha)
    if Config.Dispatch.callBlips.flashOnHigh and call.priority == 'high' then
        SetBlipFlashes(blip, true)
    end

    callBlips[call.id] = { blip = blip, last = GetGameTimer() }
end

local function RemoveCallBlip(callId)
    local entry = callBlips[callId]
    if entry then
        if entry.blip and DoesBlipExist(entry.blip) then RemoveBlip(entry.blip) end
        callBlips[callId] = nil
    end
end

local function ClearCallBlips()
    for id, entry in pairs(callBlips) do
        if entry and entry.blip and DoesBlipExist(entry.blip) then RemoveBlip(entry.blip) end
        callBlips[id] = nil
    end
end

-- Job Status
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    isDispatcher = IsDispatcherJob(currentJob)
    isPolice = IsPoliceJob(currentJob)
    isEMS = IsEMSJob(currentJob)
    -- Initiale Blips abrufen
    if CallBlipsEnabled() then
        ClearCallBlips()
        SetTimeout(1500, function()
            TriggerServerEvent('dispatch:getActiveCallsForUnits')
        end)
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    local oldDisp, oldPol, oldEMS = isDispatcher, isPolice, isEMS
    isDispatcher = IsDispatcherJob(currentJob)
    isPolice = IsPoliceJob(currentJob)
    isEMS = IsEMSJob(currentJob)
    if (oldDisp ~= isDispatcher) or (oldPol ~= isPolice) or (oldEMS ~= isEMS) then
        if CallBlipsEnabled() then
            ClearCallBlips()
            TriggerServerEvent('dispatch:getActiveCallsForUnits')
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        local playerData = ESX.GetPlayerData()
        if playerData and playerData.job then
            currentJob = playerData.job.name
            local oldDisp, oldPol, oldEMS = isDispatcher, isPolice, isEMS
            isDispatcher = IsDispatcherJob(currentJob)
            isPolice = IsPoliceJob(currentJob)
            isEMS = IsEMSJob(currentJob)
            if (oldDisp ~= isDispatcher) or (oldPol ~= isPolice) or (oldEMS ~= isEMS) then
                if CallBlipsEnabled() then
                    ClearCallBlips()
                    TriggerServerEvent('dispatch:getActiveCallsForUnits')
                end
            end
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

-- Einheiten erhalten aktive Calls für Blip-Anzeige
RegisterNetEvent('dispatch:receiveActiveCallsForUnits', function(calls)
    if not CallBlipsEnabled() then return end
    -- Kategorien sind evtl. noch nicht geladen; trotzdem Blips nach Rollenlogik setzen
    local created = 0
    for _, call in ipairs(calls or {}) do
        CreateOrUpdateCallBlip(call)
        created = created + 1
        if Config.Dispatch.callBlips.maxVisible and created >= Config.Dispatch.callBlips.maxVisible then
            break
        end
    end
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

    -- Persistenter Blip
    CreateOrUpdateCallBlip(call)

    if isDispatchOpen and IsDispatcherJob(currentJob) then
        table.insert(currentCalls, 1, call)
        SendNUIMessage({ type = 'newCall', call = call })
    end
end)

RegisterNetEvent('dispatch:callUpdated', function(call)
    -- Blip aktualisieren
    CreateOrUpdateCallBlip(call)

    for i, c in ipairs(currentCalls) do
        if c.id == call.id then
            currentCalls[i] = call
            break
        end
    end

    if isDispatchOpen and IsDispatcherJob(currentJob) then
        SendNUIMessage({ type = 'updateCall', call = call })
    end
end)

RegisterNetEvent('dispatch:callRemoved', function(callId)
    -- Blip entfernen
    RemoveCallBlip(callId)

    for i, c in ipairs(currentCalls) do
        if c.id == callId then
            table.remove(currentCalls, i)
            break
        end
    end

    if isDispatchOpen and IsDispatcherJob(currentJob) then
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

-- Cleanup bei Resource-Stop
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        ClearCallBlips()
    end
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
