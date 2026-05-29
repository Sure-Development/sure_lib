--- @class Hook : OxClass
local Hook = lib.class('Hook')

local function safeGetInvokingResource()
  if type(_G.GetInvokingResource) == 'function' then
    local ok, value = pcall(GetInvokingResource)
    if ok then
      return value
    end
  end

  return nil
end

local function safeGetCurrentResourceName()
  if type(_G.GetCurrentResourceName) == 'function' then
    local ok, value = pcall(GetCurrentResourceName)
    if ok then
      return value
    end
  end

  return nil
end

local function runPipeline(middlewares, ctx, terminate)
  local index = 0

  local function next()
    index = index + 1
    local middleware = middlewares[index]
    if middleware == nil then
      return terminate()
    end

    return middleware(ctx, next)
  end

  return next()
end

local function validatorMiddleware(meta)
  return function(ctx, next)
    for index, validator in ipairs(meta.params) do
      local arg = ctx.args[index]

      local success = pcall(function()
        validator.parse(arg)
      end)

      if not success then
        local message = ('[^1ERROR^7] Parameter index ^1%s^7, expected ^1%s^7 got ^1%s^7 of event ^1%s^7 is not valid'):format(index, validator.type, type(arg), ctx.name)

        print(message)
        error(message, 2)
      end
    end

    return next()
  end
end

function Hook:constructor()
  self.middlewares = {}
  self.hooksByName = {}
  self.localInjections = {}
  self.remoteInjectionSources = {}
  self:registerInjectionExports()
end

