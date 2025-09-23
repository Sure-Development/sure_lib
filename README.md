# sure_lib

Open Source - Library that will help your manage your resource or handle your script as a controller
In this version (1.1.3) we are currently working on the new features.
and we don't have official documentation yet.

## Core Features
- Cooldown (Make all players in server receive same timer)
- Schema Validation

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)

## Autoloader
Aliases that can be called `ESX`, `Cooldown`, `Validator`
```lua
--- fxmanifest.lua
shared_script '@sure_lib/imports/shared.lua'
```

```lua
--- client.lua
local esx = GetModule('ESX')
local cooldown = GetModule('Cooldown')
local validator = GetModule('Validator')
local reactive = GetModule('Track')

esx.WaitPlayerLoaded()

print(cooldown.GET_COOLDOWN(namespace, coords))
print(validator.string().parse('hello'))

--- Reactive System
local d, setD = reactive.Track('d', 500)

reactive.Effect(function()
	print('d has updated to', d())
end, { d })

print('Initial d is', d()) --- Initial d is 500
setD(600) --- d has updated to 600
```

## Basic Usage (Cooldown)

```lua
--- server.lua
local lLib = GetModule('Cooldown')

lLib.SETUP_INITIAL_DATA(
	--[[ namespace ]]                                    'your_namespace_like_robbery',
	--[[ initial cooldown (ms) ]]                        5000,
	--[[ after set or reset cooldown (ms) ]]             10000,
	--[[ stack on zero to reset cooldown (optional) ]]   12
)
```

```lua
--- client.lua
local lLib = GetModule('Cooldown')
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

## Basic Usage (Schema Validation)

```lua
local v = GetModule('Validator')

local testSchema = v.object({
    second = v.object({
        third = v.object({
            fourth = v.string().required()
        })
    })
})
local testData = {
    second = {
        third = {
            fourth = 'string'
        }
    }
}

local success, message = pcall(function()
    testSchema.parse(testData)
end)

if success then
    print('Validation successful!')
else
    print('Validation failed:', message)
end
```
