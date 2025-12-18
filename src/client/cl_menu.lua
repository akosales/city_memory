-- ================================================
-- City Memory System - Radial Menu (ox_lib)
-- Zentrales Menü für alle City Memory Funktionen
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Status-Variablen
local currentJob = nil
local currentGrade = 0
local isPolice = false
local isEMS = false
local isDispatcher = false
local isAdmin = false
local heatmapActive = false

-- ================================================
-- Job Status Tracking
-- ================================================

local function UpdateJobStatus()
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
        currentJob = playerData.job.name
        currentGrade = playerData.job.grade or 0
        isPolice = IsPoliceJob(currentJob)
        isEMS = IsEMSJob(currentJob)
        isDispatcher = IsDispatcherJob(currentJob)

        -- Admin Check - mehrere Methoden
        local group = playerData.group or ''
        isAdmin = (group == 'admin' or group == 'superadmin' or group == 'god')

        -- Debug
        if Config.Debug then
            print(('[City Memory] Job: %s | Dispatcher: %s | Police: %s | Admin: %s (group: %s)'):format(
                currentJob or 'nil',
                tostring(isDispatcher),
                tostring(isPolice),
                tostring(isAdmin),
                group or 'nil'
            ))
        end
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        UpdateJobStatus()
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    currentGrade = xPlayer.job.grade or 0
    isPolice = IsPoliceJob(currentJob)
    isEMS = IsEMSJob(currentJob)
    isDispatcher = IsDispatcherJob(currentJob)

    local group = xPlayer.group or ''
    isAdmin = (group == 'admin' or group == 'superadmin' or group == 'god')

    -- Radial Menu aktualisieren
    UpdateRadialMenu()
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    currentGrade = job.grade or 0
    isPolice = IsPoliceJob(currentJob)
    isEMS = IsEMSJob(currentJob)
    isDispatcher = IsDispatcherJob(currentJob)

    -- Radial Menu aktualisieren
    UpdateRadialMenu()
end)

-- ================================================
-- Radial Menu registrieren
-- ================================================

local function GetMenuLabel()
    if isDispatcher then
        return 'Leitstelle'
    else
        return 'Notruf 911'
    end
end

local function GetMenuIcon()
    if isDispatcher then
        return 'tower-broadcast'  -- Funkturm-Icon
    else
        return 'phone'
    end
end

local function RegisterRadialMenu()
    -- Prüfen ob ox_lib vorhanden
    if not lib then
        print('^1[City Memory] ox_lib nicht gefunden! Radial Menu deaktiviert.^7')
        return false
    end

    -- Haupt-Menüpunkt im Radial Menu
    lib.addRadialItem({
        id = 'city_memory_main',
        label = GetMenuLabel(),
        icon = GetMenuIcon(),
        onSelect = function()
            OpenCityMemoryMenu()
        end
    })

    return true
end

-- Radial Menu aktualisieren wenn sich Job ändert
local function UpdateRadialMenu()
    if not lib then return end

    -- Alten Eintrag entfernen und neu hinzufügen
    lib.removeRadialItem('city_memory_main')
    lib.addRadialItem({
        id = 'city_memory_main',
        label = GetMenuLabel(),
        icon = GetMenuIcon(),
        onSelect = function()
            OpenCityMemoryMenu()
        end
    })
end

-- ================================================
-- Context Menu öffnen (Untermenü)
-- ================================================