function Hook:registerInjectionExports()
  if type(_G.exports) ~= 'table' and type(_G.exports) ~= 'function' then
    return
  end

  local mt = type(_G.exports) == 'table' and getmetatable(_G.exports) or nil
  local callable = type(_G.exports) == 'function' or (mt and type(mt.__call) == 'function')
  if not callable then
    return
  end

  local hook = self

  pcall(function()
    exports('__sureHookRegisterInjection', function(hookName)
      local source = safeGetInvokingResource()
      if type(source) ~= 'string' or source == '' or type(hookName) ~= 'string' or hookName == '' then
        return false
      end

      local sources = hook.remoteInjectionSources[hookName]
      if sources == nil then
        sources = {}
        hook.remoteInjectionSources[hookName] = sources
      end

      for _, existing in ipairs(sources) do
        if existing == source then
          return true
        end
      end

      sources[#sources + 1] = source
      return true
    end)

    exports('__sureHookRunInjection', function(hookName, args)
      local target = safeGetInvokingResource()
      local result = { args = args or {}, cancelled = false }

      if type(target) ~= 'string' or type(hookName) ~= 'string' then
        return result
      end

      local byHook = hook.localInjections[target]
      if byHook == nil then
        return result
      end

      local list = byHook[hookName]
      if list == nil or #list == 0 then
        return result
      end

      local ctx = {
        name = hookName,
        args = args or {},
        cancelled = false,
      }

      for _, fn in ipairs(list) do
        local ok, err = pcall(fn, ctx)
        if not ok then
          print(('[sure_lib][hook] injection error for %s: %s'):format(hookName, tostring(err)))
        end

        if ctx.cancelled then
          break
        end
      end

      result.args = ctx.args
      result.cancelled = ctx.cancelled == true
      return result
    end)
  end)
end

--- @param middleware fun(ctx: SureHookContext, next: fun(): any): any
function Hook:use(middleware)
  self.middlewares[#self.middlewares + 1] = middleware
  return self
end

local function buildRemoteInjectionMiddleware(hook, eventName)
  return function(ctx, next)
    local sources = hook.remoteInjectionSources[eventName]
    if sources == nil or #sources == 0 then
      return next()
    end

    for _, source in ipairs(sources) do
      local ok, response = pcall(function()
        local target = _G.exports and _G.exports[source]
        if target == nil then
          return nil
        end

        local fn = target.__sureHookRunInjection
        if type(fn) ~= 'function' then
          return nil
        end

        return fn(target, eventName, ctx.args)
      end)

      if ok and type(response) == 'table' then
        if type(response.args) == 'table' then
          ctx.args = response.args
        end

        if response.cancelled == true then
          return
        end
      end
    end

    return next()
  end
end

function Hook:listen(eventName, callback, register)
  local meta = {
    name = eventName,
    params = {},
    middlewares = {},
    callback = callback,
  }

  function meta:expect(...)
    meta.params = { ... }
    return meta
  end

  function meta:use(middleware)
    meta.middlewares[#meta.middlewares + 1] = middleware
    return meta
  end

  local hook = self
  hook.hooksByName[eventName] = true

  register(eventName, function(...)
    local args = { ... }
    local ctx = {
      name = eventName,
      args = args,
    }

    local pipeline = {}
    for _, middleware in ipairs(hook.middlewares) do
      pipeline[#pipeline + 1] = middleware
    end

    pipeline[#pipeline + 1] = buildRemoteInjectionMiddleware(hook, eventName)

    for _, middleware in ipairs(meta.middlewares) do
      pipeline[#pipeline + 1] = middleware
    end

    if #meta.params > 0 then
      pipeline[#pipeline + 1] = validatorMiddleware(meta)
    end

    runPipeline(pipeline, ctx, function()
      callback(table.unpack(ctx.args, 1, #ctx.args))
    end)
  end)

  return meta
end

--- @param eventName string
--- @param callback fun(...)
function Hook:on(eventName, callback)
  return self:listen(eventName, callback, AddEventHandler)
end

--- @param eventName string
--- @param callback fun(...)
function Hook:onNet(eventName, callback)
  return self:listen(eventName, callback, RegisterNetEvent)
end

--- Register middleware against a hook owned by another resource.
--- @param targetResource string
--- @param hookName string
--- @param middleware fun(ctx: SureHookContext): any
function Hook:injectResource(targetResource, hookName, middleware)
  if type(targetResource) ~= 'string' or targetResource == '' then
    error('[sure_lib][hook] injectResource: targetResource is required', 2)
  end

  if type(hookName) ~= 'string' or hookName == '' then
    error('[sure_lib][hook] injectResource: hookName is required', 2)
  end

  if type(middleware) ~= 'function' then
    error('[sure_lib][hook] injectResource: middleware must be a function', 2)
  end

  local byTarget = self.localInjections[targetResource]
  if byTarget == nil then
    byTarget = {}
    self.localInjections[targetResource] = byTarget
  end

  local list = byTarget[hookName]
  if list == nil then
    list = {}
    byTarget[hookName] = list
  end

  list[#list + 1] = middleware

  pcall(function()
    local target = _G.exports and _G.exports[targetResource]
    if target == nil then
      return
    end

    local fn = target.__sureHookRegisterInjection
    if type(fn) ~= 'function' then
      return
    end

    fn(target, hookName)
  end)

  local current = safeGetCurrentResourceName()
  if current ~= nil and current == targetResource then
    local sources = self.remoteInjectionSources[hookName]
    if sources == nil then
      sources = {}
      self.remoteInjectionSources[hookName] = sources
    end

    local already = false
    for _, existing in ipairs(sources) do
      if existing == current then
        already = true
        break
      end
    end

    if not already then
      sources[#sources + 1] = current
    end
  end

  return self
end

--- Trigger a local event after running the hook pipeline.
--- @param eventName string
--- @param ... any
function Hook:dispatch(eventName, ...)
  TriggerEvent(eventName, ...)
end

--- Server-only: triggers a client event.
--- @param target integer|string
--- @param eventName string
--- @param ... any
function Hook:dispatchClient(target, eventName, ...)
  if not IsDuplicityVersion() then
    error('[sure_lib][hook] dispatchClient is server-only', 2)
  end

  TriggerClientEvent(eventName, target, ...)
end

--- Client-only: triggers a server event.
--- @param eventName string
--- @param ... any
function Hook:dispatchServer(eventName, ...)
  if IsDuplicityVersion() then
    error('[sure_lib][hook] dispatchServer is client-only', 2)
  end

  TriggerServerEvent(eventName, ...)
end

return Hook:new()
