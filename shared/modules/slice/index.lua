local hook = require('@sure_lib.shared.modules.hook.index')
local logModule = require('@sure_lib.shared.modules.log.index')

local function deepClone(value)
  if type(value) ~= 'table' then
    return value
  end

  local cloned = {}
  for key, item in pairs(value) do
    cloned[key] = deepClone(item)
  end

  return cloned
end

local function deepEqual(a, b)
  if a == b then
    return true
  end

  if type(a) ~= 'table' or type(b) ~= 'table' then
    return false
  end

  for key, value in pairs(a) do
    if not deepEqual(value, b[key]) then
      return false
    end
  end

  for key in pairs(b) do
    if a[key] == nil then
      return false
    end
  end

  return true
end

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
  local emitNameCache = {}
  local refDisposers = {}

  local function resolveEventName(eventName)
    local cached = emitNameCache[eventName]
    if cached == nil then
      cached = name .. ':' .. eventName
      emitNameCache[eventName] = cached
    end

    return cached
  end

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

    appendWatcher(watchers, key, handler)
    return self
  end

  function slice:emit(eventName, ...)
    hook:dispatch(resolveEventName(eventName), ...)
    return self
  end

  if IsDuplicityVersion() then
    function slice:emitClient(target, eventName, ...)
      hook:dispatchClient(target, resolveEventName(eventName), ...)
      return self
    end
  else
    function slice:emitServer(eventName, ...)
      hook:dispatchServer(resolveEventName(eventName), ...)
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

  function slice:unmount(stateKey, itemKey)
    if type(stateKey) ~= 'string' or stateKey == '' then
      error('[sure_lib][slice] unmount: stateKey must be a non-empty string', 2)
    end

    if itemKey == nil then
      error('[sure_lib][slice] unmount: itemKey is required', 2)
    end

    local list = rawState[stateKey]
    if type(list) ~= 'table' then
      return self
    end

    local filtered = {}
    local removed = false
    for _, item in ipairs(list) do
      if type(item) == 'table' and item.key == itemKey then
        removed = true
      else
        filtered[#filtered + 1] = item
      end
    end

    if removed then
      state[stateKey] = filtered
    end

    return self
  end

  function slice:ref(stateKey, handler)
    if type(stateKey) ~= 'string' or stateKey == '' then
      error('[sure_lib][slice] ref: stateKey must be a non-empty string', 2)
    end

    if type(handler) ~= 'function' then
      error('[sure_lib][slice] ref: handler must be a function', 2)
    end

    local cleanups = {}
    local snapshots = {}
    local disposed = false

    local function unmount(itemKey)
      local cleanup = cleanups[itemKey]
      cleanups[itemKey] = nil
      snapshots[itemKey] = nil
      if type(cleanup) == 'function' then
        local ok, err = pcall(cleanup)
        if not ok then
          slice.log.error(('ref cleanup for %s failed: %s'):format(tostring(itemKey), tostring(err)))
        end
      end
    end

    local function mount(item, index)
      local ok, result = pcall(handler, item, index)
      if not ok then
        slice.log.error(('ref handler for %s failed: %s'):format(tostring(item.key), tostring(result)))
        return
      end

      if type(result) == 'function' then
        cleanups[item.key] = result
      end

      snapshots[item.key] = deepClone(item)
    end

    local function reconcile(list)
      if disposed then
        return
      end

      if list == nil then
        for itemKey in pairs(snapshots) do
          unmount(itemKey)
        end
        return
      end

      if type(list) ~= 'table' then
        error(('[sure_lib][slice] ref: state.%s must be a table or nil'):format(stateKey), 2)
      end

      local seen = {}

      for index, item in ipairs(list) do
        if type(item) ~= 'table' then
          error(('[sure_lib][slice] ref(%s): item #%d is not a table'):format(stateKey, index), 2)
        end

        local itemKey = item.key
        if itemKey == nil then
          error(('[sure_lib][slice] ref(%s): item #%d missing required field "key"'):format(stateKey, index), 2)
        end

        if seen[itemKey] then
          error(('[sure_lib][slice] ref(%s): duplicate key %s'):format(stateKey, tostring(itemKey)), 2)
        end

        seen[itemKey] = true
      end

      for itemKey in pairs(snapshots) do
        if seen[itemKey] == nil then
          unmount(itemKey)
        end
      end

      for index, item in ipairs(list) do
        local previousSnapshot = snapshots[item.key]

        if previousSnapshot == nil then
          mount(item, index)
        elseif not deepEqual(previousSnapshot, item) then
          unmount(item.key)
          mount(item, index)
        end
      end
    end

    reconcile(rawState[stateKey])

    appendWatcher(watchers, stateKey, function(value)
      reconcile(value)
    end)

    local function dispose()
      if disposed then
        return
      end

      disposed = true
      for itemKey in pairs(snapshots) do
        unmount(itemKey)
      end
    end

    refDisposers[#refDisposers + 1] = dispose
    return dispose
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

  AddEventHandler('onResourceStop', function(resource)
    if resourceName ~= nil and resource ~= resourceName then
      return
    end

    if type(spec.onUnload) == 'function' then
      local ok, err = pcall(spec.onUnload, slice)
      if not ok then
        slice.log.error(('onUnload failed: %s'):format(tostring(err)))
      end
    end

    for index = #refDisposers, 1, -1 do
      local dispose = refDisposers[index]
      refDisposers[index] = nil
      local ok, err = pcall(dispose)
      if not ok then
        slice.log.error(('ref dispose failed: %s'):format(tostring(err)))
      end
    end
  end)

  return slice
end

return setmetatable({}, {
  __call = function(_, name)
    return function(spec)
      return buildSlice(name, spec)
    end
  end,
})
