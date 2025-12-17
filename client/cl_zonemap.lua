-- ================================================
-- City Memory System - Zonen-Visualisierung (Heatmap)
-- Zeigt Heat-Level als farbige Radius-Blips auf der Karte
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

local zoneBlips = {}
local showHeatmap = false
local updateInterval = 30000 -- 30s

-- Konfigurierbare Schwellen (Fallback, falls nicht in Config gesetzt)
local COP_MIN = (Config.ZoneHeatmap and Config.ZoneHeatmap.copMin) or 0.10
local CIV_MIN = (Config.ZoneHeatmap and Config.ZoneHeatmap.civMin) or 0.50
local RADIUS  = (Config.ZoneHeatmap and Config.ZoneHeatmap.radius) or 150.0

-- Job-Status
local currentJob = nil
local isPolice = false

CreateThread(function()
    while true do
        Wait(2000)
        local playerData = ESX.GetPlayerData()
        if playerData and playerData.job then
            currentJob = playerData.job.name
            isPolice = IsPoliceJob(currentJob)
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    isPolice = IsPoliceJob(currentJob)
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    isPolice = IsPoliceJob(currentJob)
end)

-- ================================================
-- Blip Helpers
-- ================================================

local function CreateZoneBlip(zoneId, coords, heat)
    if not coords then return nil end

    local blip = AddBlipForRadius(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, RADIUS)

    -- Farbe basierend auf Heat: Grün (2) < Orange (17) < Rot (1)
    local color = 2 -- Grün default
    if heat >= 0.7 then
        color = 1 -- Rot
    elseif heat >= 0.4 then
        color = 17 -- Orange
    end

    SetBlipColour(blip, color)
    SetBlipAlpha(blip, math.floor(math.min(1.0, math.max(0.0, heat)) * 180) + 40) -- 40-220
    return blip
end

local function ClearZoneBlips()
    for _, blip in pairs(zoneBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    zoneBlips = {}
end

-- ================================================
-- Heatmap Update & Filter
-- ================================================

local function UpdateHeatmap(zones)
    ClearZoneBlips()
    if not showHeatmap then return end
    if type(zones) ~= 'table' then return end

    local minHeat = isPolice and COP_MIN or CIV_MIN

    for zoneId, data in pairs(zones) do
        local heat = tonumber(data and data.heat) or 0.0
        local coords = data and data.coords
        if coords and heat and heat >= (minHeat or 0.1) then
            local blip = CreateZoneBlip(zoneId, coords, heat)
            if blip then
                zoneBlips[zoneId] = blip
            end
        end
    end
end

-- ================================================
-- Toggle Command/Keybind
-- ================================================

RegisterCommand('heatmap', function()
    showHeatmap = not showHeatmap

    if showHeatmap then
        TriggerServerEvent('city_memory:requestZoneHeat')
        SendNUIMessage({ type = 'showNotification', title = '~g~Heatmap aktiviert', message = isPolice and 'Alle Hotspots werden angezeigt.' or 'Nur starke Hotspots werden angezeigt.' })
    else
        ClearZoneBlips()
        SendNUIMessage({ type = 'showNotification', title = '~r~Heatmap deaktiviert', message = '' })
    end
end, false)

-- Standardbelegung F8 (kann später in Config verschoben werden)
RegisterKeyMapping('heatmap', 'Zone Heatmap an/aus', 'keyboard', 'F8')

-- Serverseitige Zone-Daten empfangen
RegisterNetEvent('city_memory:receiveZoneHeat', function(zones)
    UpdateHeatmap(zones)
end)

-- Auto-Update wenn aktiv
CreateThread(function()
    while true do
        Wait(updateInterval)
        if showHeatmap then
            TriggerServerEvent('city_memory:requestZoneHeat')
        end
    end
end)

-- Aufräumen bei Resource-Stop
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        ClearZoneBlips()
    end
end)