function OpenCityMemoryMenu()
    local options = {}

    -- Dynamischer Titel
    local menuTitle = isDispatcher and '📟 Leitstelle' or '📞 Notruf 911'

    -- 📞 Notruf - für alle Spieler
    options[#options + 1] = {
        title = 'Notruf absetzen',
        description = 'Einen Notruf an die Leitstelle senden',
        icon = 'phone',
        iconColor = '#4CAF50',
        onSelect = function()
            TriggerEvent('city_memory:openCallUI')
        end
    }

    -- 📋 Dispatch - nur für Einsatzkräfte
    if isDispatcher then
        options[#options + 1] = {
            title = 'Dispatch öffnen',
            description = 'Einsatzverwaltung und aktive Notrufe',
            icon = 'headset',
            iconColor = '#2196F3',
            onSelect = function()
                TriggerEvent('city_memory:openDispatch')
            end
        }
    end

    -- 🖥️ MDT - nur für Polizei
    if isPolice then
        options[#options + 1] = {
            title = 'MDT öffnen',
            description = 'Mobile Data Terminal - Personen & Fahrzeuge',
            icon = 'laptop',
            iconColor = '#1976D2',
            onSelect = function()
                TriggerEvent('city_memory:openMDT')
            end
        }
    end

    -- 🗺️ Heatmap - für alle (Polizei sieht mehr)
    local heatmapDesc = heatmapActive and 'Heatmap ist aktiv' or 'Hotspots auf der Karte anzeigen'
    options[#options + 1] = {
        title = heatmapActive and '🟢 Heatmap deaktivieren' or 'Heatmap aktivieren',
        description = heatmapDesc,
        icon = 'map-location-dot',
        iconColor = heatmapActive and '#4CAF50' or '#FF9800',
        onSelect = function()
            TriggerEvent('city_memory:toggleHeatmap')
        end
    }

    -- ⚙️ Admin - nur für Admins
    if isAdmin then
        options[#options + 1] = {
            title = 'Admin Dashboard',
            description = 'Systemverwaltung und Statistiken',
            icon = 'gear',
            iconColor = '#F44336',
            onSelect = function()
                TriggerEvent('city_memory:openAdmin')
            end
        }
    end

    -- 🚔 Polizei-Aktionen - nur für Polizei
    if isPolice then
        options[#options + 1] = {
            title = '🚔 Polizei-Aktionen',
            description = 'Schnellzugriff für Einsätze',
            icon = 'shield-halved',
            iconColor = '#1976D2',
            onSelect = function()
                OpenPoliceActionsMenu()
            end
        }
    end

    -- Context Menu anzeigen
    lib.registerContext({
        id = 'city_memory_context',
        title = menuTitle,
        options = options
    })

    lib.showContext('city_memory_context')
end

-- ================================================
-- Events für die einzelnen Funktionen
-- ================================================

-- Notruf UI öffnen
RegisterNetEvent('city_memory:openCallUI', function()
    -- Prüfen ob bereits ein UI offen ist
    if IsNuiFocused() then return end

    SetNuiFocus(true, true)
    TriggerServerEvent('dispatch:getCategories')
    SendNUIMessage({ type = 'openCallUI' })
end)

-- Dispatch UI öffnen
RegisterNetEvent('city_memory:openDispatch', function()
    if not isDispatcher then
        lib.notify({
            title = 'Keine Berechtigung',
            description = 'Du bist keine Einsatzkraft.',
            type = 'error'
        })
        return
    end

    if IsNuiFocused() then return end

    SetNuiFocus(true, true)
    TriggerServerEvent('dispatch:getCalls')
    TriggerServerEvent('dispatch:getMyCalls')
    TriggerServerEvent('dispatch:getOnlineUnits')
    SendNUIMessage({ type = 'openDispatchUI', job = currentJob })
end)

-- MDT öffnen
RegisterNetEvent('city_memory:openMDT', function()
    if not isPolice then
        lib.notify({
            title = 'Keine Berechtigung',
            description = 'Du bist kein Polizist.',
            type = 'error'
        })
        return
    end

    if IsNuiFocused() then return end

    SetNuiFocus(true, true)
    TriggerServerEvent('mdt:getWantedList')
    TriggerServerEvent('mdt:getStatistics')
    SendNUIMessage({ type = 'openMDT', job = currentJob, grade = currentGrade })
end)

-- Admin Dashboard öffnen
RegisterNetEvent('city_memory:openAdmin', function()
    if not isAdmin then
        lib.notify({
            title = 'Keine Berechtigung',
            description = 'Du bist kein Admin.',
            type = 'error'
        })
        return
    end

    if IsNuiFocused() then return end

    SetNuiFocus(true, true)
    TriggerServerEvent('admin:getFullStatistics')
    TriggerServerEvent('admin:getLogs', 50)
    TriggerServerEvent('admin:getAllCalls', 100)
    SendNUIMessage({ type = 'openAdmin' })
end)

-- Heatmap Toggle
RegisterNetEvent('city_memory:toggleHeatmap', function()
    heatmapActive = not heatmapActive

    if heatmapActive then
        TriggerServerEvent('city_memory:requestZoneHeat')
        lib.notify({
            title = 'Heatmap aktiviert',
            description = isPolice and 'Alle Hotspots werden angezeigt.' or 'Nur starke Hotspots werden angezeigt.',
            type = 'success'
        })
    else
        TriggerEvent('city_memory:clearHeatmap')
        lib.notify({
            title = 'Heatmap deaktiviert',
            description = 'Hotspots ausgeblendet.',
            type = 'inform'
        })
    end

    -- Export für andere Scripts
    exports['city_memory']:SetHeatmapActive(heatmapActive)
end)

