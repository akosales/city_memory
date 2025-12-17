-- ================================================
-- City Memory System - MDT & Admin Client
-- Mobile Data Terminal & Admin Dashboard
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

local isMDTOpen = false
local isAdminOpen = false
local currentJob = nil
local currentGrade = 0
local isPolice = false
local isAdmin = false

-- ================================================
-- Job Status Check
-- ================================================

CreateThread(function()
    while true do
        Wait(2000)

        local playerData = ESX.GetPlayerData()
        if playerData and playerData.job then
            currentJob = playerData.job.name
            currentGrade = playerData.job.grade or 0
            isPolice = IsPoliceJob(currentJob)
            isAdmin = playerData.group == 'admin' or playerData.group == 'superadmin'
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    currentGrade = xPlayer.job.grade or 0
    isPolice = IsPoliceJob(currentJob)
    isAdmin = xPlayer.group == 'admin' or xPlayer.group == 'superadmin'
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    currentGrade = job.grade or 0
    isPolice = IsPoliceJob(currentJob)
end)

-- ================================================
-- MDT Keybind (F6)
-- ================================================

RegisterCommand('openMDT', function()
    if not isPolice then
        ShowNotification('~r~Keine Berechtigung', 'Du bist kein Polizist.')
        return
    end
    if isMDTOpen or isAdminOpen then return end

    OpenMDT()
end, false)
RegisterKeyMapping('openMDT', 'MDT öffnen (Polizei)', 'keyboard', Config.Keys.openMDT or 'F6')

-- ================================================
-- Admin Dashboard Keybind (F7)
-- ================================================

RegisterCommand('openAdminDashboard', function()
    if not isAdmin then
        ShowNotification('~r~Keine Berechtigung', 'Du bist kein Admin.')
        return
    end
    if isMDTOpen or isAdminOpen then return end

    OpenAdminDashboard()
end, false)
RegisterKeyMapping('openAdminDashboard', 'Admin Dashboard öffnen', 'keyboard', Config.Keys.openAdmin or 'F7')

-- ================================================
-- MDT öffnen
-- ================================================

function OpenMDT()
    isMDTOpen = true
    SetNuiFocus(true, true)

    -- Initiale Daten laden
    TriggerServerEvent('mdt:getWantedList')
    TriggerServerEvent('mdt:getStatistics')

    SendNUIMessage({
        type = 'openMDT',
        job = currentJob,
        grade = currentGrade,
    })
end

-- ================================================
-- Admin Dashboard öffnen
-- ================================================

function OpenAdminDashboard()
    isAdminOpen = true
    SetNuiFocus(true, true)

    TriggerServerEvent('admin:getFullStatistics')
    TriggerServerEvent('admin:getLogs', 50)
    TriggerServerEvent('admin:getAllCalls', 100)

    SendNUIMessage({
        type = 'openAdmin'
    })
end

-- ================================================
-- UIs schließen
-- ================================================

function CloseMDT()
    isMDTOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMDT' })
end

function CloseAdmin()
    isAdminOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeAdmin' })
end

-- ================================================
-- NUI Callbacks - MDT
-- ================================================

