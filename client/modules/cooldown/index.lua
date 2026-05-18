--- @type SURELIB.COOLDOWN.STRUCT
local data = {}
local definitions = {}
local app = {}
local ESX = exports.es_extended:getSharedObject()
local pairs = pairs
local floor = math.floor
local ceil = math.ceil
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

--- @param key string
--- @param position vector3
--- @param remainingMs integer
RegisterNetEvent(cooldownSetEvent, function(key, position, remainingMs)
  local index = generateIndex(key, position)

  if data[key] == nil then
    data[key] = {}
  end

  data[key][index] = remainingMs
end)

--- @param key string
--- @param index string
--- @param remainingMs integer
RegisterNetEvent(cooldownSetByIndexEvent, function(key, index, remainingMs)
  if data[key] == nil then
    data[key] = {}
  end

  data[key][index] = remainingMs
end)

--- Returns the remaining cooldown for a key and position.
--- @param key string
--- @param position vector3
--- @return integer?
function app.getRemaining(key, position)
  local index = generateIndex(key, position)

  if data[key] == nil then
    data[key] = {}
  end

  if data[key][index] == nil then
    local remainingMs = lib.callback.await(cooldownGetOrInitCallback, false, key, position)
    if type(remainingMs) == 'number' then
      data[key][index] = remainingMs
    end
  end

  return data[key][index]
end

--- Starts or resets a cooldown.
--- @param key string
--- @param position vector3
--- @param durationMs integer?
function app.start(key, position, durationMs)
  TriggerServerEvent(cooldownSetEvent, key, position, durationMs)
end

--- @param callback function
function app.ready(callback)
  app.readyCallback = callback
end

--- @return SURELIB.COOLDOWN.STRUCT
function app.all()
  return data
end

--- @param key string
--- @param remainingMs integer
--- @return integer
local function decrementRemaining(key, remainingMs)
  local pauseTimerOn = definitions[key] and definitions[key].pauseTimerOn or nil
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

CreateThread(function()
  while not ESX.IsPlayerLoaded() do
    Wait(500)
  end

  local firstTimeSync = lib.callback.await(cooldownGetFirstTimeCallback, false) or {}
  data = firstTimeSync.data or firstTimeSync
  definitions = firstTimeSync.definitions or {}

  if type(app.readyCallback) == 'function' then
    app.readyCallback()
  end

  lib.print.info('type=readyCallback action=startTimer')

  lib.timer(1000, function(self)
    for key, list in pairs(data) do
      for index, remainingMs in pairs(list) do
        if remainingMs > 0 then
          data[key][index] = decrementRemaining(key, remainingMs)
        end
      end
    end

    self:restart(true)
  end, true)
end)

return app
