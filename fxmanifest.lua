fx_version 'cerulean'
game 'gta5'

name 'Lib'
description 'Sure (Lib)'
version '2.7.1'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/init.lua'
}

server_scripts {
	'server/init.lua'
}

client_scripts {
	'client/init.lua'
}

files {
	'init.lua',
	'shared/init.lua',
	'client/modules/**/*.lua',
	'shared/modules/**/*.lua',
	'library/**/*.lua',
	'web/lui/**/*'
}

dependencies {
	'ox_lib',
	'es_extended'
}
