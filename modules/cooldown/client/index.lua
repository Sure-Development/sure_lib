--- @type SURELIB.COOLDOWN.STRUCT
local data = {}
local app = {}

--- @param namespace string
--- @param coords vector3
--- @return string
local function generateIndex(namespace, coords)
	return ('%s_%s:%s:%s'):format(namespace, coords.x, coords.y, coords.z)
end

--- @param namespace string
--- @param coords vector3
--- @param cooldown integer
RegisterNetEvent(('%s:lib:cooldownSet'):format(cache.resource), function(namespace, coords, cooldown)
	local index = generateIndex(namespace, coords)

	if data[namespace] == nil then
		data[namespace] = {}
	end

	data[namespace][index] = cooldown
end)

--- @param namespace string
--- @param index string
--- @param cooldown integer
RegisterNetEvent(('%s:lib:cooldownSetByIndex'):format(cache.resource), function(namespace, index, cooldown)
	if data[namespace] == nil then
		data[namespace] = {}
	end

	data[namespace][index] = cooldown
end)

--- Returns the cooldown value for a specific namespace and coordinates
--- @description Retrieves or initializes a cooldown value for a given namespace and location
--- @param namespace string The namespace identifier for the cooldown
--- @param coords vector3 The coordinates where the cooldown is applied
--- @return integer The current cooldown value for the specified namespace and coordinates
--- @note If the cooldown doesn't exist, it will be initialized through a server callback
function app.GetCooldown(namespace, coords)
	local index = generateIndex(namespace, coords)

	if data[namespace] == nil then
		data[namespace] = {}
	end

	if data[namespace][index] == nil then
		local cooldown = lib.callback.await(('%s:lib:cooldownGetOrInit'):format(cache.resource), false, namespace, coords)
		if type(cooldown) == 'number' then
			data[namespace][index] = cooldown
		end
	end

	return data[namespace][index]
end

--- Sets a cooldown timer for a specific location
--- @param namespace string The unique identifier for this cooldown
--- @param coords vector3 The coordinates where the cooldown will be applied
--- @param cooldown integer? Optional duration of the cooldown in milliseconds
function app.SetCooldown(namespace, coords, cooldown)
	TriggerServerEvent(('%s:lib:cooldownSet'):format(cache.resource), namespace, coords, cooldown)
end

--- OnReady sets a callback function to be executed when the application is ready
--- Use this to initialize components that require the application to be fully loaded
--- @param cb function The callback function to execute when ready
function app.OnReady(cb)
	app.on_ready_cb = cb
end

--- Gets the cooldown data structure.
--- This function returns the internal cooldown data containing all active cooldowns and their states.
--- @return SURELIB.COOLDOWN.STRUCT # The current cooldown data structure
function app.GetData()
	return data
end

CreateThread(function()
	while not ESX.IsPlayerLoaded() do
		Wait(500)
	end

	data = lib.callback.await(('%s:lib:cooldownGetFirstTime'):format(cache.resource), false)

	if type(app.on_ready_cb) == 'function' then
		app.on_ready_cb()

		lib.print.info('type=on_ready_cb action=startTimer')

		lib.timer(1000, function(self)
			for namespace, list in pairs(data) do
				for index, cooldown in pairs(list) do
					if cooldown > 0 then
						data[namespace][index] -= 1000

						if data[namespace][index] < 0 then
							data[namespace][index] = 0
						end
					end
				end
			end

			self:restart(true)
		end, true)
	end
end)

return app
