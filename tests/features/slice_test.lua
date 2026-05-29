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

h.test('slice ref mounts handler for each item on initial state', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local mounted = {}

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
        { key = 'b', value = 2 },
      },
    },
  })

  duty:ref('entities', function(item)
    mounted[item.key] = item.value
  end)

  h.assertEqual(1, mounted.a)
  h.assertEqual(2, mounted.b)
end)

h.test('slice ref only mounts newly added items on update', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local mountCalls = {}

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
      },
    },
  })

  duty:ref('entities', function(item)
    mountCalls[#mountCalls + 1] = item.key
  end)

  duty.state.entities = {
    { key = 'a', value = 1 },
    { key = 'b', value = 2 },
  }

  h.assertEqual(2, #mountCalls)
  h.assertEqual('a', mountCalls[1])
  h.assertEqual('b', mountCalls[2])
end)

h.test('slice ref runs cleanup only for removed items', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local cleaned = {}

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
        { key = 'b', value = 2 },
      },
    },
  })

  duty:ref('entities', function(item)
    return function()
      cleaned[#cleaned + 1] = item.key
    end
  end)

  duty.state.entities = {
    { key = 'a', value = 1 },
  }

  h.assertEqual(1, #cleaned)
  h.assertEqual('b', cleaned[1])
end)

h.test('slice ref remounts only items whose nested content changes', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local mountCount = { a = 0, b = 0 }
  local cleanupCount = { a = 0, b = 0 }

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', coords = { x = 0, y = 0, z = 0 } },
        { key = 'b', coords = { x = 1, y = 1, z = 1 } },
      },
    },
  })

  duty:ref('entities', function(item)
    mountCount[item.key] = mountCount[item.key] + 1
    return function()
      cleanupCount[item.key] = cleanupCount[item.key] + 1
    end
  end)

  duty.state.entities = {
    { key = 'a', coords = { x = 5, y = 5, z = 5 } },
    { key = 'b', coords = { x = 1, y = 1, z = 1 } },
  }

  h.assertEqual(2, mountCount.a)
  h.assertEqual(1, cleanupCount.a)
  h.assertEqual(1, mountCount.b)
  h.assertEqual(0, cleanupCount.b)
end)

h.test('slice ref skips reconciliation when array is structurally identical', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local mountCount = 0

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
      },
    },
  })

  duty:ref('entities', function()
    mountCount = mountCount + 1
  end)

  duty.state.entities = {
    { key = 'a', value = 1 },
  }

  h.assertEqual(1, mountCount)
end)

h.test('slice ref errors on duplicate keys', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
        { key = 'a', value = 2 },
      },
    },
  })

  h.assertErrorContains(function()
    duty:ref('entities', function() end)
  end, 'duplicate key a')
end)

h.test('slice ref errors when an item is missing the key field', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('world')({
    state = {
      entities = {
        { value = 1 },
      },
    },
  })

  h.assertErrorContains(function()
    duty:ref('entities', function() end)
  end, 'missing required field "key"')
end)

h.test('slice ref handler without a returned cleanup runs no cleanup on remove', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local cleaned = false

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
      },
    },
  })

  duty:ref('entities', function()
    -- no return = no cleanup
  end)

  duty.state.entities = {}

  h.assertFalse(cleaned)
end)

h.test('slice ref dispose unmounts all current items and stops watching', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local cleaned = {}
  local mountCount = 0

  local duty = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
        { key = 'b', value = 2 },
      },
    },
  })

  local dispose = duty:ref('entities', function(item)
    mountCount = mountCount + 1
    return function()
      cleaned[#cleaned + 1] = item.key
    end
  end)

  dispose()

  table.sort(cleaned)
  h.assertEqual(2, mountCount)
  h.assertEqual('a', cleaned[1])
  h.assertEqual('b', cleaned[2])

  duty.state.entities = {
    { key = 'c', value = 3 },
  }

  h.assertEqual(2, mountCount)
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
