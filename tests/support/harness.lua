---@diagnostic disable: duplicate-set-field

local harness = {
  tests = {},
}

local resourceModules = {
  ['@sure_lib.init'] = 'init.lua',
  ['@sure_lib.shared.init'] = 'shared/init.lua',
  ['@sure_lib.shared.modules.validator.index'] = 'shared/modules/validator/index.lua',
  ['@sure_lib.shared.modules.track.index'] = 'shared/modules/track/index.lua',
  ['@sure_lib.shared.modules.hook.index'] = 'shared/modules/hook/index.lua',
  ['@sure_lib.shared.modules.slice.index'] = 'shared/modules/slice/index.lua',
  ['@sure_lib.shared.modules.log.index'] = 'shared/modules/log/index.lua',
  ['@sure_lib.shared.modules.config.index'] = 'shared/modules/config/index.lua',
  ['@sure_lib.client.modules.player.index'] = 'client/modules/player/index.lua',
  ['@sure_lib.client.modules.cooldown.index'] = 'client/modules/cooldown/index.lua',
  ['@sure_lib.client.modules.spawn.index'] = 'client/modules/spawn/index.lua',
  ['@sure_lib.client.modules.keybind.index'] = 'client/modules/keybind/index.lua',
  ['@sure_lib.client.modules.lui.index'] = 'client/modules/lui/index.lua',
  ['@sure_lib.client.modules.lui.blueprint'] = 'client/modules/lui/blueprint.lua',
  ['@sure_lib.client.modules.lui.builder'] = 'client/modules/lui/builder.lua',
  ['@sure_lib.client.modules.lui.nui'] = 'client/modules/lui/nui.lua',
  ['@sure_lib.client.modules.lui.renderer'] = 'client/modules/lui/renderer.lua',
  ['@sure_lib.client.modules.lui.state'] = 'client/modules/lui/state.lua',
  ['@sure_lib.client.modules.lui.utils'] = 'client/modules/lui/utils.lua',
  ['@sure_lib.server.modules.esx.index'] = 'server/modules/esx/index.lua',
  ['@sure_lib.server.modules.cooldown.index'] = 'server/modules/cooldown/index.lua',
  ['@sure_lib.server.modules.db.index'] = 'server/modules/db/index.lua',
}

local loadedModuleKeys = {
  '@sure_lib.init',
  '@sure_lib.shared.init',
  'init',
  'shared.init',
  'shared.modules.validator.index',
  'shared.modules.track.index',
  'shared.modules.hook.index',
  'shared.modules.slice.index',
  'shared.modules.log.index',
  'shared.modules.config.index',
  'client.modules.player.index',
  'client.modules.cooldown.index',
  'client.modules.spawn.index',
  'client.modules.keybind.index',
  'client.modules.lui.index',
  'client.modules.lui.blueprint',
  'client.modules.lui.builder',
  'client.modules.lui.nui',
  'client.modules.lui.renderer',
  'client.modules.lui.state',
  'client.modules.lui.utils',
  'server.modules.esx.index',
  'server.modules.cooldown.index',
  'server.modules.db.index',
}

local function deepClone(value)
  if type(value) ~= 'table' then
    return value
  end

  local cloned = {}
  for key, item in pairs(value) do
    cloned[deepClone(key)] = deepClone(item)
  end

  return cloned
end

local function defaultEsx()
  return {
    IsPlayerLoaded = function()
      return true
    end,
    GetPlayerData = function()
      return {
        inventory = {},
        accounts = {},
        loadout = {},
      }
    end,
    GetPlayerFromId = function()
      return nil
    end,
  }
end

local function defaultOxmysql(context)
  return {
    query_async = function(_, sql, params)
      context.mysqlQueries[#context.mysqlQueries + 1] = {
        method = 'query_async',
        sql = sql,
        params = params or {},
      }

      return {}
    end,
    insert_async = function(_, sql, params)
      context.mysqlQueries[#context.mysqlQueries + 1] = {
        method = 'insert_async',
        sql = sql,
        params = params or {},
      }

      return 1
    end,
    update_async = function(_, sql, params)
      context.mysqlQueries[#context.mysqlQueries + 1] = {
        method = 'update_async',
        sql = sql,
        params = params or {},
      }

      return 1
    end,
    execute_async = function(_, sql, params)
      context.mysqlQueries[#context.mysqlQueries + 1] = {
        method = 'execute_async',
        sql = sql,
        params = params or {},
      }

      return true
    end,
  }
end

local function hashString(value)
  local hash = 0
  for index = 1, #value do
    hash = hash + value:byte(index) * index
  end

  return hash
end

