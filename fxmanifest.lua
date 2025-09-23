fx_version 'cerulean'
game 'gta5'

name 'Lib'
description 'Sure (Lib)'
version '1.1.3'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

files {
	--- Cooldown
	'modules/cooldown/client/index.lua',
	'modules/cooldown/server/index.lua',

	--- Validator
	'modules/validator/shared/index.lua',

	--- ESX
	'modules/esx/client/index.lua',

	--- Track
	'modules/track/shared/index.lua',

	'imports/shared.lua'
}

dependencies {
	'ox_lib',
	'es_extended'
}
