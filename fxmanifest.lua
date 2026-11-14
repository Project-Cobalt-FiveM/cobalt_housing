fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_housing'
author 'Project Cobalt'
description 'Properties, starter apartments and the realtor property creator'
version '1.0.0'

dependencies {
    'cobalt_mysql',
    'ox_lib',
    'cobalt_core',
    'cobalt_inventory',
    'ox_target',
}

shared_script '@ox_lib/init.lua'

ox_libs { 'locale' }

server_scripts {
    '@cobalt_mysql/lib/MySQL.lua',
    '@cobalt_core/server/migrationgate.lua',
    'server/init.lua',
}

client_script 'client/init.lua'

ui_page '_nui/build/index.html'

files {
    'config.lua',
    'locales/*.json',
    'client/*.lua',
    'shared/*.lua',
    'data/shells.lua',
    '_nui/build/index.html',
    '_nui/build/assets/*',
}
