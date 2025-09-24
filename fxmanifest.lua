fx_version 'cerulean'
game 'gta5'

name 'Lib'
description 'Sure (Lib)'
version '1.2'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'@es_extended/imports.lua',
	'imports/shared.lua'
}

server_scripts {
	'resources/server/**/*.lua'
}

client_scripts {
	'resources/client/**/*.lua'
}

files {
	'modules/**/*.lua',
	'imports/shared.lua'
}

dependencies {
	'ox_lib',
	'es_extended'
}
