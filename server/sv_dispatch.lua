-- ================================================
-- City Memory System - Dispatch Server
-- Notruf & Einsatzverwaltung
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- Aktive Notrufe
local ActiveCalls = {}
local CallIdCounter = 1000

-- ================================================
-- Kategorien & Prioritäten
-- ================================================

local Categories = {
    ['shooting'] = { label = 'Schüsse', priority = 'high', icon = '🔫', police = true, ems = true },
    ['robbery'] = { label = 'Überfall', priority = 'high', icon = '💰', police = true, ems = false },
    ['assault'] = { label = 'Körperverletzung', priority = 'high', icon = '👊', police = true, ems = true },
    ['pursuit'] = { label = 'Verfolgung', priority = 'high', icon = '🚗', police = true, ems = false },
    ['medical'] = { label = 'Medizinisch', priority = 'medium', icon = '🏥', police = false, ems = true },
    ['accident'] = { label = 'Unfall', priority = 'medium', icon = '💥', police = true, ems = true },
    ['fire'] = { label = 'Feuer', priority = 'medium', icon = '🔥', police = true, ems = true },
    ['theft'] = { label = 'Diebstahl', priority = 'low', icon = '🦹', police = true, ems = false },
    ['suspicious'] = { label = 'Verdächtige Person', priority = 'low', icon = '👤', police = true, ems = false },
    ['other'] = { label = 'Sonstiges', priority = 'low', icon = '❓', police = true, ems = true },
}

-- ================================================
-- Helper Functions
-- ================================================

local function GenerateCallId()
    CallIdCounter = CallIdCounter + 1
    return CallIdCounter
end

local function GetPlayerJob(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    return xPlayer.job.name
end

local function IsDispatcher(source)
    local job = GetPlayerJob(source)
    return IsDispatcherJob(job)
end

local function IsPolice(source)
    local job = GetPlayerJob(source)
    return IsPoliceJob(job)
end

local function IsEMS(source)
    local job = GetPlayerJob(source)
    return IsEMSJob(job)
end

local function CanSeeCatgory(source, category)
    local cat = Categories[category]
    if not cat then return true end

    if IsPolice(source) and cat.police then return true end
    if IsEMS(source) and cat.ems then return true end

    return false
end

local function GetStreetName(coords)
    -- Server: Kein Zugriff auf Client-Natives wie GetStreetNameAtCoord.
    -- Fallback: nutze Zonenlabel oder leeren String, damit die UI weiterhin ein Feld hat.
    local zoneLabel = GetZoneLabel(coords)
    if zoneLabel and zoneLabel ~= '' and zoneLabel ~= 'Außerhalb' then
        return zoneLabel
    end
    return ''
end

local function GetZoneLabel(coords)
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    if zoneId and Config.Zones[zoneId] then
        return Config.Zones[zoneId].label
    end
    return 'Außerhalb'
end

local function NormalizeStreetServer(name)
    if not name or name == '' then return '' end
    -- trim
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    -- multiple spaces to single
    name = name:gsub('%s+', ' ')
    -- limit to 200 (DB column limit)
    if #name > 200 then
        name = name:sub(1, 200)
    end
    return name
end

-- ================================================
-- Notruf erstellen
-- ================================================

RegisterNetEvent('dispatch:createCall', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)

    local callId = GenerateCallId()
    local category = data.category or 'other'
    local catInfo = Categories[category] or Categories['other']

    local call = {
        id = callId,
        category = category,
        categoryLabel = catInfo.label,
        categoryIcon = catInfo.icon,
        priority = catInfo.priority,
        message = data.message or '',
        anonymous = data.anonymous or false,
        caller = {
            id = source,
            identifier = xPlayer.identifier,
            name = data.anonymous and 'ANONYM' or xPlayer.getName(),
        },
        location = {
            coords = { x = coords.x, y = coords.y, z = coords.z },
            street = NormalizeStreetServer(data and data.street and data.street ~= '' and data.street or GetStreetName(coords)),
            zone = GetZoneLabel(coords),
        },
        status = 'open', -- open, accepted, enroute, onscene, completed
        assignedUnits = {},
        createdAt = os.time(),
        updatedAt = os.time(),
    }

    ActiveCalls[callId] = call

    -- Zone Heat erhöhen
    local zoneId = exports['city_memory']:GetZoneFromCoords(coords)
    if zoneId then
        local severity = 0.05
        if catInfo.priority == 'high' then severity = 0.15 end
        if catInfo.priority == 'medium' then severity = 0.10 end
        exports['city_memory']:RegisterZoneEvent(zoneId, 'emergency_call', severity, xPlayer.identifier)
    end

    -- Bestätigung an Anrufer
    TriggerClientEvent('dispatch:callCreated', source, {
        callId = callId,
        message = 'Notruf wurde übermittelt. Bleiben Sie in der Nähe.'
    })

    -- An alle Dispatcher senden
    BroadcastNewCall(call)

    local locText = call.location.zone
    if call.location.street and call.location.street ~= '' then
        locText = call.location.street .. ' (' .. call.location.zone .. ')'
    end

    Log('DISPATCH', ('Neuer Notruf #%d: %s von %s in %s'):format(
        callId, catInfo.label, call.caller.name, locText
    ))
end)