RegisterNUICallback('closeMDT', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('closeAdmin', function(data, cb)
    CloseAdmin()
    cb('ok')
end)

RegisterNUICallback('mdt:searchPerson', function(data, cb)
    TriggerServerEvent('mdt:searchPerson', data.query)
    cb('ok')
end)

RegisterNUICallback('mdt:searchVehicle', function(data, cb)
    TriggerServerEvent('mdt:searchVehicle', data.plate)
    cb('ok')
end)

RegisterNUICallback('mdt:getPersonDetails', function(data, cb)
    TriggerServerEvent('mdt:getPersonDetails', data.identifier)
    cb('ok')
end)

RegisterNUICallback('mdt:addNote', function(data, cb)
    TriggerServerEvent('mdt:addPersonNote', data.identifier, data.note)
    cb('ok')
end)

RegisterNUICallback('mdt:getPersonNotes', function(data, cb)
    TriggerServerEvent('mdt:getPersonNotes', data.identifier)
    cb('ok')
end)

RegisterNUICallback('mdt:createWanted', function(data, cb)
    TriggerServerEvent('mdt:createWanted', data)
    cb('ok')
end)

RegisterNUICallback('mdt:removeWanted', function(data, cb)
    TriggerServerEvent('mdt:removeWanted', data.id)
    cb('ok')
end)

RegisterNUICallback('mdt:refreshStats', function(data, cb)
    TriggerServerEvent('mdt:getStatistics')
    TriggerServerEvent('mdt:getWantedList')
    cb('ok')
end)

-- ================================================
-- NUI Callbacks - Admin
-- ================================================

RegisterNUICallback('admin:refreshStats', function(data, cb)
    TriggerServerEvent('admin:getFullStatistics')
    TriggerServerEvent('admin:getAllCalls', 100)
    cb('ok')
end)

RegisterNUICallback('admin:refreshLogs', function(data, cb)
    TriggerServerEvent('admin:getLogs', data.limit or 50)
    cb('ok')
end)

RegisterNUICallback('admin:resetData', function(data, cb)
    TriggerServerEvent('admin:resetData', data.dataType)
    cb('ok')
end)

-- ================================================
-- Server Events - MDT
-- ================================================

RegisterNetEvent('mdt:personSearchResults', function(results)
    SendNUIMessage({
        type = 'mdt:personResults',
        results = results
    })
end)

RegisterNetEvent('mdt:personDetails', function(data)
    SendNUIMessage({
        type = 'mdt:personDetails',
        data = data
    })
end)

RegisterNetEvent('mdt:vehicleSearchResults', function(data)
    SendNUIMessage({
        type = 'mdt:vehicleResults',
        data = data
    })
end)

RegisterNetEvent('mdt:personNotes', function(notes)
    SendNUIMessage({
        type = 'mdt:personNotes',
        notes = notes
    })
end)

RegisterNetEvent('mdt:noteAdded', function(success)
    if success then
        ShowNotification('~g~Notiz hinzugefügt', 'Die Notiz wurde gespeichert.')
    end
end)

RegisterNetEvent('mdt:wantedList', function(wanted)
    SendNUIMessage({
        type = 'mdt:wantedList',
        wanted = wanted
    })
end)

RegisterNetEvent('mdt:newWanted', function(data)
    ShowNotification('~o~NEUE FAHNDUNG', data.type .. ': ' .. data.target .. '\n' .. data.reason, true)
    PlayAlertSound()
end)

RegisterNetEvent('mdt:wantedRemoved', function(id)
    SendNUIMessage({
        type = 'mdt:wantedRemoved',
        id = id
    })
end)

RegisterNetEvent('mdt:statistics', function(stats)
    SendNUIMessage({
        type = 'mdt:statistics',
        stats = stats
    })
end)

RegisterNetEvent('mdt:error', function(message)
    ShowNotification('~r~Fehler', message)
end)

-- ================================================
-- Server Events - Admin
-- ================================================

RegisterNetEvent('admin:fullStatistics', function(stats)
    SendNUIMessage({
        type = 'admin:statistics',
        stats = stats
    })
end)

RegisterNetEvent('admin:logs', function(logs)
    SendNUIMessage({
        type = 'admin:logs',
        logs = logs
    })
end)

RegisterNetEvent('admin:allCalls', function(data)
    SendNUIMessage({
        type = 'admin:allCalls',
        calls = data
    })
end)

RegisterNetEvent('admin:resetSuccess', function(dataType)
    ShowNotification('~g~Daten zurückgesetzt', dataType .. ' wurde erfolgreich zurückgesetzt.')
end)

RegisterNetEvent('admin:error', function(message)
    ShowNotification('~r~Admin Fehler', message)
end)

-- ================================================
-- Sound Helper
-- ================================================

function PlayAlertSound()
    if Config.Sounds.enabled then
        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', false)
    end
end

-- ================================================
-- Notification Helper (reuse from dispatch)
-- ================================================

function ShowNotification(title, message, urgent)
    SendNUIMessage({
        type = 'showNotification',
        title = title,
        message = message,
        urgent = urgent or false
    })
end

-- ================================================
-- ESC Handling
-- ================================================

CreateThread(function()
    while true do
        Wait(0)

        if isMDTOpen or isAdminOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 199, true)

            if IsDisabledControlJustReleased(0, 322) then
                if isMDTOpen then CloseMDT() end
                if isAdminOpen then CloseAdmin() end
            end
        end
    end
end)
