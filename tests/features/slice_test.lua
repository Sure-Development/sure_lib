local h = require('tests.support.harness')

h.test('slice initialises reactive state and exposes actions', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({
    state = { onDuty = false, streak = 0 },
    actions = {
      toggle = function(s)
        s.state.onDuty = not s.state.onDuty
      end,
      bumpStreak = function(s, amount)
        s.state.streak = s.state.streak + amount
      end,
    },
  })

  h.assertEqual('duty', duty.name)
  h.assertFalse(duty.state.onDuty)

  duty.actions.toggle()
  h.assertTrue(duty.state.onDuty)

  duty.actions.bumpStreak(3)
  h.assertEqual(3, duty.state.streak)
end)

h.test('slice watch fires when state key changes and ignores no-op writes', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local changes = {}

  local duty = slice('duty')({
    state = { onDuty = false },
    watch = {
      onDuty = function(_, value, previous)
        changes[#changes + 1] = { previous = previous, value = value }
      end,
    },
  })

  duty.state.onDuty = true
  duty.state.onDuty = true
  duty.state.onDuty = false

  h.assertEqual(2, #changes)
  h.assertEqual(false, changes[1].previous)
  h.assertEqual(true, changes[1].value)
  h.assertEqual(true, changes[2].previous)
  h.assertEqual(false, changes[2].value)
end)

h.test('slice subscribe attaches an external watcher', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local seen = nil

  local duty = slice('duty')({
    state = { onDuty = false },
  })

  duty:subscribe('onDuty', function(value)
    seen = value
  end)

  duty.state.onDuty = true
  h.assertTrue(seen)
end)

h.test('slice on handler auto-prefixes local event names', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local received = nil

  slice('duty')({
    state = { onDuty = false },
    on = {
      sync = function(s, value)
        s.state.onDuty = value
        received = value
      end,
    },
  })

  context.events['duty:sync'](true)
  h.assertTrue(received)
end)

h.test('slice net handler auto-prefixes net event names', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({
    state = { onDuty = false },
    net = {
      sync = function(s, value)
        s.state.onDuty = value
      end,
    },
  })

  context.events['duty:sync'](true)
  h.assertTrue(duty.state.onDuty)
end)

h.test('slice emit prefixes local dispatch with the slice name', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({ state = {} })
  duty:emit('changed', 7)

  h.assertEqual('duty:changed', context.localEvents[1].name)
  h.assertEqual(7, context.localEvents[1].args[1])
end)

h.test('slice emitServer is client-only and prefixes event name', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({ state = {} })
  duty:emitServer('request', 'arg')

  h.assertEqual('duty:request', context.serverEvents[1].name)
  h.assertEqual('arg', context.serverEvents[1].args[1])
end)

h.test('slice emitClient is server-only and prefixes event name', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({ state = {} })
  duty:emitClient(5, 'sync', 'payload')

  h.assertEqual('duty:sync', context.clientEvents[1].name)
  h.assertEqual(5, context.clientEvents[1].target)
  h.assertEqual('payload', context.clientEvents[1].args[1])
end)

h.test('slice registers prefixed console commands', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local seen = nil

  slice('duty')({
    state = {},
    commands = {
      print = function(_, source, args)
        seen = { source = source, args = args }
      end,
    },
  })

  local command = context.commands['duty:print']
  h.assertTrue(command ~= nil)
  command.callback(0, { 'hello' }, 'duty:print hello')
  h.assertEqual(0, seen.source)
  h.assertEqual('hello', seen.args[1])
end)

h.test('slice onLoad fires when current resource starts', function()
  local context = h.reset('client', { resourceName = 'myResource' })
  local slice = h.load('shared/modules/slice/index.lua')
  local loaded = false

  slice('duty')({
    state = {},
    onLoad = function()
      loaded = true
    end,
  })

  local handler = context.events['onResourceStart']
  h.assertTrue(handler ~= nil)
  handler('otherResource')
  h.assertFalse(loaded)
  handler('myResource')
  h.assertTrue(loaded)
end)

h.test('slice snapshot returns a shallow copy of current state', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({
    state = { onDuty = true, streak = 5 },
  })

  local snap = duty:snapshot()
  duty.state.streak = 10

  h.assertEqual(true, snap.onDuty)
  h.assertEqual(5, snap.streak)
end)

h.test('slice rejects invalid spec or name', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  h.assertErrorContains(function()
    slice('')({ state = {} })
  end, 'name must be a non-empty string')

  h.assertErrorContains(function()
    slice('valid')('not a table')
  end, 'spec must be a table')
end)
