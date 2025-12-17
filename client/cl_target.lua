-- ================================================
-- City Memory System - ox_target Interaktionen
-- Interaktionen an Objekten (Computer, Telefone, etc.)
-- ================================================

-- ================================================
-- Polizei-Computer (MDT)
-- ================================================

-- Mission Row PD
exports.ox_target:addBoxZone({
    coords = vec3(441.79, -982.08, 30.69),
    size = vec3(1.0, 1.0, 1.5),
    rotation = 0,
    debug = Config.Debug,
    options = {
        {
            name = 'mdt_missionrow',
            icon = 'fa-solid fa-laptop',
            label = 'MDT öffnen',
            onSelect = function()
                TriggerEvent('city_memory:openMDT')
            end,
            canInteract = function()
                return IsPoliceJob(GetPlayerJob())
            end
        },
        {
            name = 'dispatch_missionrow',
            icon = 'fa-solid fa-headset',
            label = 'Dispatch öffnen',
            onSelect = function()
                TriggerEvent('city_memory:openDispatch')
            end,
            canInteract = function()
                return IsDispatcherJob(GetPlayerJob())
            end
        }
    }
})

-- Vespucci PD
exports.ox_target:addBoxZone({
    coords = vec3(-1093.84, -809.13, 19.29),
    size = vec3(1.0, 1.0, 1.5),
    rotation = 0,
    debug = Config.Debug,
    options = {
        {
            name = 'mdt_vespucci',
            icon = 'fa-solid fa-laptop',
            label = 'MDT öffnen',
            onSelect = function()
                TriggerEvent('city_memory:openMDT')
            end,
            canInteract = function()
                return IsPoliceJob(GetPlayerJob())
            end
        }
    }
})

-- Sandy Shores Sheriff
exports.ox_target:addBoxZone({
    coords = vec3(1853.18, 3686.63, 34.27),
    size = vec3(1.0, 1.0, 1.5),
    rotation = 0,
    debug = Config.Debug,
    options = {
        {
            name = 'mdt_sandy',
            icon = 'fa-solid fa-laptop',
            label = 'MDT öffnen',
            onSelect = function()
                TriggerEvent('city_memory:openMDT')
            end,
            canInteract = function()
                return IsPoliceJob(GetPlayerJob())
            end
        }
    }
})

-- Paleto Bay Sheriff
exports.ox_target:addBoxZone({
    coords = vec3(-448.22, 6012.85, 31.72),
    size = vec3(1.0, 1.0, 1.5),
    rotation = 0,
    debug = Config.Debug,
    options = {
        {
            name = 'mdt_paleto',
            icon = 'fa-solid fa-laptop',
            label = 'MDT öffnen',
            onSelect = function()
                TriggerEvent('city_memory:openMDT')
            end,
            canInteract = function()
                return IsPoliceJob(GetPlayerJob())
            end
        }
    }
})

-- ================================================
-- Leitstelle / Dispatch Center
-- ================================================

-- Mission Row Dispatch Desk
exports.ox_target:addBoxZone({
    coords = vec3(441.16, -979.43, 30.69),
    size = vec3(2.0, 1.5, 1.5),
    rotation = 0,
    debug = Config.Debug,
    options = {
        {
            name = 'dispatch_desk',
            icon = 'fa-solid fa-headset',
            label = 'Leitstelle öffnen',
            onSelect = function()
                TriggerEvent('city_memory:openDispatch')
            end,
            canInteract = function()
                return IsDispatcherJob(GetPlayerJob())
            end
        }
    }
})

-- ================================================
-- Krankenhaus (EMS Dispatch)
-- ================================================

-- Pillbox Hospital
exports.ox_target:addBoxZone({
    coords = vec3(311.67, -592.76, 43.29),
    size = vec3(1.5, 1.0, 1.5),
    rotation = 0,
    debug = Config.Debug,
    options = {
        {
            name = 'ems_dispatch_pillbox',
            icon = 'fa-solid fa-headset',
            label = 'EMS Dispatch',
            onSelect = function()
                TriggerEvent('city_memory:openDispatch')
            end,
            canInteract = function()
                return IsEMSJob(GetPlayerJob())
            end
        }
    }
})