-- ================================================
-- Notruf an Dispatcher broadcasten
-- ================================================

function BroadcastNewCall(call)
    local players = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(players) do
        if IsDispatcher(xPlayer.source) then
            if CanSeeCatgory(xPlayer.source, call.category) then
                TriggerClientEvent('dispatch:newCall', xPlayer.source, call)
            end
        end
    end
end

-- ================================================
-- Notruf annehmen
-- ================================================

RegisterNetEvent('dispatch:acceptCall', function(callId)
    local source = source
    if not IsDispatcher(source) then return end

    local call = ActiveCalls[callId]
    if not call then
        TriggerClientEvent('dispatch:error', source, 'Notruf nicht gefunden.')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local unitInfo = {
        id = source,
        name = xPlayer.getName(),
        job = xPlayer.job.name,
        status = 'enroute',
        acceptedAt = os.time()
    }

    -- Zur Unit-Liste hinzufügen
    table.insert(call.assignedUnits, unitInfo)

    -- Status aktualisieren wenn erster
    if call.status == 'open' then
        call.status = 'accepted'
    end
    call.updatedAt = os.time()

    -- Bestätigung an Dispatcher
    TriggerClientEvent('dispatch:callAccepted', source, {
        callId = callId,
        call = call
    })

    -- Anrufer benachrichtigen
    if call.caller.id and GetPlayerPed(call.caller.id) then
        TriggerClientEvent('dispatch:unitsEnroute', call.caller.id, {
            unitName = xPlayer.getName(),
            unitJob = xPlayer.job.label or xPlayer.job.name
        })
    end

    -- Alle Dispatcher aktualisieren
    BroadcastCallUpdate(call)

    Log('DISPATCH', ('%s hat Notruf #%d angenommen'):format(xPlayer.getName(), callId))
end)

-- ================================================
-- Status aktualisieren
-- ================================================

RegisterNetEvent('dispatch:updateStatus', function(callId, newStatus)
    local source = source
    if not IsDispatcher(source) then return end

    local call = ActiveCalls[callId]
    if not call then return end

    local xPlayer = ESX.GetPlayerFromId(source)

    -- Unit-Status aktualisieren
    for _, unit in ipairs(call.assignedUnits) do
        if unit.id == source then
            unit.status = newStatus
        end
    end

    -- Gesamt-Status aktualisieren
    if newStatus == 'onscene' then
        call.status = 'onscene'
    elseif newStatus == 'completed' then
        -- Prüfen ob alle fertig
        local allCompleted = true
        for _, unit in ipairs(call.assignedUnits) do
            if unit.status ~= 'completed' then
                allCompleted = false
            end
        end
        if allCompleted then
            call.status = 'completed'
        end
    end

    call.updatedAt = os.time()

    -- Anrufer über Status informieren
    if call.caller.id and GetPlayerPed(call.caller.id) then
        if newStatus == 'onscene' then
            TriggerClientEvent('dispatch:unitsArrived', call.caller.id)
        elseif newStatus == 'completed' then
            TriggerClientEvent('dispatch:callCompleted', call.caller.id)
        end
    end

    BroadcastCallUpdate(call)

    Log('DISPATCH', ('%s Status für #%d: %s'):format(xPlayer.getName(), callId, newStatus))
end)

-- ================================================
-- Notruf abschließen
-- ================================================

RegisterNetEvent('dispatch:closeCall', function(callId)
    local source = source
    if not IsDispatcher(source) then return end

    local call = ActiveCalls[callId]
    if not call then return end

    call.status = 'completed'
    call.updatedAt = os.time()

    -- In DB speichern für Historie
    PG.insert([[
        INSERT INTO dispatch_history (call_id, category, priority, message, caller_name, location_zone, location_street, coords_x, coords_y, coords_z, created_at, closed_at, units_count)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, to_timestamp(?), CURRENT_TIMESTAMP, ?)
    ]], {
        call.id,
        call.category,
        call.priority,
        call.message,
        call.caller.name,
        call.location.zone,
        call.location.street,
        call.location.coords.x,
        call.location.coords.y,
        call.location.coords.z,
        call.createdAt,
        #call.assignedUnits
    })

    BroadcastCallUpdate(call)

    -- Nach 5 Sekunden aus aktiven Calls entfernen
    SetTimeout(5000, function()
        ActiveCalls[callId] = nil
        BroadcastCallRemoved(callId)
    end)

    Log('DISPATCH', ('Notruf #%d abgeschlossen'):format(callId))
end)

-- ================================================
-- Backup anfordern
-- ================================================

