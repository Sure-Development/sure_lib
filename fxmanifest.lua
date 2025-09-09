fx_version 'cerulean'
game 'gta5'

name 'Lib'
description 'Sure (Lib)'
version '1.1.0-alpha'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

files {
	--- Cooldown
	'modules/cooldown/client/index.lua',
	'modules/cooldown/server/index.lua',

	--- Validator
	'modules/validator/shared/index.lua'
}

dependencies {
	'ox_lib',
	'es_extended'
}
