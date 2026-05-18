fx_version 'cerulean'
game 'gta5'

name 'Resource Name'
description 'Resource Description'
version '0.0.1'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua'
}

client_scripts {
    'client/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', --- If server needed
    'server/init.lua'
}

ui_page 'interface/index.html' --- If resource has NUI
files {
    'client/**/*.lua',
    'shared/**/*.lua',
    'interface/index.html', --- If resource has NUI
    'interface/**/*' --- If resource has NUI
}