-- Heatmap Status für cl_zonemap.lua
exports('IsHeatmapActive', function()
    return heatmapActive
end)

exports('SetHeatmapActive', function(state)
    heatmapActive = state
end)

-- ================================================
-- Polizei-Aktionen Untermenü
-- ================================================

function OpenPoliceActionsMenu()
    local options = {
        {
            title = '🔍 Nächste Person überprüfen',
            description = 'Schau eine Person an und nutze ox_target',
            icon = 'id-card',
            disabled = true
        },
        {
            title = '🚗 Kennzeichen eingeben',
            description = 'Manuell ein Kennzeichen abfragen',
            icon = 'car',
            onSelect = function()
                local input = lib.inputDialog('Kennzeichen-Abfrage', {
                    { type = 'input', label = 'Kennzeichen', placeholder = 'z.B. LS 1234 AB', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('city_memory:queryPlate', input[1])
                end
            end
        },
        {
            title = '📋 Neue Fahndung',
            description = 'Person oder Fahrzeug zur Fahndung ausschreiben',
            icon = 'flag',
            onSelect = function()
                OpenWantedDialog()
            end
        },
        {
            title = '🗺️ Hotspots anzeigen',
            description = 'Aktuelle Brennpunkte auf der Karte',
            icon = 'map-location-dot',
            onSelect = function()
                TriggerEvent('city_memory:toggleHeatmap')
            end
        }
    }

    lib.registerContext({
        id = 'city_memory_police_actions',
        title = '🚔 Polizei-Aktionen',
        menu = 'city_memory_context',
        options = options
    })

    lib.showContext('city_memory_police_actions')
end

function OpenWantedDialog()
    local input = lib.inputDialog('Neue Fahndung erstellen', {
        { type = 'select', label = 'Typ', options = {
            { value = 'person', label = '👤 Person' },
            { value = 'vehicle', label = '🚗 Fahrzeug' }
        }, required = true },
        { type = 'input', label = 'Ziel (Name / Kennzeichen)', required = true },
        { type = 'textarea', label = 'Grund der Fahndung', required = true }
    })

    if input and input[1] and input[2] and input[3] then
        TriggerServerEvent('mdt:createWanted', {
            type = input[1],
            target = input[2],
            reason = input[3]
        })

        lib.notify({
            title = 'Fahndung erstellt',
            description = 'Alle Einheiten wurden informiert.',
            type = 'success'
        })
    end
end

-- ================================================
-- Command Fallback (falls jemand Commands bevorzugt)
-- ================================================

RegisterCommand('citymemory', function()
    OpenCityMemoryMenu()
end, false)

RegisterCommand('cm', function()
    OpenCityMemoryMenu()
end, false)

-- Einzelne Commands für direkten Zugriff
RegisterCommand('notruf', function()
    TriggerEvent('city_memory:openCallUI')
end, false)

RegisterCommand('dispatch', function()
    TriggerEvent('city_memory:openDispatch')
end, false)

RegisterCommand('mdt', function()
    TriggerEvent('city_memory:openMDT')
end, false)

RegisterCommand('heatmap', function()
    TriggerEvent('city_memory:toggleHeatmap')
end, false)

RegisterCommand('cityadmin', function()
    TriggerEvent('city_memory:openAdmin')
end, false)

-- ================================================
-- Optionaler Keybind für schnellen Zugriff
-- ================================================

if Config.Menu and Config.Menu.enableKeybind then
    RegisterCommand('opencitymemory', function()
        OpenCityMemoryMenu()
    end, false)
    RegisterKeyMapping('opencitymemory', 'City Memory Menü', 'keyboard', Config.Menu.keybind or 'F5')
end

-- ================================================
-- Initialisierung
-- ================================================

CreateThread(function()
    Wait(1000) -- Warten bis ox_lib geladen

    if RegisterRadialMenu() then
        print('^2[City Memory] Radial Menu erfolgreich registriert^7')
    else
        print('^3[City Memory] Fallback: Nutze /citymemory oder /cm^7')
    end
end)
