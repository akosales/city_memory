-- ================================================
-- City Memory System - Zonen-Visualisierung (Heatmap)
-- v2.2 - Auto-Aktivierung für Polizei & Legende
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

local zoneBlips = {} -- [zoneId] = { blip = handle, lastSeen = ms }
local heatmapActive = false
local legendVisible = false
local updateInterval = Config.ZoneHeatmap and Config.ZoneHeatmap.interval or 30000
local pruneGraceMs = (Config.ZoneHeatmap and Config.ZoneHeatmap.pruneGraceMs) or 60000
local enableForCivilians = (Config.ZoneHeatmap and Config.ZoneHeatmap.enableForCivilians) ~= false
local autoEnableForCivilians = (Config.ZoneHeatmap and Config.ZoneHeatmap.autoEnableForCivilians) or false

-- Schwellenwerte
local COP_MIN = (Config.ZoneHeatmap and Config.ZoneHeatmap.copMin) or 0.10
local CIV_MIN = (Config.ZoneHeatmap and Config.ZoneHeatmap.civMin) or 0.50
local RADIUS  = (Config.ZoneHeatmap and Config.ZoneHeatmap.radius) or 150.0

-- Job-Status
local currentJob = nil
local isPolice = false
local wasPolice = false

-- Onboarding Flag (persistent via KVP)
local hasSeenHeatmapIntro = GetResourceKvpInt('city_memory:heatmap_intro') == 1

-- ================================================
-- Job Status Tracking
-- ================================================

local function UpdateJobStatus()
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
        currentJob = playerData.job.name
        wasPolice = isPolice
        isPolice = IsPoliceJob(currentJob)

        -- Auto-Aktivierung wenn Spieler Polizist wird
        if isPolice and not wasPolice then
            AutoEnableForPolice()
        end

        -- Wechsel von Polizei zu Zivilist: optionales Verhalten
        if not isPolice and wasPolice then
            if autoEnableForCivilians or enableForCivilians then
                AutoEnableForCivilian()
            else
                AutoDisableForCivilian()
            end
        end
    end
end

CreateThread(function()
    Wait(3000)
    UpdateJobStatus()

    while true do
        Wait(2000)
        UpdateJobStatus()
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    currentJob = xPlayer.job.name
    isPolice = IsPoliceJob(currentJob)

    SetTimeout(2000, function()
        if isPolice then
            AutoEnableForPolice()
        elseif autoEnableForCivilians and enableForCivilians then
            AutoEnableForCivilian()
        end
    end)
end)

RegisterNetEvent('esx:setJob', function(job)
    currentJob = job.name
    wasPolice = isPolice
    isPolice = IsPoliceJob(currentJob)

    if isPolice and not wasPolice then
        AutoEnableForPolice()
    elseif not isPolice and wasPolice then
        AutoDisableForCivilian()
    end
end)

-- ================================================
-- Auto-Aktivierung für Polizei
-- ================================================

function AutoEnableForPolice()
    if heatmapActive then return end

    heatmapActive = true
    legendVisible = true

    TriggerServerEvent('city_memory:requestZoneHeat')
    ShowLegend(true)

    -- Onboarding (nur einmal pro Spieler)
    if not hasSeenHeatmapIntro then
        hasSeenHeatmapIntro = true
        SetResourceKvpInt('city_memory:heatmap_intro', 1)

        SetTimeout(1500, function()
            ShowHeatmapIntro()
        end)
    else
        if lib and lib.notify then
            lib.notify({
                title = 'Heatmap aktiv',
                description = 'Kriminalitäts-Hotspots werden angezeigt',
                type = 'inform',
                duration = 3000
            })
        end
    end
end

function AutoDisableForCivilian()
    heatmapActive = false
    legendVisible = false
    ClearZoneBlips()
    ShowLegend(false)
end

function AutoEnableForCivilian()
    if not enableForCivilians then return end
    if heatmapActive then return end

    heatmapActive = true
    legendVisible = true
    TriggerServerEvent('city_memory:requestZoneHeat')
    ShowLegend(true)

    if lib and lib.notify then
        lib.notify({
            title = 'Heatmap aktiv',
            description = 'Hotspots für Bürger werden angezeigt',
            type = 'inform',
            duration = 3000
        })
    end
end

-- ================================================
-- Onboarding: Erster Heatmap Hinweis
-- ================================================

function ShowHeatmapIntro()
    SendNUIMessage({
        type = 'showHeatmapIntro',
        isPolice = isPolice
    })
end

-- ================================================
-- Legende anzeigen/verstecken
-- ================================================

function ShowLegend(show)
    legendVisible = show
    SendNUIMessage({
        type = 'toggleHeatmapLegend',
        show = show,
        isPolice = isPolice
    })
end

