local h = require('tests.support.harness')

h.test('server cooldown initializes, returns and broadcasts cooldown state', function()
  local context = h.reset('server')
  local cooldown = h.load('server/modules/cooldown/index.lua')
  local position = { x = 1, y = 2, z = 3 }

  cooldown.define('robbery', {
    initialDurationMs = 5000,
    durationMs = 10000,
    resetAfterZeroTicks = 2,
  })

  local current = context.callbacks['sure_lib:lib:cooldownGetOrInit'](10, 'robbery', position)
  context.events['sure_lib:lib:cooldownSet']('robbery', position)

  h.assertEqual(5000, current)
  h.assertEqual('sure_lib:lib:cooldownSet', context.clientEvents[1].name)
  h.assertEqual(10000, context.clientEvents[1].args[3])
  h.assertEqual(1, #context.timers)
end)

h.test('client cooldown requests missing state and sends set events', function()
  local position = { x = 1, y = 2, z = 3 }
  local context = h.reset('client', {
    callbackResults = {
      ['sure_lib:lib:cooldownGetFirstTime'] = {},
      ['sure_lib:lib:cooldownGetOrInit'] = 5000,
    },
    esx = {
      IsPlayerLoaded = function()
        return true
      end,
    },
  })
  local cooldown = h.load('client/modules/cooldown/index.lua')

  h.assertEqual(5000, cooldown.getRemaining('robbery', position))

  cooldown.start('robbery', position, 10000)

  h.assertEqual('sure_lib:lib:cooldownSet', context.serverEvents[1].name)
  h.assertEqual('robbery', context.serverEvents[1].args[1])
  h.assertEqual(10000, context.serverEvents[1].args[3])
end)

h.test('client cooldown timer decrements local data', function()
  local context = h.reset('client', {
    callbackResults = {
      ['sure_lib:lib:cooldownGetFirstTime'] = {
        robbery = {
          ['robbery_1:2:3'] = 1500,
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

  h.assertEqual(500, cooldown.all().robbery['robbery_1:2:3'])
end)

h.test('server cooldown pauses at pauseTimerOn until an external update changes the value', function()
  local context = h.reset('server')
  local cooldown = h.load('server/modules/cooldown/index.lua')
  local position = { x = 1, y = 2, z = 3 }

  cooldown.define('event', {
    initialDurationMs = 31000,
    durationMs = 60000,
    pauseTimerOn = 30000,
  })

  context.callbacks['sure_lib:lib:cooldownGetOrInit'](10, 'event', position)
  context.timers[1].callback(context.timers[1])
  context.timers[1].callback(context.timers[1])

  h.assertEqual(30000, context.callbacks['sure_lib:lib:cooldownGetOrInit'](10, 'event', position))

  context.events['sure_lib:lib:cooldownSet']('event', position, 29000)
  context.timers[1].callback(context.timers[1])

  h.assertEqual(28000, context.callbacks['sure_lib:lib:cooldownGetOrInit'](10, 'event', position))
end)

h.test('client cooldown respects pauseTimerOn definitions from first-time sync', function()
  local context = h.reset('client', {
    callbackResults = {
      ['sure_lib:lib:cooldownGetFirstTime'] = {
        data = {
          event = {
            ['event_1:2:3'] = 31000,
          },
        },
        definitions = {
          event = {
            pauseTimerOn = 30000,
          },
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
  context.timers[1].callback(context.timers[1])

  h.assertEqual(30000, cooldown.all().event['event_1:2:3'])

  context.events['sure_lib:lib:cooldownSetByIndex']('event', 'event_1:2:3', 29000)
  context.timers[1].callback(context.timers[1])

  h.assertEqual(28000, cooldown.all().event['event_1:2:3'])
end)

h.test('server cooldown rounds position keys to avoid floating point drift', function()
  local context = h.reset('server')
  local cooldown = h.load('server/modules/cooldown/index.lua')
  local firstPosition = { x = 1.2341, y = -2.3451, z = 3.0001 }
  local driftedPosition = { x = 1.2342, y = -2.3452, z = 3.0002 }

  cooldown.define('event', {
    initialDurationMs = 5000,
    durationMs = 10000,
  })

  context.callbacks['sure_lib:lib:cooldownGetOrInit'](10, 'event', firstPosition)
  context.events['sure_lib:lib:cooldownSet']('event', firstPosition, 9000)

  h.assertEqual(9000, context.callbacks['sure_lib:lib:cooldownGetOrInit'](10, 'event', driftedPosition))
end)

h.test('client cooldown rounds position keys to avoid floating point drift', function()
  local context = h.reset('client', {
    callbackResults = {
      ['sure_lib:lib:cooldownGetFirstTime'] = {
        event = {
          ['event_1.23:-2.35:3.00'] = 5000,
        },
      },
      ['sure_lib:lib:cooldownGetOrInit'] = function()
        error('unexpected server lookup')
      end,
    },
    esx = {
      IsPlayerLoaded = function()
        return true
      end,
    },
  })
  local cooldown = h.load('client/modules/cooldown/index.lua')

  h.assertEqual(5000, cooldown.getRemaining('event', { x = 1.2342, y = -2.3452, z = 3.0002 }))
end)
