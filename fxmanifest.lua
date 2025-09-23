fx_version 'cerulean'
game 'gta5'

name 'Lib'
description 'Sure (Lib)'
version '1.2'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

server_scripts {
	'resources/server/**/*.lua'
}

files {
	'modules/**/*/index.lua',
	'imports/shared.lua'
}

dependencies {
	'ox_lib',
	'es_extended'
}
