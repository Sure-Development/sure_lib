local app = {}
local watchersByState = {}
local nextWatcherId = 0
local clone = lib.table.deepclone
local ipairs = ipairs
local pairs = pairs
local type = type

local function copyValue(value)
  if type(value) == 'table' then
    return clone(value)
  end

  return value
end

local function notify(stateName)
  local watchers = watchersByState[stateName]
  if watchers == nil then
    return
  end

  local snapshot = {}
  for id, callback in pairs(watchers) do
    snapshot[id] = callback
  end

  for _, callback in pairs(snapshot) do
    if type(callback) == 'function' then
      callback()
    end
  end
end

--- @param stateName string
--- @param initialValue any
--- @return SureTrackGetter, fun(newValue: any|fun(currentValue: any): any)
function app.state(stateName, initialValue)
  local data = copyValue(initialValue)

  local getter = {}

  local setter = function(newValue)
    if type(newValue) == 'function' then
      newValue = newValue(copyValue(data))
    end

    if newValue ~= data then
      data = copyValue(newValue)
      notify(stateName)
    end
  end

  setmetatable(getter, {
    __index = {
      isReactive = true,
      stateName = stateName,
    },

    __call = function()
      return copyValue(data)
    end,
  })

  return getter, setter
end

--- @param callback fun()
--- @param dependencies SureTrackGetter[]
--- @return fun() dispose
function app.effect(callback, dependencies)
  nextWatcherId = nextWatcherId + 1
  local id = nextWatcherId
  local boundStates = {}

  for _, dep in ipairs(dependencies or {}) do
    local stateName = dep and dep.stateName
    if stateName then
      if watchersByState[stateName] == nil then
        watchersByState[stateName] = {}
      end

      watchersByState[stateName][id] = callback
      boundStates[#boundStates + 1] = stateName
    end
  end

  return function()
    for _, stateName in ipairs(boundStates) do
      local watchers = watchersByState[stateName]
      if watchers ~= nil then
        watchers[id] = nil
      end
    end
  end
end

--- @param stateName string
--- @param compute fun(): any
--- @param dependencies SureTrackGetter[]
--- @return SureTrackGetter
function app.computed(stateName, compute, dependencies)
  local getter, setter = app.state(stateName, compute())
  app.effect(function()
    setter(compute())
  end, dependencies)

  return getter
end

return app
