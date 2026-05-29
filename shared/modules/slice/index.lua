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

local function isKeyedArray(value)
  if type(value) ~= 'table' then
    return false
  end

  for key, item in pairs(value) do
    if type(key) ~= 'number' then
      return false
    end
    if type(item) ~= 'table' or item.key == nil then
      return false
    end
  end

  return true
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

local function buildState(initial, watchers, txContext)
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

      if txContext.depth > 0 then
        if not txContext.touched[key] then
          txContext.touched[key] = true
          txContext.originals[key] = previous
        end
        return
      end

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

local function diffKeyedArray(previous, current)
  local previousByKey = {}
  if type(previous) == 'table' then
    for _, item in ipairs(previous) do
      previousByKey[item.key] = item
    end
  end

  local currentByKey = {}
  if type(current) == 'table' then
    for _, item in ipairs(current) do
      currentByKey[item.key] = item
    end
  end

  local added = {}
  local removed = {}
  local changed = {}

  for key, item in pairs(currentByKey) do
    local before = previousByKey[key]
    if before == nil then
      added[#added + 1] = item
    elseif not deepEqual(before, item) then
      changed[#changed + 1] = item
    end
  end

  for key in pairs(previousByKey) do
    if currentByKey[key] == nil then
      removed[#removed + 1] = key
    end
  end

  if #added == 0 and #removed == 0 and #changed == 0 then
    return nil
  end

  return { added = added, removed = removed, changed = changed }
end

local function applyKeyedPatch(current, patch)
  local byKey = {}
  if type(current) == 'table' then
    for _, item in ipairs(current) do
      byKey[item.key] = item
    end
  end

  if type(patch.removed) == 'table' then
    for _, key in ipairs(patch.removed) do
      byKey[key] = nil
    end
  end

  if type(patch.changed) == 'table' then
    for _, item in ipairs(patch.changed) do
      byKey[item.key] = item
    end
  end

  if type(patch.added) == 'table' then
    for _, item in ipairs(patch.added) do
      byKey[item.key] = item
    end
  end

  local out = {}
  for _, item in pairs(byKey) do
    out[#out + 1] = item
  end

  return out
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
  local txContext = { depth = 0, touched = {}, originals = {} }
  local state, rawState = buildState(spec.state, watchers, txContext)
  local emitNameCache = {}
  local refDisposers = {}
  local stopped = false
  local scopes = {}
  local isServer = IsDuplicityVersion() == true

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

  function slice:transaction(fn)
    if type(fn) ~= 'function' then
      error('[sure_lib][slice] transaction requires a function', 2)
    end

    txContext.depth = txContext.depth + 1
    local ok, err = pcall(fn, self)
    txContext.depth = txContext.depth - 1

    if txContext.depth == 0 then
      local touched = txContext.touched
      local originals = txContext.originals
      txContext.touched = {}
      txContext.originals = {}

      for key in pairs(touched) do
        local current = rawState[key]
        local previous = originals[key]
        if current ~= previous then
          local list = watchers[key]
          if list ~= nil then
            for _, handler in ipairs(list) do
              local watcherOk, watcherErr = pcall(handler, current, previous)
              if not watcherOk then
                slice.log.error(('transaction watcher for %s failed: %s'):format(key, tostring(watcherErr)))
              end
            end
          end
        end
      end
    end

    if not ok then
      error(err, 2)
    end

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

  function slice:push(stateKey, item)
    if type(stateKey) ~= 'string' or stateKey == '' then
      error('[sure_lib][slice] push: stateKey must be a non-empty string', 2)
    end

    if type(item) ~= 'table' then
      error('[sure_lib][slice] push: item must be a table', 2)
    end

    local list = rawState[stateKey]
    local next = {}
    if type(list) == 'table' then
      for index, existing in ipairs(list) do
        next[index] = existing
      end
    end

    next[#next + 1] = item
    state[stateKey] = next

    return self
  end

  function slice:patch(stateKey, itemKey, partial)
    if type(stateKey) ~= 'string' or stateKey == '' then
      error('[sure_lib][slice] patch: stateKey must be a non-empty string', 2)
    end

    if itemKey == nil then
      error('[sure_lib][slice] patch: itemKey is required', 2)
    end

    if type(partial) ~= 'table' then
      error('[sure_lib][slice] patch: partial must be a table', 2)
    end

    local list = rawState[stateKey]
    if type(list) ~= 'table' then
      return self
    end

    local next = {}
    local touched = false
    for index, existing in ipairs(list) do
      if type(existing) == 'table' and existing.key == itemKey then
        local merged = {}
        for key, value in pairs(existing) do
          merged[key] = value
        end
        for key, value in pairs(partial) do
          merged[key] = value
        end
        merged.key = existing.key
        next[index] = merged
        touched = true
      else
        next[index] = existing
      end
    end

    if touched then
      state[stateKey] = next
    end

    return self
  end

  function slice:removeBy(stateKey, predicate)
    if type(stateKey) ~= 'string' or stateKey == '' then
      error('[sure_lib][slice] removeBy: stateKey must be a non-empty string', 2)
    end

    if type(predicate) ~= 'function' then
      error('[sure_lib][slice] removeBy: predicate must be a function', 2)
    end

    local list = rawState[stateKey]
    if type(list) ~= 'table' then
      return self
    end

    local next = {}
    local removed = false
    for _, existing in ipairs(list) do
      local drop = false
      local ok, result = pcall(predicate, existing)
      if ok then
        drop = result == true
      else
        slice.log.error(('removeBy(%s) predicate failed: %s'):format(stateKey, tostring(result)))
      end

      if drop then
        removed = true
      else
        next[#next + 1] = existing
      end
    end

    if removed then
      state[stateKey] = next
    end

    return self
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

  if type(spec.state) == 'table' then
    for stateKey in pairs(spec.state) do
      if type(stateKey) == 'string' and #stateKey > 0 then
        local actionName = 'set' .. stateKey:sub(1, 1):upper() .. stateKey:sub(2)
        slice.actions[actionName] = function(value)
          state[stateKey] = value
          return value
        end
      end
    end
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

  local function resolveIdentifier(identifier)
    if not isServer then
      return nil
    end

    local esx = _G.ESX
    if esx == nil or type(esx.GetPlayerFromIdentifier) ~= 'function' then
      return nil
    end

    local xPlayer = esx.GetPlayerFromIdentifier(identifier)
    if xPlayer == nil then
      return nil
    end

    return xPlayer.source
  end

  local function syncEventName(stateKey)
    return name .. ':sync:' .. stateKey
  end

  local function buildScope(scopeName)
    local playerIds = {}
    local identifiers = {}
    local bindings = {}

    local scope = {
      name = scopeName,
    }

    local function emitInitialTo(playerId)
      if playerId == nil or not isServer then
        return
      end

      for eventName, info in pairs(bindings) do
        local value = rawState[info.stateKey]
        if info.diff then
          TriggerClientEvent(eventName, playerId, { full = value })
        else
          TriggerClientEvent(eventName, playerId, value)
        end
      end
    end

    local function emitClearedTo(playerId)
      if playerId == nil or not isServer then
        return
      end

      for eventName, info in pairs(bindings) do
        if info.diff then
          TriggerClientEvent(eventName, playerId, { cleared = true })
        end
      end
    end

    function scope:add(idOrIdentifier)
      if type(idOrIdentifier) == 'number' then
        if not playerIds[idOrIdentifier] then
          playerIds[idOrIdentifier] = true
          emitInitialTo(idOrIdentifier)
        end
      elseif type(idOrIdentifier) == 'string' and idOrIdentifier ~= '' then
        if not identifiers[idOrIdentifier] then
          identifiers[idOrIdentifier] = true
          emitInitialTo(resolveIdentifier(idOrIdentifier))
        end
      end

      return self
    end

    function scope:remove(idOrIdentifier)
      local resolved = nil

      if type(idOrIdentifier) == 'number' then
        if playerIds[idOrIdentifier] then
          playerIds[idOrIdentifier] = nil
          resolved = idOrIdentifier
        end
      elseif type(idOrIdentifier) == 'string' then
        if identifiers[idOrIdentifier] then
          identifiers[idOrIdentifier] = nil
          resolved = resolveIdentifier(idOrIdentifier)
        end
      end

      if resolved ~= nil then
        emitClearedTo(resolved)
      end

      return self
    end

    function scope:list()
      local out = {}
      local seen = {}

      for id in pairs(playerIds) do
        if not seen[id] then
          seen[id] = true
          out[#out + 1] = id
        end
      end

      for identifier in pairs(identifiers) do
        local id = resolveIdentifier(identifier)
        if id ~= nil and not seen[id] then
          seen[id] = true
          out[#out + 1] = id
        end
      end

      return out
    end

    function scope:contains(playerId)
      if playerIds[playerId] then
        return true
      end

      for identifier in pairs(identifiers) do
        if resolveIdentifier(identifier) == playerId then
          return true
        end
      end

      return false
    end

    function scope:_bind(eventName, stateKey, useDiff)
      bindings[eventName] = { stateKey = stateKey, diff = useDiff == true }
    end

    return scope
  end

  function slice:scope(scopeName)
    if type(scopeName) ~= 'string' or scopeName == '' then
      error('[sure_lib][slice] scope: name must be a non-empty string', 2)
    end

    local existing = scopes[scopeName]
    if existing == nil then
      existing = buildScope(scopeName)
      scopes[scopeName] = existing
    end

    return existing
  end

  if type(spec.netSync) == 'table' then
    for stateKey, config in pairs(spec.netSync) do
      local direction = nil
      local scopeName = nil
      local useDiff = false

      if type(config) == 'string' then
        direction = config
      elseif type(config) == 'table' then
        direction = config.direction
        scopeName = config.scope
        useDiff = config.diff == true
      end

      if direction ~= 'sender' and direction ~= 'receiver' then
        slice.log.warn(('netSync.%s: invalid direction %s'):format(tostring(stateKey), tostring(direction)))
      else
        local eventName = syncEventName(stateKey)

        if direction == 'sender' then
          local boundScope = nil
          if type(scopeName) == 'string' and scopeName ~= '' then
            boundScope = slice:scope(scopeName)
            boundScope:_bind(eventName, stateKey, useDiff)
          end

          local snapshot = nil

          local function broadcast(payload)
            if isServer then
              if boundScope == nil then
                TriggerClientEvent(eventName, -1, payload)
              else
                for _, playerId in ipairs(boundScope:list()) do
                  TriggerClientEvent(eventName, playerId, payload)
                end
              end
            else
              TriggerServerEvent(eventName, payload)
            end
          end

          appendWatcher(watchers, stateKey, function(value)
            if not useDiff then
              broadcast(value)
              return
            end

            if not isKeyedArray(value) then
              if isKeyedArray(snapshot) then
                slice.log.warn(('netSync.%s: value is no longer a keyed array; falling back to full sync'):format(stateKey))
              end
              snapshot = nil
              broadcast({ full = value })
              return
            end

            if snapshot == nil then
              snapshot = deepClone(value)
              broadcast({ full = value })
              return
            end

            local patch = diffKeyedArray(snapshot, value)
            if patch == nil then
              return
            end

            snapshot = deepClone(value)
            broadcast({ patch = patch })
          end)
        elseif direction == 'receiver' then
          RegisterNetEvent(eventName, function(payload)
            if not useDiff then
              state[stateKey] = payload
              return
            end

            if type(payload) ~= 'table' then
              state[stateKey] = payload
              return
            end

            if payload.cleared == true then
              state[stateKey] = nil
              return
            end

            if payload.full ~= nil then
              state[stateKey] = payload.full
              return
            end

            if payload.patch ~= nil then
              state[stateKey] = applyKeyedPatch(rawState[stateKey], payload.patch)
              return
            end

            state[stateKey] = payload
          end)
        end
      end
    end
  end

  if type(spec.every) == 'table' then
    local intervals = {}
    local handlers = {}
    for interval, handler in pairs(spec.every) do
      if type(interval) == 'number' and interval > 0 and type(handler) == 'function' then
        intervals[#intervals + 1] = interval
        handlers[interval] = handler
      end
    end

    if #intervals > 0 then
      table.sort(intervals)
      local lastFired = {}

      local function tick(now)
        now = now or GetGameTimer()
        local nextDueIn = math.huge

        for _, interval in ipairs(intervals) do
          if lastFired[interval] == nil then
            lastFired[interval] = now
          end

          local elapsed = now - lastFired[interval]
          if elapsed >= interval then
            local ok, err = pcall(handlers[interval], slice)
            if not ok then
              slice.log.error(('every[%s] failed: %s'):format(interval, tostring(err)))
            end
            lastFired[interval] = now
            elapsed = 0
          end

          local remaining = interval - elapsed
          if remaining < nextDueIn then
            nextDueIn = remaining
          end
        end

        return nextDueIn == math.huge and 0 or math.max(nextDueIn, 0)
      end

      function slice:_tickEvery(now)
        return tick(now)
      end

      CreateThread(function()
        while not stopped do
          local sleep = tick()
          Wait(sleep)
        end
      end)
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

    stopped = true

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
