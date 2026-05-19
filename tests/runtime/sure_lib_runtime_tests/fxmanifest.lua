fx_version 'cerulean'
game 'gta5'

name 'sure_lib_runtime_tests'
description 'Runtime integration tests for sure_lib in a real FiveM environment'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
  '@ox_lib/init.lua',
  '@sure_lib/init.lua'
}

server_scripts {
  'shared/runner.lua',
  'server/main.lua'
}

client_scripts {
  'shared/runner.lua',
  'client/main.lua'
}

files {
  'config/runtime.lua'
}

dependencies {
  'ox_lib',
  'sure_lib',
  'es_extended'
}