RegisterNetEvent('dispatch:requestBackup', function(callId)
    local source = source
    if not IsDispatcher(source) then return end

    local call = ActiveCalls[callId]
    if not call then return end

    local xPlayer = ESX.GetPlayerFromId(source)

    -- An alle Dispatcher senden
    local players = ESX.GetExtendedPlayers()
    for _, player in pairs(players) do
        if IsDispatcher(player.source) and player.source ~= source then
            if CanSeeCatgory(player.source, call.category) then
                TriggerClientEvent('dispatch:backupRequested', player.source, {
                    callId = callId,
                    call = call,
                    requestedBy = xPlayer.getName()
                })
            end
        end
    end

    Log('DISPATCH', ('%s fordert Backup für #%d'):format(xPlayer.getName(), callId))
end)

-- ================================================
-- Alle Calls abrufen
-- ================================================

RegisterNetEvent('dispatch:getCalls', function()
    local source = source
    if not IsDispatcher(source) then return end

    local visibleCalls = {}

    for callId, call in pairs(ActiveCalls) do
        if call.status ~= 'completed' then
            if CanSeeCatgory(source, call.category) then
                table.insert(visibleCalls, call)
            end
        end
    end

    -- Nach Priorität sortieren
    table.sort(visibleCalls, function(a, b)
        local priorityOrder = { high = 1, medium = 2, low = 3 }
        if priorityOrder[a.priority] ~= priorityOrder[b.priority] then
            return priorityOrder[a.priority] < priorityOrder[b.priority]
        end
        return a.createdAt > b.createdAt
    end)

    TriggerClientEvent('dispatch:receiveCalls', source, visibleCalls)
end)

-- ================================================
-- Meine Einsätze abrufen
-- ================================================

RegisterNetEvent('dispatch:getMyCalls', function()
    local source = source
    if not IsDispatcher(source) then return end

    local myCalls = {}

    for callId, call in pairs(ActiveCalls) do
        for _, unit in ipairs(call.assignedUnits) do
            if unit.id == source then
                table.insert(myCalls, call)
                break
            end
        end
    end

    TriggerClientEvent('dispatch:receiveMyCalls', source, myCalls)
end)

-- ================================================
-- Broadcast Helpers
-- ================================================

function BroadcastCallUpdate(call)
    local players = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(players) do
        if IsDispatcher(xPlayer.source) then
            if CanSeeCatgory(xPlayer.source, call.category) then
                TriggerClientEvent('dispatch:callUpdated', xPlayer.source, call)
            end
        end
    end
end

function BroadcastCallRemoved(callId)
    local players = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(players) do
        if IsDispatcher(xPlayer.source) then
            TriggerClientEvent('dispatch:callRemoved', xPlayer.source, callId)
        end
    end
end

-- ================================================
-- Kategorien an Client senden
-- ================================================

RegisterNetEvent('dispatch:getCategories', function()
    local source = source
    TriggerClientEvent('dispatch:receiveCategories', source, Categories)
end)

-- ================================================
-- Auto-Cleanup alter Notrufe (15 Min)
-- ================================================

CreateThread(function()
    while true do
        Wait(60000) -- Jede Minute prüfen

        local now = os.time()
        local timeout = 15 * 60 -- 15 Minuten

        for callId, call in pairs(ActiveCalls) do
            if call.status == 'open' and (now - call.createdAt) > timeout then
                call.status = 'expired'
                BroadcastCallRemoved(callId)
                ActiveCalls[callId] = nil
                Log('DISPATCH', ('Notruf #%d abgelaufen'):format(callId))
            end
        end
    end
end)

-- ================================================
-- Online Units zählen
-- ================================================

RegisterNetEvent('dispatch:getOnlineUnits', function()
    local source = source

    local policeCount = 0
    local emsCount = 0

    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(players) do
        if IsPolice(xPlayer.source) then
            policeCount = policeCount + 1
        elseif IsEMS(xPlayer.source) then
            emsCount = emsCount + 1
        end
    end

    TriggerClientEvent('dispatch:receiveOnlineUnits', source, {
        police = policeCount,
        ems = emsCount
    })
end)

-- Export: Aktive Notrufe abrufen (für Admin-Panel/MDT)
exports('GetActiveCalls', function()
    local list = {}
    for _, call in pairs(ActiveCalls) do
        if call then table.insert(list, call) end
    end
    table.sort(list, function(a, b) return a.createdAt > b.createdAt end)
    return list
end)

Log('DISPATCH', 'sv_dispatch.lua geladen')


-- ================================================
-- Berechtigungs-Check (UI öffnen)
-- ================================================

RegisterNetEvent('dispatch:canOpen', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local jobName = nil
    local allowed = false

    if xPlayer and xPlayer.job and xPlayer.job.name then
        jobName = xPlayer.job.name
        allowed = IsDispatcherJob(jobName)
    end

    TriggerClientEvent('dispatch:canOpenResult', src, allowed, jobName)
end)