-- ================================================
-- Blip Helpers
-- ================================================

local function ApplyBlipStyle(blip, heat)
    local color = 2 -- Grün
    if heat >= 0.7 then
        color = 1 -- Rot
    elseif heat >= 0.4 then
        color = 17 -- Orange
    end
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, math.floor(math.min(1.0, math.max(0.0, heat)) * 180) + 40)
end

local function CreateZoneBlip(zoneId, coords, heat)
    if not coords then return nil end
    local blip = AddBlipForRadius(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, RADIUS)
    ApplyBlipStyle(blip, heat)
    return blip
end

local function ClearZoneBlips()
    for _, entry in pairs(zoneBlips) do
        local blip = entry and entry.blip or entry -- backward compatibility
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    zoneBlips = {}
end

-- ================================================
-- Heatmap Update
-- ================================================

local function UpdateHeatmap(zones)
    if not heatmapActive then return end
    if type(zones) ~= 'table' then return end

    local minHeat = isPolice and COP_MIN or CIV_MIN
    local now = GetGameTimer()

    for zoneId, data in pairs(zones) do
        local heat = tonumber(data and data.heat) or 0.0
        local coords = data and data.coords
        if coords and heat and heat >= minHeat then
            local entry = zoneBlips[zoneId]
            if entry and entry.blip and DoesBlipExist(entry.blip) then
                -- Update bestehenden Blip
                ApplyBlipStyle(entry.blip, heat)
                entry.lastSeen = now
            else
                -- Neu erstellen
                local blip = CreateZoneBlip(zoneId, coords, heat)
                if blip then
                    zoneBlips[zoneId] = { blip = blip, lastSeen = now }
                end
            end
        end
    end

    -- Pruning: entferne Blips, die seit Gnadenfrist nicht mehr gesehen wurden
    for zId, entry in pairs(zoneBlips) do
        local last = entry.lastSeen or 0
        if now - last > pruneGraceMs then
            local blip = entry.blip or entry
            if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
            zoneBlips[zId] = nil
        end
    end
end

-- ================================================
-- Manuelles Toggle (über Menü/Command)
-- ================================================

function ToggleHeatmap()
    if (not isPolice) and (not enableForCivilians) then
        if lib and lib.notify then
            lib.notify({ title = 'Heatmap', description = 'Für Zivilisten deaktiviert', type = 'error', duration = 2500 })
        end
        return
    end

    heatmapActive = not heatmapActive
    legendVisible = heatmapActive

    if heatmapActive then
        TriggerServerEvent('city_memory:requestZoneHeat')
        ShowLegend(true)

        if lib and lib.notify then
            lib.notify({
                title = 'Heatmap aktiviert',
                description = isPolice and 'Alle Hotspots werden angezeigt' or 'Starke Hotspots werden angezeigt',
                type = 'success',
                duration = 3000
            })
        end
    else
        ClearZoneBlips()
        ShowLegend(false)

        if lib and lib.notify then
            lib.notify({
                title = 'Heatmap deaktiviert',
                description = 'Hotspots ausgeblendet',
                type = 'inform',
                duration = 3000
            })
        end
    end
end

-- ================================================
-- Events
-- ================================================

RegisterNetEvent('city_memory:toggleHeatmap', function()
    ToggleHeatmap()
end)

RegisterNetEvent('city_memory:clearHeatmap', function()
    heatmapActive = false
    legendVisible = false
    ClearZoneBlips()
    ShowLegend(false)
end)

RegisterNetEvent('city_memory:receiveZoneHeat', function(zones)
    UpdateHeatmap(zones)
end)

-- ================================================
-- Exports
-- ================================================

exports('IsHeatmapActive', function()
    return heatmapActive
end)

exports('SetHeatmapActive', function(state)
    if state and not heatmapActive then
        heatmapActive = true
        legendVisible = true
        TriggerServerEvent('city_memory:requestZoneHeat')
        ShowLegend(true)
    elseif not state and heatmapActive then
        heatmapActive = false
        legendVisible = false
        ClearZoneBlips()
        ShowLegend(false)
    end
end)

exports('ToggleHeatmap', ToggleHeatmap)
exports('ClearHeatmap', ClearZoneBlips)

exports('RefreshHeatmap', function()
    if heatmapActive then
        TriggerServerEvent('city_memory:requestZoneHeat')
    end
end)

-- ================================================
-- Auto-Update Loop
-- ================================================

CreateThread(function()
    while true do
        Wait(updateInterval)

        if heatmapActive then
            TriggerServerEvent('city_memory:requestZoneHeat')
        end
    end
end)

-- ================================================
-- Cleanup
-- ================================================

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        ClearZoneBlips()
        ShowLegend(false)
    end
end)

print('^2[City Memory] Heatmap System v2.2 geladen^7')
