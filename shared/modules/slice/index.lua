local hook = require('@sure_lib.shared.modules.hook.index')
local logModule = require('@sure_lib.shared.modules.log.index')

local function buildState(initial, watchers)
  local data = {}
  if type(initial) == 'table' then
    for key, value in pairs(initial) do
      data[key] = value
    end
  end

  local proxy = {}

  setmetatable(proxy, {
    __index = function(_, key)
      return data[key]
    end,
    __newindex = function(_, key, value)
      local previous = data[key]
      if previous == value then
        return
      end

      data[key] = value

      local list = watchers[key]
      if list == nil then
        return
      end

      for _, handler in ipairs(list) do
        handler(value, previous)
      end
    end,
    __pairs = function()
      return pairs(data)
    end,
  })

  return proxy, data
end

local function appendWatcher(watchers, key, handler)
  local list = watchers[key]
  if list == nil then
    list = {}
    watchers[key] = list
  end

  list[#list + 1] = handler
end

local function prefix(name, eventName)
  return name .. ':' .. eventName
end

local function buildSlice(name, spec)
  if type(name) ~= 'string' or name == '' then
    error('[sure_lib][slice] name must be a non-empty string', 3)
  end

  if type(spec) ~= 'table' then
    error('[sure_lib][slice] spec must be a table', 3)
  end

  local watchers = {}
  local state, rawState = buildState(spec.state, watchers)

  local slice = {
    name = name,
    state = state,
    actions = {},
    log = logModule.create(name),
  }

  function slice:subscribe(key, handler)
    if type(key) ~= 'string' or type(handler) ~= 'function' then
      error('[sure_lib][slice] subscribe requires (key, handler)', 2)
    end

    appendWatcher(watchers, key, function(value, previous)
      handler(value, previous)
    end)

    return self
  end

  function slice:emit(eventName, ...)
    hook:dispatch(prefix(name, eventName), ...)
    return self
  end

  if IsDuplicityVersion() then
    function slice:emitClient(target, eventName, ...)
      hook:dispatchClient(target, prefix(name, eventName), ...)
      return self
    end
  else
    function slice:emitServer(eventName, ...)
      hook:dispatchServer(prefix(name, eventName), ...)
      return self
    end
  end

  function slice:snapshot()
    local copy = {}
    for key, value in pairs(rawState) do
      copy[key] = value
    end

    return copy
  end

  if type(spec.actions) == 'table' then
    for actionName, action in pairs(spec.actions) do
      if type(action) == 'function' then
        slice.actions[actionName] = function(...)
          return action(slice, ...)
        end
      end
    end
  end

  if type(spec.watch) == 'table' then
    for key, handler in pairs(spec.watch) do
      if type(handler) == 'function' then
        appendWatcher(watchers, key, function(value, previous)
          handler(slice, value, previous)
        end)
      end
    end
  end

  if type(spec.on) == 'table' then
    for eventName, handler in pairs(spec.on) do
      if type(handler) == 'function' then
        hook:on(prefix(name, eventName), function(...)
          return handler(slice, ...)
        end)
      end
    end
  end

  if type(spec.net) == 'table' then
    for eventName, handler in pairs(spec.net) do
      if type(handler) == 'function' then
        hook:onNet(prefix(name, eventName), function(...)
          return handler(slice, ...)
        end)
      end
    end
  end

  if type(spec.commands) == 'table' then
    for commandName, handler in pairs(spec.commands) do
      if type(handler) == 'function' then
        RegisterCommand(prefix(name, commandName), function(source, args, raw)
          return handler(slice, source, args, raw)
        end, false)
      end
    end
  end

  local resourceName = nil
  if type(_G.GetCurrentResourceName) == 'function' then
    local ok, value = pcall(GetCurrentResourceName)
    if ok then
      resourceName = value
    end
  end

  if type(spec.onLoad) == 'function' then
    AddEventHandler('onResourceStart', function(resource)
      if resourceName == nil or resource == resourceName then
        spec.onLoad(slice)
      end
    end)
  end

  if type(spec.onUnload) == 'function' then
    AddEventHandler('onResourceStop', function(resource)
      if resourceName == nil or resource == resourceName then
        spec.onUnload(slice)
      end
    end)
  end

  return slice
end

return setmetatable({}, {
  __call = function(_, name)
    return function(spec)
      return buildSlice(name, spec)
    end
  end,
})