function harness.test(testName, callback)
  harness.tests[#harness.tests + 1] = {
    name = testName,
    callback = callback,
  }
end

function harness.assertEqual(expected, actual, message)
  if expected ~= actual then
    error((message or 'values are not equal') .. (': expected %s, got %s'):format(tostring(expected), tostring(actual)), 2)
  end
end

function harness.assertTrue(value, message)
  harness.assertEqual(true, value, message)
end

function harness.assertFalse(value, message)
  harness.assertEqual(false, value, message)
end

function harness.assertNil(value, message)
  if value ~= nil then
    error((message or 'expected nil') .. (': got %s'):format(tostring(value)), 2)
  end
end

function harness.assertErrorContains(action, expectedText)
  local originalPrint = _G.print
  _G.print = function() end

  local ok, err = pcall(action)
  _G.print = originalPrint

  if ok then
    error('expected function to error', 2)
  end

  if expectedText and not tostring(err):find(expectedText, 1, true) then
    error(('expected error to contain %q, got %q'):format(expectedText, tostring(err)), 2)
  end
end

function harness.load(path)
  local chunk, err = loadfile(path)
  if not chunk then
    error(err, 2)
  end

  return chunk()
end

function harness.registerResourceModules()
  for name, path in pairs(resourceModules) do
    package.preload[name] = function()
      return harness.load(path)
    end
  end
end

