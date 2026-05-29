--- @alias SURELIB.COOLDOWN.STRUCT table<string, table<string, any>>
--- @type SURELIB.COOLDOWN.STRUCT
local data = {}
--- @type SURELIB.COOLDOWN.STRUCT
local dataById = {}
--- @type SURELIB.COOLDOWN.STRUCT
local initialData = {}
local app = {}
--- @type SURELIB.COOLDOWN.STRUCT
local stackZero = {}
--- @type SURELIB.COOLDOWN.STRUCT
local stackZeroById = {}
local pairs = pairs
local floor = math.floor
local ceil = math.ceil
local timerStarted = false
local cooldownSetEvent = ('%s:lib:cooldownSet'):format(cache.resource)
local cooldownSetByIndexEvent = ('%s:lib:cooldownSetByIndex'):format(cache.resource)
local cooldownGetFirstTimeCallback = ('%s:lib:cooldownGetFirstTime'):format(cache.resource)
local cooldownGetOrInitCallback = ('%s:lib:cooldownGetOrInit'):format(cache.resource)
local cooldownSetByIdEvent = ('%s:lib:cooldownSetById'):format(cache.resource)
local cooldownGetOrInitByIdCallback = ('%s:lib:cooldownGetOrInitById'):format(cache.resource)

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

local function ensureKey(key)
  if data[key] == nil then
    data[key] = {}
  end
  if stackZero[key] == nil then
    stackZero[key] = {}
  end
  if dataById[key] == nil then
    dataById[key] = {}
  end
  if stackZeroById[key] == nil then
    stackZeroById[key] = {}
  end
end

lib.callback.register(cooldownGetFirstTimeCallback, function()
  return {
    data = data,
    dataById = dataById,
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
--- @param identifier string|integer
lib.callback.register(cooldownGetOrInitByIdCallback, function(_, key, identifier)
  if initialData[key] == nil then
    lib.print.error(('Cooldown key %s does not have initial data'):format(key))
    return nil
  end

  if dataById[key][identifier] == nil then
    dataById[key][identifier] = initialData[key].initialDurationMs
  end

  return dataById[key][identifier]
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
--- @param identifier string|integer
--- @param durationMs integer?
RegisterNetEvent(cooldownSetByIdEvent, function(key, identifier, durationMs)
  if initialData[key] == nil then
    lib.print.error(('Cooldown key %s does not have initial data'):format(key))
    return
  end

  if durationMs == nil then
    durationMs = initialData[key].durationMs
  end

  dataById[key][identifier] = durationMs

  TriggerClientEvent(cooldownSetByIdEvent, -1, key, identifier, durationMs)
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

local function tickBucket(bucket, zeroBucket, setterEvent, key)
  for index, remainingMs in pairs(bucket) do
    if remainingMs > 0 then
      bucket[index] = decrementRemaining(key, remainingMs)
      zeroBucket[index] = 0
    elseif remainingMs == 0 then
      local zeroStack = zeroBucket[index] or 0
      if initialData[key].resetAfterZeroTicks ~= nil and zeroStack == initialData[key].resetAfterZeroTicks then
        zeroBucket[index] = 0
        bucket[index] = initialData[key].durationMs
        TriggerClientEvent(setterEvent, -1, key, index, bucket[index])
      else
        zeroBucket[index] = zeroStack + 1
      end
    end
  end
end

local function startTimer()
  if timerStarted then
    return
  end

  timerStarted = true
  lib.print.info('action=startCooldownTimer')

  lib.timer(1000, function(self)
    for key, list in pairs(data) do
      tickBucket(list, stackZero[key], cooldownSetByIndexEvent, key)
    end

    for key, list in pairs(dataById) do
      tickBucket(list, stackZeroById[key], cooldownSetByIdEvent, key)
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

  ensureKey(key)
end

--- Server-driven set for the identifier-scoped cooldown.
--- @param key string
--- @param identifier string|integer
--- @param durationMs integer?
function app.startById(key, identifier, durationMs)
  if initialData[key] == nil then
    lib.print.error(('Cooldown key %s does not have initial data'):format(key))
    return
  end

  ensureKey(key)
  dataById[key][identifier] = durationMs or initialData[key].durationMs
  TriggerClientEvent(cooldownSetByIdEvent, -1, key, identifier, dataById[key][identifier])
end

--- @param key string
--- @param identifier string|integer
--- @return integer?
function app.getRemainingById(key, identifier)
  if dataById[key] == nil then
    return nil
  end

  return dataById[key][identifier]
end

startTimer()

return app
