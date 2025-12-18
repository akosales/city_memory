fx_version 'cerulean'
game 'gta5'

name 'city_memory'
description 'Persistentes Stadt-Gedächtnis, Dispatch & MDT System für ESX'
author 'GrandRP Dev Team'
version '2.1.0'

lua54 'yes'

-- Dependencies
dependencies {
    'es_extended',
    'ox_lib',       -- Für Radial Menu & Notifications
    'ox_target',    -- Für Interaktionen an Objekten (optional aber empfohlen)
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/dispatch.css',
    'html/css/mdt.css',
    'html/css/heatmap.css',
    'html/js/dispatch.js',
    'html/js/mdt.js',
    'html/js/heatmap.js'
}

shared_scripts {
    '@ox_lib/init.lua',  -- ox_lib Initialisierung
    'shared/config.lua',
    'shared/utils.lua',
    'shared/zones.lua'
}

server_scripts {
    'server/pg.lua',
    'server/main.lua',
    'server/sv_zones.lua',
    'server/sv_profiles.lua',
    'server/sv_vehicles.lua',
    'server/sv_decay.lua',
    'server/sv_police.lua',
    'server/sv_dispatch.lua',
    'server/sv_mdt.lua'
}

client_scripts {
    'client/cl_menu.lua',       -- NEU: Zentrales Menü (ox_lib)
    'client/cl_target.lua',     -- NEU: ox_target Interaktionen
    'client/cl_effects.lua',
    'client/cl_feedback.lua',
    'client/cl_dispatch.lua',
    'client/cl_mdt.lua',
    'client/cl_zonemap.lua'
}
