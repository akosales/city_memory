-- ================================================
-- Neon PostgreSQL HTTP Connector für FiveM
-- Nutzt Neon's Serverless Driver API
-- Keine externen Dependencies nötig
-- ================================================

local PG = {}

-- Connection Details - Zwei Möglichkeiten:
-- 1. Einzelne ConVars: city_memory_pg_host, city_memory_pg_user, etc.
-- 2. Connection String: city_memory_pg_connection

local connInfo = {}
local connectionString = ''

local function buildConnectionString()
    local host = GetConvar('city_memory_pg_host', '')
    local port = GetConvar('city_memory_pg_port', '5432')
    local database = GetConvar('city_memory_pg_database', '')
    local user = GetConvar('city_memory_pg_user', '')
    local password = GetConvar('city_memory_pg_password', '')

    if host ~= '' and user ~= '' and password ~= '' and database ~= '' then
        connInfo = {
            host = host,
            port = port,
            database = database,
            user = user,
            password = password
        }
        connectionString = ('postgresql://%s:%s@%s/%s?sslmode=require'):format(
            user, password, host, database
        )
        print('^2[City Memory PG] Connection via ConVars:^7 ' .. host .. '/' .. database)
        return true
    end
    return false
end

local function parseConnectionString(connStr)
    -- postgresql://user:pass@host/database?sslmode=require
    local pattern = "postgresql://([^:]+):([^@]+)@([^/]+)/([^?]+)"
    local user, pass, host, database = connStr:match(pattern)

    if user and pass and host and database then
        connInfo = {
            user = user,
            password = pass,
            host = host,
            database = database
        }
        connectionString = connStr
        print('^2[City Memory PG] Connection via String:^7 ' .. host .. '/' .. database)
        return true
    end
    return false
end

-- Initialisierung: Versuche beide Methoden
local function initConnection()
    -- Methode 1: Einzelne ConVars
    if buildConnectionString() then
        return true
    end

    -- Methode 2: Connection String
    local connStr = GetConvar('city_memory_pg_connection', '')
    if connStr ~= '' then
        if parseConnectionString(connStr) then
            return true
        end
    end

    -- Fallback: Alte ConVar-Namen (Rückwärtskompatibilität)
    connStr = GetConvar('pg_connection_string', '')
    if connStr ~= '' then
        if parseConnectionString(connStr) then
            return true
        end
    end

    print('^1[City Memory PG] FEHLER: Keine Datenbankverbindung konfiguriert^7')
    print('^3Füge folgendes zur server.cfg hinzu:^7')
    print('')
    print('^3# Option 1: Einzelne Werte^7')
    print('^3set city_memory_pg_host "ep-xxxxx.eu-central-1.aws.neon.tech"^7')
    print('^3set city_memory_pg_database "city_memory"^7')
    print('^3set city_memory_pg_user "dein_user"^7')
    print('^3set city_memory_pg_password "dein_passwort"^7')
    print('')
    print('^3# Option 2: Connection String^7')
    print('^3set city_memory_pg_connection "postgresql://user:pass@host/db?sslmode=require"^7')
    return false
end

initConnection()

-- ================================================
-- SQL Parameter Escaping
-- ================================================

local function escapeValue(value)
    if value == nil then
        return 'NULL'
    end

    local t = type(value)

    if t == 'string' then
        local escaped = value:gsub("'", "''")
        escaped = escaped:gsub("\\", "\\\\")
        return "'" .. escaped .. "'"
    elseif t == 'number' then
        return tostring(value)
    elseif t == 'boolean' then
        return value and 'TRUE' or 'FALSE'
    elseif t == 'table' then
        -- Automatisch Tabellen als JSON serialisieren (für ?::jsonb)
        local ok, encoded = pcall(json.encode, value)
        if not ok then
            -- Fallback: tostring, damit die Query nicht bricht
            local fallback = tostring(value):gsub("'", "''")
            fallback = fallback:gsub("\\", "\\\\")
            return "'" .. fallback .. "'"
        end
        -- SQL-safe machen
        encoded = encoded:gsub("'", "''")
        encoded = encoded:gsub("\\", "\\\\")
        return "'" .. encoded .. "'"
    else
        local escaped = tostring(value):gsub("'", "''")
        escaped = escaped:gsub("\\", "\\\\")
        return "'" .. escaped .. "'"
    end
end

local function interpolateParams(query, params)
    if not params or #params == 0 then
        return query
    end

    local result = query
    for i, param in ipairs(params) do
        local escaped = escapeValue(param)
        -- Verwende Funktionsersatz, damit '%' im String nicht als Platzhalter interpretiert wird
        result = result:gsub('%?', function() return escaped end, 1)
    end

    return result
