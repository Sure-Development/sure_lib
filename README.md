# sure_lib

Open Source - Library that will help your manage your resource or handle your script as a controller
In this version (1.0.0-alpha) we are currently working on the new features.
and we don't have official documentation yet.

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)

## Basic Usage

```lua
--- server.lua
local lLib = require '@sure_lib/modules/cooldown/server/index'

lLib.SETUP_INITIAL_DATA(
	--[[ namespace ]]                                    'your_namespace_like_robbery',
	--[[ initial cooldown (ms) ]]                        5000,
	--[[ after set or reset cooldown (ms) ]]             10000,
	--[[ stack on zero to reset cooldown (optional) ]]   12
)
```

```lua
--- client.lua
local lLib = require '@sure_lib/modules/cooldown/client/index'
local namespace = 'your_namespace_like_robbery'

lLib.ON_READY(function()
	local coords = vec3(0.0, 0.0, 0.0)

	while true do
		Wait(1000)
		local cooldown = lLib.GET_COOLDOWN(namespace, coords)
		print('Cooldown is', cooldown)

		if cooldown == 0 then
			print('This is a zero then wait 2 seconds to reset cooldown')
			Wait(2000)
			lLib.SET_COOLDOWN(namespace, coords)
		end
	end
end)
```