-- ================================================
-- Öffentliche Notruftelefone
-- ================================================

local phoneLocations = {
    vec3(232.28, -899.35, 30.09),   -- Legion Square
    vec3(-1037.97, -2733.82, 13.76), -- Flughafen
    vec3(1693.44, 4788.22, 41.99),   -- Grapeseed
    vec3(-379.53, 6118.32, 31.85),   -- Paleto Bay
    vec3(1960.17, 3740.48, 32.34),   -- Sandy Shores
}

for i, coords in ipairs(phoneLocations) do
    exports.ox_target:addBoxZone({
        coords = coords,
        size = vec3(1.0, 1.0, 2.0),
        rotation = 0,
        debug = Config.Debug,
        options = {
            {
                name = 'public_phone_' .. i,
                icon = 'fa-solid fa-phone',
                label = 'Notruf (911)',
                onSelect = function()
                    TriggerEvent('city_memory:openCallUI')
                end
            }
        }
    })
end

-- ================================================
-- Polizeifahrzeuge (MDT im Auto)
-- ================================================

local policeVehicles = {
    'police', 'police2', 'police3', 'police4',
    'policeb', 'policeold1', 'policeold2',
    'policet', 'sheriff', 'sheriff2',
    'fbi', 'fbi2', 'riot', 'riot2'
}

exports.ox_target:addGlobalVehicle({
    {
        name = 'vehicle_mdt',
        icon = 'fa-solid fa-laptop',
        label = 'Fahrzeug-MDT',
        onSelect = function(data)
            TriggerEvent('city_memory:openMDT')
        end,
        canInteract = function(entity, distance, coords, name, bone)
            if not IsPoliceJob(GetPlayerJob()) then return false end
            
            local model = GetEntityModel(entity)
            for _, veh in ipairs(policeVehicles) do
                if model == GetHashKey(veh) then
                    return true
                end
            end
            return false
        end
    },
    {
        name = 'vehicle_dispatch',
        icon = 'fa-solid fa-headset',
        label = 'Dispatch',
        onSelect = function(data)
            TriggerEvent('city_memory:openDispatch')
        end,
        canInteract = function(entity, distance, coords, name, bone)
            if not IsDispatcherJob(GetPlayerJob()) then return false end
            
            local model = GetEntityModel(entity)
            for _, veh in ipairs(policeVehicles) do
                if model == GetHashKey(veh) then
                    return true
                end
            end
            return false
        end
    }
})

-- ================================================
-- EMS Fahrzeuge
-- ================================================

local emsVehicles = {
    'ambulance', 'firetruk', 'lguard'
}

exports.ox_target:addGlobalVehicle({
    {
        name = 'ems_vehicle_dispatch',
        icon = 'fa-solid fa-headset',
        label = 'EMS Dispatch',
        onSelect = function(data)
            TriggerEvent('city_memory:openDispatch')
        end,
        canInteract = function(entity, distance, coords, name, bone)
            if not IsEMSJob(GetPlayerJob()) then return false end
            
            local model = GetEntityModel(entity)
            for _, veh in ipairs(emsVehicles) do
                if model == GetHashKey(veh) then
                    return true
                end
            end
            return false
        end
    }
})

-- ================================================
-- Helper Function
-- ================================================

function GetPlayerJob()
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
        return playerData.job.name
    end
    return nil
end

-- ================================================
-- Optional: Admin Computer (z.B. im Rathaus)
-- ================================================

if Config.Admin and Config.Admin.enabled then
    exports.ox_target:addBoxZone({
        coords = vec3(-544.16, -204.92, 38.22), -- Rathaus
        size = vec3(1.0, 1.0, 1.5),
        rotation = 0,
        debug = Config.Debug,
        options = {
            {
                name = 'admin_computer',
                icon = 'fa-solid fa-gear',
                label = 'Admin Dashboard',
                onSelect = function()
                    TriggerEvent('city_memory:openAdmin')
                end,
                canInteract = function()
                    local playerData = ESX.GetPlayerData()
                    return playerData and (playerData.group == 'admin' or playerData.group == 'superadmin')
                end
            }
        }
    })
end

print('^2[City Memory] ox_target Interaktionen geladen^7')