function harness.reset(side, options)
  options = options or {}

  for name in pairs(resourceModules) do
    package.loaded[name] = nil
  end

  for _, name in ipairs(loadedModuleKeys) do
    package.loaded[name] = nil
  end

  _G.sure = nil
  _G.cache = {
    resource = options.resourceName or 'sure_lib',
  }

  local context = {
    events = {},
    callbacks = {},
    serverEvents = {},
    clientEvents = {},
    nuiCallbacks = {},
    nuiMessages = {},
    nuiFocus = {},
    timers = {},
    commands = {},
    mysqlQueries = {},
    resourceFiles = options.resourceFiles or {},
    savedResourceFiles = {},
    requestedModels = {},
    requestedAnimDicts = {},
    spawnedPeds = {},
    spawnedObjects = {},
    deletedEntities = {},
    entityOptions = {},
    points = {},
    entities = {},
    networkedEntities = {},
    controlledEntities = {},
    missionEntities = {},
    nextHandle = options.nextHandle or 1000,
    currentTime = options.currentTime or 0,
    logs = {
      info = {},
      error = {},
    },
    ped = options.ped or 100,
    health = options.health or 200,
    armor = options.armor or 0,
    coords = options.coords or { x = 0, y = 0, z = 0 },
    vehicleProperties = options.vehicleProperties or nil,
  }

  _G.IsDuplicityVersion = function()
    return side == 'server'
  end

  _G.lib = {
    table = {
      deepclone = deepClone,
    },
    print = {
      info = function(message)
        context.logs.info[#context.logs.info + 1] = message
      end,
      error = function(message)
        context.logs.error[#context.logs.error + 1] = message
      end,
    },
    load = function(filePath, env)
      context.loadedFiles = context.loadedFiles or {}
      context.loadedFiles[#context.loadedFiles + 1] = {
        filePath = filePath,
        env = env,
      }

      local resourcePath = filePath
      local content = context.resourceFiles[resourcePath]
      if content == nil then
        resourcePath = filePath:gsub('%.', '/') .. '.lua'
        content = context.resourceFiles[resourcePath]
      end

      if content == nil then
        error('file not found: ' .. filePath, 2)
      end

      local chunk, err = load(content, '@' .. resourcePath, 't', env)
      if chunk == nil then
        error(err, 2)
      end

      return chunk()
    end,
    callback = {
      register = function(name, callback)
        context.callbacks[name] = callback
      end,
      await = function(name, _, ...)
        local callback = context.callbacks[name]
        if callback then
          return callback(false, ...)
        end

        local value = options.callbackResults and options.callbackResults[name]
        if type(value) == 'function' then
          return value(...)
        end

        return value
      end,
    },
    points = {
      new = function(point)
        function point:remove()
          self.removed = true
        end

        context.points[#context.points + 1] = point
        return point
      end,
    },
    timer = function(interval, callback, active)
      local timer = {
        interval = interval,
        callback = callback,
        active = active,
        restarted = false,
      }

      function timer:restart(force)
        self.restarted = force == true
      end

      context.timers[#context.timers + 1] = timer
      return timer
    end,
    class = function()
      local class = {}
      class.__index = class

      function class:new(...)
        local instance = setmetatable({}, class)
        if type(instance.constructor) == 'function' then
          instance:constructor(...)
        end

        return instance
      end

      return class
    end,
    addKeybind = options.addKeybind or function(spec)
      context.keybinds = context.keybinds or {}
      context.keybinds[#context.keybinds + 1] = spec

      local instance = {
        spec = spec,
        disabled = false,
      }

      function instance:disable(value)
        instance.disabled = value
      end

      return instance
    end,
  }

  local currentResource = options.resourceName or 'sure_lib'
  context.exportRegistry = {}
  context.invokingStack = {}

  local staticExports = {
    es_extended = {
      getSharedObject = function()
        return options.esx or defaultEsx()
      end,
    },
    oxmysql = options.oxmysql or defaultOxmysql(context),
  }

  local function buildResourceProxy(resourceName)
    local proxy = {}
    return setmetatable(proxy, {
      __index = function(_, fnName)
        local registry = context.exportRegistry[resourceName]
        if registry == nil or registry[fnName] == nil then
          return nil
        end

        local fn = registry[fnName]
        return function(...)
          local args = { ... }
          if args[1] == proxy then
            table.remove(args, 1)
          end

          context.invokingStack[#context.invokingStack + 1] = currentResource
          local ok, result = pcall(fn, table.unpack(args))
          context.invokingStack[#context.invokingStack] = nil

          if not ok then
            error(result, 2)
          end

          return result
        end
      end,
    })
  end

  _G.exports = setmetatable({}, {
    __call = function(_, name, fn)
      if type(name) ~= 'string' or type(fn) ~= 'function' then
        return
      end

      local registry = context.exportRegistry[currentResource]
      if registry == nil then
        registry = {}
        context.exportRegistry[currentResource] = registry
      end

      registry[name] = fn
    end,
    __index = function(_, resourceName)
      if staticExports[resourceName] ~= nil then
        return staticExports[resourceName]
      end

      return buildResourceProxy(resourceName)
    end,
  })

  _G.GetCurrentResourceName = function()
    return currentResource
  end

  _G.GetInvokingResource = function()
    return context.invokingStack[#context.invokingStack]
  end

  context.setInvokingResource = function(name)
    context.invokingStack[#context.invokingStack + 1] = name
  end

  context.clearInvokingResource = function()
    context.invokingStack[#context.invokingStack] = nil
  end

  context.registerExternalExport = function(resourceName, fnName, fn)
    local registry = context.exportRegistry[resourceName]
    if registry == nil then
      registry = {}
      context.exportRegistry[resourceName] = registry
    end

    registry[fnName] = fn
  end

  _G.LoadResourceFile = function(_, filePath)
    return context.resourceFiles[filePath]
  end

  _G.SaveResourceFile = function(_, filePath, content)
    context.resourceFiles[filePath] = content
    context.savedResourceFiles[filePath] = content
    return true
  end

  _G.RegisterCommand = function(name, callback, restricted)
    context.commands[name] = {
      callback = callback,
      restricted = restricted,
    }
  end

  _G.RegisterNUICallback = function(name, callback)
    context.nuiCallbacks[name] = callback
  end

  _G.SendNUIMessage = function(message)
    context.nuiMessages[#context.nuiMessages + 1] = message
  end

  _G.SetNuiFocus = function(hasFocus, hasCursor)
    context.nuiFocus[#context.nuiFocus + 1] = {
      hasFocus = hasFocus,
      hasCursor = hasCursor,
    }
  end

  _G.RegisterNetEvent = function(name, callback)
    context.events[name] = callback
  end

  _G.AddEventHandler = function(name, callback)
    context.events[name] = callback
  end

  _G.TriggerServerEvent = function(name, ...)
    context.serverEvents[#context.serverEvents + 1] = {
      name = name,
      args = { ... },
    }
  end

  _G.TriggerEvent = function(name, ...)
    context.localEvents = context.localEvents or {}
    context.localEvents[#context.localEvents + 1] = {
      name = name,
      args = { ... },
    }
    local handler = context.events[name]
    if handler ~= nil then
      handler(...)
    end
  end

  _G.GetResourceState = function(resource)
    local states = options.resourceStates or {}
    return states[resource] or 'started'
  end

  _G.GetResourceMetadata = function(resource, key)
    local metadata = options.resourceMetadata or {}
    local entry = metadata[resource]
    if type(entry) == 'table' then
      return entry[key]
    end

    return nil
  end

  _G.TriggerClientEvent = function(name, target, ...)
    context.clientEvents[#context.clientEvents + 1] = {
      name = name,
      target = target,
      args = { ... },
    }
  end

  _G.CreateThread = function(callback)
    callback()
  end

  _G.Wait = function() end

  _G.promise = {
    new = function()
      local promiseObject = {
        resolved = false,
      }

      function promiseObject:resolve(value)
        self.resolved = true
        self.value = value
      end

      return promiseObject
    end,
  }

  _G.Citizen = {
    Await = function(promiseObject)
      return promiseObject.value
    end,
  }

  _G.PlayerPedId = function()
    return context.ped
  end

  _G.GetEntityHealth = function(ped)
    return ped == context.ped and context.health or 0
  end

  _G.GetEntityArmor = function(ped)
    return ped == context.ped and context.armor or 0
  end

  _G.GetEntityCoords = function(ped)
    return ped == context.ped and context.coords or nil
  end

  _G.vector3 = function(x, y, z)
    return {
      x = x,
      y = y,
      z = z,
    }
  end

  _G.vector4 = function(x, y, z, w)
    return {
      x = x,
      y = y,
      z = z,
      w = w,
    }
  end

  _G.GetHashKey = function(model)
    if type(model) ~= 'string' then
      return model
    end

    return options.modelHashes and options.modelHashes[model] or hashString(model)
  end

  _G.GetGameTimer = function()
    context.currentTime = context.currentTime + 1
    return context.currentTime
  end

  _G.RequestModel = function(modelHash)
    context.requestedModels[#context.requestedModels + 1] = modelHash
  end

  _G.HasModelLoaded = function()
    return options.modelLoaded ~= false
  end

  _G.CreatePed = function(pedType, modelHash, x, y, z, heading, networked, dynamic)
    context.nextHandle = context.nextHandle + 1
    local handle = context.nextHandle
    context.entities[handle] = true
    context.networkedEntities[handle] = networked == true
    context.spawnedPeds[#context.spawnedPeds + 1] = {
      handle = handle,
      pedType = pedType,
      modelHash = modelHash,
      x = x,
      y = y,
      z = z,
      heading = heading,
      networked = networked,
      dynamic = dynamic,
    }

    return handle
  end

  _G.CreateObjectNoOffset = function(modelHash, x, y, z, networked, door, dynamic)
    context.nextHandle = context.nextHandle + 1
    local handle = context.nextHandle
    context.entities[handle] = true
    context.networkedEntities[handle] = networked == true
    context.spawnedObjects[#context.spawnedObjects + 1] = {
      handle = handle,
      modelHash = modelHash,
      x = x,
      y = y,
      z = z,
      networked = networked,
      door = door,
      dynamic = dynamic,
    }

    return handle
  end

  _G.FreezeEntityPosition = function(handle, value)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].freeze = value
  end

  _G.SetEntityInvincible = function(handle, value)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].invincible = value
  end

  _G.SetEntityCollision = function(handle, enabled)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].collision = enabled
  end

  _G.SetEntityAlpha = function(handle, value)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].alpha = value
  end

  _G.SetBlockingOfNonTemporaryEvents = function(handle, value)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].blockEvents = value
  end

  _G.SetPedDiesWhenInjured = function(handle, value)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].diesOnInjury = value
  end

  _G.PlaceObjectOnGroundProperly = function(handle)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].placedOnGround = true
  end

  _G.RequestAnimDict = function(dict)
    context.requestedAnimDicts[#context.requestedAnimDicts + 1] = dict
  end

  _G.HasAnimDictLoaded = function()
    return options.animDictLoaded ~= false
  end

  _G.TaskStartScenarioInPlace = function(handle, scenario)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].scenario = scenario
  end

  _G.TaskPlayAnim = function(handle, dict, clip, blendIn, blendOut, duration, flag)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].animation = {
      dict = dict,
      clip = clip,
      blendIn = blendIn,
      blendOut = blendOut,
      duration = duration,
      flag = flag,
    }
  end

  _G.SetEntityRotation = function(handle, x, y, z)
    context.entityOptions[handle] = context.entityOptions[handle] or {}
    context.entityOptions[handle].rotation = {
      x = x,
      y = y,
      z = z,
    }
  end

  _G.SetModelAsNoLongerNeeded = function(modelHash)
    context.releasedModel = modelHash
  end

  _G.DoesEntityExist = function(handle)
    return context.entities[handle] == true
  end

  _G.NetworkGetEntityIsNetworked = function(handle)
    return context.networkedEntities[handle] == true
  end

  _G.NetworkRequestControlOfEntity = function(handle)
    context.controlledEntities[handle] = true
  end

  _G.SetEntityAsMissionEntity = function(handle, value, force)
    context.missionEntities[handle] = { value = value, force = force }
  end

  _G.DeleteEntity = function(handle)
    context.deletedEntities[#context.deletedEntities + 1] = handle
    context.entities[handle] = nil
    context.networkedEntities[handle] = nil
  end

  harness.registerResourceModules()

  return context
end

return harness
