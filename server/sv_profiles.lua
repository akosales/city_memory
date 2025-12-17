-- ================================================
-- City Memory System - Player Profile Management
-- ================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================
-- Reputation ändern
-- ================================================

-- Stellt sicher, dass ein Profil existiert (legt bei Bedarf Default an)
local function EnsurePlayerProfile(identifier)
    PG.insert([[
        INSERT INTO player_profiles (identifier) VALUES (?)
        ON CONFLICT (identifier) DO NOTHING
    ]], { identifier })
end

local function NormalizeEventType(eventType)
    if type(eventType) ~= 'string' then return 'unknown' end
    local s = eventType:lower()
    s = s:gsub('[^a-z0-9_%-]', '_')
    if #s > 30 then s = s:sub(1, 30) end
    if s == '' then s = 'unknown' end
    return s
end

local function ModifyReputation(identifier, eventType, impact, context)
    -- Impact aus Config oder übergeben
    local normalizedEvent = NormalizeEventType(eventType)
    local reputationChange = impact or Config.ReputationModifiers[normalizedEvent] or 0.0

    -- Sicherstellen, dass ein Profil vorhanden ist
    local profile = GetCachedProfile(identifier)
    if not profile then
        EnsurePlayerProfile(identifier)
        profile = GetCachedProfile(identifier) or {
            reputation = Config.PlayerProfile and Config.PlayerProfile.defaultReputation or 0.5,
            volatility = 0.0,
            cooperation = 0.5,
            violence_tendency = 0.0,
            flee_tendency = 0.0,
        }
    end

    local currentRep = tonumber(profile.reputation) or (Config.PlayerProfile and Config.PlayerProfile.defaultReputation) or 0.5
    local newRep = math.max(
        Config.PlayerProfile.minReputation,
        math.min(Config.PlayerProfile.maxReputation, currentRep + reputationChange)
    )

    -- Neue Werte berechnen
    local newVolatility = tonumber(profile.volatility) or 0.0
    local newCooperation = tonumber(profile.cooperation) or 0.5
    local newViolence = tonumber(profile.violence_tendency) or 0.0
    local newFlee = tonumber(profile.flee_tendency) or 0.0

    -- Tendenzen tracken
    if normalizedEvent == 'flee_police' then
        newFlee = math.min(1.0, newFlee + 0.1)
    elseif normalizedEvent == 'weapon_vs_player' or normalizedEvent == 'weapon_vs_npc' then
        newViolence = math.min(1.0, newViolence + 0.1)
    elseif normalizedEvent == 'cooperate' or normalizedEvent == 'surrender' then
        newCooperation = math.min(1.0, newCooperation + 0.05)
    end

    -- Volatility erhöhen bei negativen Events
    if reputationChange < 0 then
        newVolatility = math.min(1.0, newVolatility + 0.05)
    end

    -- DB Update
    if reputationChange < 0 then
        PG.update([[
            UPDATE player_profiles
            SET reputation = ?,
                volatility = ?,
                cooperation = ?,
                violence_tendency = ?,
                flee_tendency = ?,
                last_negative_event = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE identifier = ?
        ]], { newRep, newVolatility, newCooperation, newViolence, newFlee, identifier })
    else
        PG.update([[
            UPDATE player_profiles
            SET reputation = ?,
                volatility = ?,
                cooperation = ?,
                violence_tendency = ?,
                flee_tendency = ?,
                last_positive_event = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE identifier = ?
        ]], { newRep, newVolatility, newCooperation, newViolence, newFlee, identifier })
    end

    -- Event loggen (Context als JSONB casten)
    local jsonValue = context and json.encode(context) or nil
    PG.insert([[
        INSERT INTO player_events (identifier, event_type, impact, context)
        VALUES (?, ?, ?, COALESCE(?::jsonb, '{}'::jsonb))
    ]], { identifier, normalizedEvent, reputationChange, jsonValue })

    -- Cache invalidieren
    ProfileCache[identifier] = nil

    Log('PROFILE', ('Reputation geändert: %s %.3f -> %.3f (%s)'):format(
        identifier, currentRep, newRep, normalizedEvent
    ))

    return true
end

-- ================================================
-- Profil abrufen
-- ================================================

local function GetPlayerProfile(identifier)
    local profile = GetCachedProfile(identifier)
    if not profile then return nil end

    return {
        reputation = tonumber(profile.reputation) or 0.5,
        volatility = tonumber(profile.volatility) or 0.0,
        cooperation = tonumber(profile.cooperation) or 0.5,
        violence_tendency = tonumber(profile.violence_tendency) or 0.0,
        flee_tendency = tonumber(profile.flee_tendency) or 0.0
    }
end

-- ================================================
-- Risk-Level Abfragen
-- ================================================

local function GetRiskLevel(identifier)
    local profile = GetCachedProfile(identifier)
    if not profile then return 'unknown' end

    local rep = tonumber(profile.reputation) or 0.5

    if rep < Config.RiskLevels.high then
        return 'high'
    elseif rep < Config.RiskLevels.medium then
        return 'medium'
    else
        return 'low'
    end
end

local function IsHighRisk(identifier)
    return GetRiskLevel(identifier) == 'high'
end

-- ================================================
-- Events von anderen Scripts / Client
-- ================================================

-- Flucht vor Polizei
RegisterNetEvent('city_memory:reportFlee', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    ModifyReputation(xPlayer.identifier, 'flee_police', nil, { source = source })
end)

-- Kooperation
RegisterNetEvent('city_memory:reportCooperation', function(targetId)
    local source = source
    -- Validierung: Nur Polizei darf das melden
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'police' then return end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    ModifyReputation(xTarget.identifier, 'cooperate', nil, { reportedBy = xPlayer.identifier })
end)

-- Waffengebrauch gegen Spieler
RegisterNetEvent('city_memory:reportWeaponUsePlayer', function(victimId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    ModifyReputation(xPlayer.identifier, 'weapon_vs_player', nil, { victim = victimId })
end)

-- Waffengebrauch gegen NPC
RegisterNetEvent('city_memory:reportWeaponUseNPC', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    ModifyReputation(xPlayer.identifier, 'weapon_vs_npc', nil, nil)
end)

-- Selbststellung
RegisterNetEvent('city_memory:reportSurrender', function(playerId)
    local source = source
    -- Validierung: Nur Polizei darf das melden
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'police' then return end

    local xTarget = ESX.GetPlayerFromId(playerId)
    if not xTarget then return end

    ModifyReputation(xTarget.identifier, 'surrender', nil, { reportedBy = xPlayer.identifier })
end)

-- ================================================
-- Exports registrieren
-- ================================================

exports('GetPlayerProfile', GetPlayerProfile)
exports('GetRiskLevel', GetRiskLevel)
exports('IsHighRisk', IsHighRisk)
exports('RegisterPlayerEvent', function(identifier, eventType, impact, context)
    return ModifyReputation(identifier, eventType, impact, context)
end)

Log('PROFILES', 'sv_profiles.lua geladen')
