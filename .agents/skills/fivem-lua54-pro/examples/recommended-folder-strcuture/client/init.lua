local config = require 'config.public.someConfigFile'
local functions = require 'shared.functions'

print(config.hello)

require 'client.modules.doSomeThing'