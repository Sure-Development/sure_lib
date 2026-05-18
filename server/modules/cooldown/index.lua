--- @alias SURELIB.COOLDOWN.STRUCT table<string, table<string, any>>
--- @type SURELIB.COOLDOWN.STRUCT
local data = {}
--- @type SURELIB.COOLDOWN.STRUCT
local initialData = {}
local app = {}
--- @type SURELIB.COOLDOWN.STRUCT
local stackZero = {}
local pairs = pairs
local floor = math.floor
local ceil = math.ceil
local timerStarted = false
local cooldownSetEvent = ('%s:lib:cooldownSet'):format(cache.resource)
local cooldownSetByIndexEvent = ('%s:lib:cooldownSetByIndex'):format(cache.resource)
local cooldownGetFirstTimeCallback = ('%s:lib:cooldownGetFirstTime'):format(cache.resource)
local cooldownGetOrInitCallback = ('%s:lib:cooldownGetOrInit'):format(cache.resource)

--- @param value number
--- @return number
local function roundCoordinate(value)
  local scaled = value * 100
  if scaled >= 0 then
    return floor(scaled + 0.5) / 100
  end

  return ceil(scaled - 0.5) / 100
end

--- @param key string
--- @param position vector3
--- @return string
local function generateIndex(key, position)
  return ('%s_%.2f:%.2f:%.2f'):format(key, roundCoordinate(position.x), roundCoordinate(position.y), roundCoordinate(position.z))
end

lib.callback.register(cooldownGetFirstTimeCallback, function()
  return {
    data = data,
    definitions = initialData,
  }
end)

--- @param key string
--- @param position vector3
lib.callback.register(cooldownGetOrInitCallback, function(_, key, position)
  if initialData[key] == nil then
    lib.print.error(('Cooldown key %s does not have initial data'):format(key))
    return nil
  end

  local index = generateIndex(key, position)
  if data[key][index] == nil then
    data[key][index] = initialData[key].initialDurationMs
  end

  return data[key][index]
end)

--- @param key string
--- @param position vector3
--- @param durationMs integer?
RegisterNetEvent(cooldownSetEvent, function(key, position, durationMs)
  if initialData[key] == nil then
    lib.print.error(('Cooldown key %s does not have initial data'):format(key))
    return
  end

  if durationMs == nil then
    durationMs = initialData[key].durationMs
  end

  local index = generateIndex(key, position)
  data[key][index] = durationMs

  TriggerClientEvent(cooldownSetEvent, -1, key, position, durationMs)
end)

--- @param key string
--- @param remainingMs integer
--- @return integer
local function decrementRemaining(key, remainingMs)
  local pauseTimerOn = initialData[key] and initialData[key].pauseTimerOn or nil
  if pauseTimerOn ~= nil then
    if remainingMs == pauseTimerOn then
      return remainingMs
    end

    if remainingMs > pauseTimerOn and remainingMs - 1000 <= pauseTimerOn then
      return pauseTimerOn
    end
  end

  local nextRemainingMs = remainingMs - 1000
  if nextRemainingMs < 0 then
    return 0
  end

  return nextRemainingMs
end

local function startTimer()
  if timerStarted then
    return
  end

  timerStarted = true
  lib.print.info('action=startCooldownTimer')

  lib.timer(1000, function(self)
    for key, list in pairs(data) do
      for index, remainingMs in pairs(list) do
        if remainingMs > 0 then
          data[key][index] = decrementRemaining(key, remainingMs)
          stackZero[key][index] = 0
        elseif remainingMs == 0 then
          local zeroStack = stackZero[key][index] or 0
          if initialData[key].resetAfterZeroTicks ~= nil and zeroStack == initialData[key].resetAfterZeroTicks then
            stackZero[key][index] = 0
            data[key][index] = initialData[key].durationMs
            TriggerClientEvent(cooldownSetByIndexEvent, -1, key, index, data[key][index])
          else
            stackZero[key][index] = zeroStack + 1
          end
        end
      end
    end

    self:restart(true)
  end, true)
end

--- @class SURELIB.COOLDOWN.DEFINITION
--- @field initialDurationMs integer
--- @field durationMs integer
--- @field pauseTimerOn integer? Millisecond value where countdown pauses until externally changed.
--- @field resetAfterZeroTicks integer?

--- @param key string
--- @param definition SURELIB.COOLDOWN.DEFINITION
function app.define(key, definition)
  lib.print.info(('Set cooldown key=%s'):format(key))

  initialData[key] = {
    initialDurationMs = definition.initialDurationMs,
    durationMs = definition.durationMs,
    pauseTimerOn = definition.pauseTimerOn,
    resetAfterZeroTicks = definition.resetAfterZeroTicks,
  }

  data[key] = {}
  stackZero[key] = {}
end

startTimer()

return app
