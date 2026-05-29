local h = require('tests.support.harness')

h.test('server cooldown by id initializes and broadcasts state per identifier', function()
  local context = h.reset('server')
  local cooldown = h.load('server/modules/cooldown/index.lua')

  cooldown.define('ability', {
    initialDurationMs = 2000,
    durationMs = 5000,
  })

  local current = context.callbacks['sure_lib:lib:cooldownGetOrInitById'](10, 'ability', 'license:abc')
  cooldown.startById('ability', 'license:abc', 5000)

  h.assertEqual(2000, current)
  h.assertEqual('sure_lib:lib:cooldownSetById', context.clientEvents[1].name)
  h.assertEqual('license:abc', context.clientEvents[1].args[2])
  h.assertEqual(5000, context.clientEvents[1].args[3])
end)

h.test('server cooldown net event by id reuses default duration when missing', function()
  local context = h.reset('server')
  local cooldown = h.load('server/modules/cooldown/index.lua')

  cooldown.define('ability', {
    initialDurationMs = 2000,
    durationMs = 7000,
  })

  context.events['sure_lib:lib:cooldownSetById']('ability', 'player:1')

  local broadcast = context.clientEvents[1]
  h.assertEqual('sure_lib:lib:cooldownSetById', broadcast.name)
  h.assertEqual(7000, broadcast.args[3])
end)

h.test('client cooldown by id pulls remaining from server callback when missing', function()
  local context = h.reset('client', {
    callbackResults = {
      ['sure_lib:lib:cooldownGetFirstTime'] = {},
      ['sure_lib:lib:cooldownGetOrInitById'] = 4000,
    },
    esx = {
      IsPlayerLoaded = function()
        return true
      end,
    },
  })
  local cooldown = h.load('client/modules/cooldown/index.lua')

  h.assertEqual(4000, cooldown.getRemainingById('ability', 'license:abc'))

  cooldown.startById('ability', 'license:abc', 6000)

  h.assertEqual('sure_lib:lib:cooldownSetById', context.serverEvents[1].name)
  h.assertEqual('license:abc', context.serverEvents[1].args[2])
  h.assertEqual(6000, context.serverEvents[1].args[3])
end)

h.test('client cooldown by id timer decrements local data', function()
  local context = h.reset('client', {
    callbackResults = {
      ['sure_lib:lib:cooldownGetFirstTime'] = {
        data = {},
        dataById = {
          ability = { ['license:abc'] = 1500 },
        },
      },
    },
    esx = {
      IsPlayerLoaded = function()
        return true
      end,
    },
  })
  local cooldown = h.load('client/modules/cooldown/index.lua')

  context.timers[1].callback(context.timers[1])

  h.assertEqual(500, cooldown.allById().ability['license:abc'])
end)
