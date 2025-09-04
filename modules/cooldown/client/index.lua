--- @type table<string, table<string, integer>>
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

--- @param namespace string
--- @param coords vector3
--- @return integer
function app.GET_COOLDOWN(namespace, coords)
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

--- @param namespace string
--- @param coords vector3
--- @param cooldown integer?
function app.SET_COOLDOWN(namespace, coords, cooldown)
	TriggerServerEvent(('%s:lib:cooldownSet'):format(cache.resource), namespace, coords, cooldown)
end

--- @param cb fun()
function app.ON_READY(cb)
	app.on_ready_cb = cb
end

function app.GET_DATA()
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