end

-- ================================================
-- Neon Serverless HTTP API
-- ================================================

local function getNeonApiUrl()
    if not connInfo.host then return nil end

    -- Extrahiere Host ohne -pooler
    local host = connInfo.host:gsub('-pooler', '')

    return 'https://' .. host .. '/sql'
end

-- ================================================
-- Query Execution via Neon HTTP
-- ================================================

function PG.query(query, params, callback)
    local finalQuery = interpolateParams(query, params)
    local url = getNeonApiUrl()

    if not url then
        print('^1[City Memory PG] Keine gültige Connection^7')
        if callback then callback(nil) end
        return nil
    end

    local p = promise.new()

    local requestBody = json.encode({
        query = finalQuery
    })

    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode >= 200 and statusCode < 300 then
            local success, response = pcall(json.decode, responseText)
            if success and response then
                local rows = response.rows or response or {}
                if callback then callback(rows) end
                p:resolve(rows)
            else
                print('^1[City Memory PG] JSON Parse Error^7')
                if Config and Config.Debug then
                    print('^3Response: ' .. (responseText or 'nil'):sub(1, 200) .. '^7')
                end
                if callback then callback({}) end
                p:resolve({})
            end
            else
                    print(('^1[City Memory PG] HTTP Error %d^7'):format(statusCode or 0))
                    print('^3Query: ' .. finalQuery:sub(1, 300) .. '^7')
                    if responseText then
                        print('^3Response: ' .. responseText:sub(1, 500) .. '^7')
                    end
                    if true then
                -- Query gekürzt und Zeilenumbrüche reduziert für bessere Lesbarkeit
                local q = finalQuery:gsub('%s+', ' ')
                if #q > 500 then
                    q = q:sub(1, 500) .. ('... (%d bytes total)'):format(#finalQuery)
                end
                print(('^3Query: %s^7'):format(q))
                if responseText then
                    local resp = responseText
                    if #resp > 2000 then
                        resp = resp:sub(1, 2000) .. ('... (%d bytes total)'):format(#responseText)
                    end
                    print(('^3Response: %s^7'):format(resp))
                end
            end
            if callback then callback(nil) end
            p:resolve(nil)
        end
    end, 'POST', requestBody, {
        ['Content-Type'] = 'application/json',
        ['Neon-Connection-String'] = connectionString
    })

    return Citizen.Await(p)
end

-- Alias Funktionen
function PG.execute(query, params, callback)
    return PG.query(query, params, callback)
end

function PG.insert(query, params, callback)
    return PG.query(query, params, callback)
end

function PG.update(query, params, callback)
    return PG.query(query, params, callback)
end

function PG.scalar(query, params, callback)
    local result = PG.query(query, params)
    if result and result[1] then
        for k, v in pairs(result[1]) do
            if callback then callback(v) end
            return v
        end
    end
    if callback then callback(nil) end
    return nil
end

-- Async Variante
function PG.queryAsync(query, params, callback)
    local finalQuery = interpolateParams(query, params)
    local url = getNeonApiUrl()

    if not url then
        if callback then callback(nil) end
        return
    end

    local requestBody = json.encode({
        query = finalQuery
    })

    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode >= 200 and statusCode < 300 then
            local success, response = pcall(json.decode, responseText)
            if success and response then
                local rows = response.rows or response or {}
                if callback then callback(rows) end
            else
                if callback then callback({}) end
            end
        else
            if callback then callback(nil) end
        end
    end, 'POST', requestBody, {
        ['Content-Type'] = 'application/json',
        ['Neon-Connection-String'] = connectionString
    })
end

-- ================================================
-- Connection Test
-- ================================================

CreateThread(function()
    Wait(3000)

    if not connInfo.host then
        print('^1[City Memory PG] Überspringe Connection Test - keine Config^7')
        return
    end

    print('^3[City Memory PG] Teste Datenbankverbindung...^7')

    local result = PG.query('SELECT 1 as connected')

    if result then
        print('^2[City Memory PG] ✓ Verbindung zu NeonDB erfolgreich!^7')
    else
        print('^1[City Memory PG] ✗ Verbindung fehlgeschlagen!^7')
        print('^3Prüfe:^7')
        print('^3  1. city_memory_pg_* ConVars in server.cfg^7')
        print('^3  2. NeonDB ist erreichbar^7')
        print('^3  3. Passwort ist korrekt^7')
    end
end)

-- ================================================
-- Global verfügbar
-- ================================================

_G.PG = PG

print('^2[City Memory] PostgreSQL Connector geladen^7')

return PG
