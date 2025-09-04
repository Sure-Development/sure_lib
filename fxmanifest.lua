fx_version 'cerulean'
game 'gta5'

name 'Lib'
description 'Sure (Lib)'
version '1.0.0'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependecies {
	'ox_lib',
	'es_extended'
}

files {
	--- Cooldown
	'modules/cooldown/client/index.lua',
	'modules/cooldown/server/index.lua',
}
