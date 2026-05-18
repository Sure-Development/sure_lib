local app = {}
local watchers = {}
local watcherIdsByState = {}
local clone = lib.table.deepclone
local ipairs = ipairs
local type = type

--- @param stateName string
--- @param initialValue any
--- @return any, fun(newValue: any)
function app.state(stateName, initialValue)
  local data = nil
  if type(initialValue) == 'table' then
    data = clone(initialValue)
  else
    data = initialValue
  end

  local getter = {}

  local setter = function(newValue)
    if newValue ~= data then
      if type(newValue) == 'table' then
        data = clone(newValue)
      else
        data = newValue
      end

      local watcherIds = watcherIdsByState[stateName]
      if watcherIds then
        for _, id in ipairs(watcherIds) do
          local watcher = watchers[id]
          if watcher and type(watcher.callback) == 'function' then
            watcher.callback()
          end
        end
      end
    end
  end

  local meta = {
    __index = {
      isReactive = true,
      stateName = stateName,
    },

    __call = function()
      return data
    end,
  }

  setmetatable(getter, meta)

  return getter, setter
end

--- @param callback fun()
--- @param dependencies any[]
function app.effect(callback, dependencies)
  local index = #watchers + 1
  watchers[index] = {
    callback = callback,
    deps = dependencies,
  }

  for _, dep in ipairs(dependencies or {}) do
    local stateName = dep and dep.stateName
    if stateName then
      local watcherIds = watcherIdsByState[stateName]
      if watcherIds == nil then
        watcherIds = {}
        watcherIdsByState[stateName] = watcherIds
      end

      watcherIds[#watcherIds + 1] = index
    end
  end
end

return app
