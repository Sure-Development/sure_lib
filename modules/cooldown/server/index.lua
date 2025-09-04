--- @type table<string, table<string, integer>>
local data = {}
--- @type table<string, table<string, any>>
local initialData = {}
local app = {}
local stackZero = {}

--- @param namespace string
--- @param coords vector3
--- @return string
local function generateIndex(namespace, coords)
	return ('%s_%s:%s:%s'):format(namespace, coords.x, coords.y, coords.z)
end

lib.callback.register(('%s:lib:cooldownGetFirstTime'):format(cache.resource), function()
	return data
end)

--- @param namespace string
--- @param coords vector3
lib.callback.register(('%s:lib:cooldownGetOrInit'):format(cache.resource), function(_, namespace, coords)
	if initialData[namespace] == nil then
		lib.print.error(('Namespace %s does not have initial data'):format(namespace))
		return nil
	end

	local index = generateIndex(namespace, coords)
	if data[namespace][index] == nil then
		data[namespace][index] = initialData[namespace].initialCooldown
	end

	return data[namespace][index]
end)

--- @param namespace string
--- @param coords vector3
--- @param cooldown integer?
RegisterNetEvent(('%s:lib:cooldownSet'):format(cache.resource), function(namespace, coords, cooldown)
	if initialData[namespace] == nil then
		lib.print.error(('Namespace %s does not have initial data'):format(namespace))
		return
	end

	if cooldown == nil then
		cooldown = initialData[namespace].afterSetCooldown
	end

	local index = generateIndex(namespace, coords)
	data[namespace][index] = cooldown

	TriggerClientEvent(('%s:lib:cooldownSet'):format(cache.resource), -1, namespace, coords, cooldown)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == cache.resource then
		lib.print.info('ev=onResourceStart action=startTimer')

		lib.timer(1000, function(self)
			for namespace, list in pairs(data) do
				for index, cooldown in pairs(list) do
					if cooldown > 0 then
						data[namespace][index] -= 1000
						stackZero[namespace][index] = 0

						if data[namespace][index] < 0 then
							data[namespace][index] = 0
						end
					elseif cooldown == 0 then
						if
								initialData[namespace].stackOnZeroToRemove ~= nil
								and stackZero[namespace][index] == initialData[namespace].stackOnZeroToRemove
						then
							stackZero[namespace][index] = 0
							data[namespace][index] = initialData[namespace].afterSetCooldown
							TriggerClientEvent(('%s:lib:cooldownSetByIndex'):format(cache.resource), -1, namespace, index,
								data[namespace][index])
						end

						stackZero[namespace][index] += 1
					end
				end
			end

			self:restart(true)
		end, true)
	end
end)

--- @param namespace string
--- @param initialCooldown number
function app.SETUP_INITIAL_DATA(namespace, initialCooldown, afterSetCooldown, stackOnZeroToRemove)
	lib.print.info(('Set initial data namespace=%s'):format(namespace))

	initialData[namespace] = {
		initialCooldown = initialCooldown,
		afterSetCooldown = afterSetCooldown,
		stackOnZeroToRemove = stackOnZeroToRemove
	}

	data[namespace] = {}
	stackZero[namespace] = {}
end

return app
