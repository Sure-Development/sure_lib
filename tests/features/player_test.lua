local h = require('tests.support.harness')

local function setupPlayer(playerData, options)
  options = options or {}
  options.esx = {
    Game = {
      GetVehicleProperties = function(vehicle)
        if vehicle == options.vehicle then
          return options.vehicleProperties
        end

        return nil
      end,
    },
    IsPlayerLoaded = function()
      return true
    end,
    GetPlayerData = function()
      return playerData
    end,
  }

  local context = h.reset('client', options)
  cache.vehicle = options.vehicle
  require('@sure_lib.init')

  return context
end

h.test('sure.player auto-imports on client shared init', function()
  setupPlayer({
    inventory = {},
    accounts = {},
    loadout = {},
  })

  h.assertEqual('table', type(sure.player))
  h.assertEqual('table', type(sure.player.inventory))
end)

h.test('sure.player inventory returns current list and item lookup by name', function()
  local playerData = {
    inventory = {
      { name = 'bread', count = 1 },
      { name = 'water', count = 2 },
    },
    accounts = {},
    loadout = {},
  }
  setupPlayer(playerData)

  h.assertEqual(playerData.inventory, sure.player.inventory)
  h.assertEqual(1, sure.player.inventory.bread.count)

  playerData.inventory = {
    { name = 'bread', count = 5 },
  }

  h.assertEqual(5, sure.player.inventory.bread.count)
end)

h.test('sure.player accounts lookup by account name', function()
  setupPlayer({
    inventory = {},
    accounts = {
      { name = 'money', money = 50 },
      { name = 'bank', money = 250 },
    },
    loadout = {},
  })

  h.assertEqual(250, sure.player.accounts.bank.money)
  h.assertEqual(50, sure.player.accounts.money.money)
end)

h.test('sure.player loadout lookup normalizes weapon names', function()
  setupPlayer({
    inventory = {},
    accounts = {},
    loadout = {
      { name = 'WEAPON_POOLCUE', ammo = 1 },
      { name = 'WEAPON_PISTOL', ammo = 12 },
    },
  })

  h.assertEqual(1, sure.player.loadout['WEAPON_POOLCUE'].ammo)
  h.assertEqual(1, sure.player.loadout.weapon_poolcue.ammo)
  h.assertEqual(1, sure.player.loadout.poolcue.ammo)
  h.assertEqual(12, sure.player.loadout.pistol.ammo)
end)

h.test('sure.player exposes ped state and current vehicle properties', function()
  local vehicleProperties = {
    plate = 'SURE',
  }
  setupPlayer({
    inventory = {},
    accounts = {},
    loadout = {},
  }, {
    ped = 15,
    health = 175,
    armor = 50,
    coords = { x = 10, y = 20, z = 30 },
    vehicle = 99,
    vehicleProperties = vehicleProperties,
  })

  h.assertEqual(15, sure.player.ped)
  h.assertEqual(175, sure.player.health)
  h.assertEqual(50, sure.player.armor)
  h.assertEqual(10, sure.player.coords.x)
  h.assertEqual(vehicleProperties, sure.player.currentVehicleProperties)

  cache.vehicle = nil

  h.assertNil(sure.player.currentVehicleProperties)
end)

h.test('sure.player exposes common player shortcuts', function()
  local playerData = {
    inventory = {},
    accounts = {},
    loadout = {},
  }
  setupPlayer(playerData, {
    vehicle = 77,
  })
  cache.serverId = 12

  h.assertEqual(playerData, sure.player.data)
  h.assertTrue(sure.player.loaded)
  h.assertEqual(12, sure.player.serverId)
  h.assertEqual(77, sure.player.vehicle)
  h.assertNil(sure.player.waitUntilLoaded())
end)
