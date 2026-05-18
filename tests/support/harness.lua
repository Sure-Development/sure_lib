local harness = {
  tests = {},
}

local resourceModules = {
  ['@sure_lib.init'] = 'init.lua',
  ['@sure_lib.shared.init'] = 'shared/init.lua',
  ['@sure_lib.shared.modules.validator.index'] = 'shared/modules/validator/index.lua',
  ['@sure_lib.shared.modules.track.index'] = 'shared/modules/track/index.lua',
  ['@sure_lib.shared.modules.listener.index'] = 'shared/modules/listener/index.lua',
  ['@sure_lib.client.modules.player.index'] = 'client/modules/player/index.lua',
  ['@sure_lib.client.modules.cooldown.index'] = 'client/modules/cooldown/index.lua',
  ['@sure_lib.server.modules.esx.index'] = 'server/modules/esx/index.lua',
  ['@sure_lib.server.modules.cooldown.index'] = 'server/modules/cooldown/index.lua',
}

local loadedModuleKeys = {
  '@sure_lib.init',
  '@sure_lib.shared.init',
  'init',
  'shared.init',
  'shared.modules.validator.index',
  'shared.modules.track.index',
  'shared.modules.listener.index',
  'client.modules.player.index',
  'client.modules.cooldown.index',
  'server.modules.esx.index',
  'server.modules.cooldown.index',
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
    timers = {},
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
  }

  _G.exports = {
    es_extended = {
      getSharedObject = function()
        return options.esx or defaultEsx()
      end,
    },
  }

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

  harness.registerResourceModules()

  return context
end

return harness
