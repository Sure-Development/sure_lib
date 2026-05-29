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

h.test('slice ref auto-disposes every active item when the resource stops', function()
  local context = h.reset('client', { resourceName = 'myResource' })
  local slice = h.load('shared/modules/slice/index.lua')
  local cleaned = {}

  local world = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
        { key = 'b', value = 2 },
      },
    },
  })

  world:ref('entities', function(item)
    return function()
      cleaned[#cleaned + 1] = item.key
    end
  end)

  local handler = context.events['onResourceStop']
  h.assertTrue(handler ~= nil)
  handler('otherResource')
  h.assertEqual(0, #cleaned)

  handler('myResource')
  table.sort(cleaned)
  h.assertEqual(2, #cleaned)
  h.assertEqual('a', cleaned[1])
  h.assertEqual('b', cleaned[2])
end)

h.test('slice ref auto-dispose runs after spec.onUnload', function()
  local context = h.reset('client', { resourceName = 'myResource' })
  local slice = h.load('shared/modules/slice/index.lua')
  local order = {}

  local world = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
      },
    },
    onUnload = function()
      order[#order + 1] = 'onUnload'
    end,
  })

  world:ref('entities', function()
    return function()
      order[#order + 1] = 'refDispose'
    end
  end)

  context.events['onResourceStop']('myResource')

  h.assertEqual('onUnload', order[1])
  h.assertEqual('refDispose', order[2])
end)

h.test('slice unmount drops a single item and triggers ref cleanup', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local cleaned = {}

  local world = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
        { key = 'b', value = 2 },
      },
    },
  })

  world:ref('entities', function(item)
    return function()
      cleaned[#cleaned + 1] = item.key
    end
  end)

  world:unmount('entities', 'a')

  h.assertEqual(1, #cleaned)
  h.assertEqual('a', cleaned[1])
  h.assertEqual(1, #world.state.entities)
  h.assertEqual('b', world.state.entities[1].key)
end)

h.test('slice unmount is a no-op when the item key is missing', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local cleaned = {}

  local world = slice('world')({
    state = {
      entities = {
        { key = 'a', value = 1 },
      },
    },
  })

  world:ref('entities', function(item)
    return function()
      cleaned[#cleaned + 1] = item.key
    end
  end)

  world:unmount('entities', 'ghost')

  h.assertEqual(0, #cleaned)
  h.assertEqual(1, #world.state.entities)
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

h.test('slice scope add stores player ids and lists them', function()
  h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({ state = {} })
  local farmers = world:scope('farmers')

  farmers:add(1)
  farmers:add(2)
  farmers:add(1)

  local list = farmers:list()
  table.sort(list)
  h.assertEqual(2, #list)
  h.assertEqual(1, list[1])
  h.assertEqual(2, list[2])
  h.assertTrue(farmers:contains(1))
  h.assertFalse(farmers:contains(99))

  farmers:remove(1)
  h.assertFalse(farmers:contains(1))
end)

h.test('slice scope resolves ESX identifiers via ESX.GetPlayerFromIdentifier', function()
  h.reset('server')
  _G.ESX = {
    GetPlayerFromIdentifier = function(identifier)
      if identifier == 'license:abc' then
        return { source = 42 }
      end
      return nil
    end,
  }

  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({ state = {} })
  local farmers = world:scope('farmers')

  farmers:add('license:abc')
  farmers:add('license:missing')

  local list = farmers:list()
  h.assertEqual(1, #list)
  h.assertEqual(42, list[1])
  h.assertTrue(farmers:contains(42))
end)

h.test('slice netSync sender broadcasts state changes to all clients by default', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { count = 0 },
    netSync = { count = 'sender' },
  })

  world.state.count = 7

  h.assertEqual(1, #context.clientEvents)
  h.assertEqual('world:sync:count', context.clientEvents[1].name)
  h.assertEqual(-1, context.clientEvents[1].target)
  h.assertEqual(7, context.clientEvents[1].args[1])
end)

h.test('slice netSync sender with scope emits only to scope members', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { count = 0 },
    netSync = {
      count = { direction = 'sender', scope = 'farmers' },
    },
  })

  local farmers = world:scope('farmers')

  context.clientEvents = {}
  world.state.count = 1
  h.assertEqual(0, #context.clientEvents)

  farmers:add(5)
  h.assertEqual(1, #context.clientEvents)
  h.assertEqual(5, context.clientEvents[1].target)
  h.assertEqual(1, context.clientEvents[1].args[1])

  context.clientEvents = {}
  world.state.count = 2
  h.assertEqual(1, #context.clientEvents)
  h.assertEqual(5, context.clientEvents[1].target)
  h.assertEqual(2, context.clientEvents[1].args[1])

  farmers:add(6)
  h.assertEqual(2, #context.clientEvents)
  h.assertEqual(6, context.clientEvents[2].target)
  h.assertEqual(2, context.clientEvents[2].args[1])

  context.clientEvents = {}
  world.state.count = 3
  table.sort(context.clientEvents, function(a, b)
    return a.target < b.target
  end)
  h.assertEqual(2, #context.clientEvents)
  h.assertEqual(5, context.clientEvents[1].target)
  h.assertEqual(6, context.clientEvents[2].target)
end)

h.test('slice netSync sender with diff sends full value on first emit then patches', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { entities = {} },
    netSync = {
      entities = { direction = 'sender', diff = true },
    },
  })

  world.state.entities = {
    { key = 'a', value = 1 },
    { key = 'b', value = 2 },
  }

  h.assertEqual(1, #context.clientEvents)
  local first = context.clientEvents[1].args[1]
  h.assertTrue(first.full ~= nil)
  h.assertEqual(2, #first.full)

  context.clientEvents = {}

  world.state.entities = {
    { key = 'a', value = 1 },
    { key = 'b', value = 2 },
    { key = 'c', value = 3 },
  }

  h.assertEqual(1, #context.clientEvents)
  local patch = context.clientEvents[1].args[1].patch
  h.assertTrue(patch ~= nil)
  h.assertEqual(1, #patch.added)
  h.assertEqual('c', patch.added[1].key)
  h.assertEqual(0, #patch.removed)
  h.assertEqual(0, #patch.changed)
end)

h.test('slice netSync diff skips emit when patch is empty', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { entities = {} },
    netSync = {
      entities = { direction = 'sender', diff = true },
    },
  })

  world.state.entities = { { key = 'a', value = 1 } }
  context.clientEvents = {}

  world.state.entities = { { key = 'a', value = 1 } }

  h.assertEqual(0, #context.clientEvents)
end)

h.test('slice netSync diff emits patch with removed and changed', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { entities = {} },
    netSync = {
      entities = { direction = 'sender', diff = true },
    },
  })

  world.state.entities = {
    { key = 'a', value = 1 },
    { key = 'b', value = 2 },
    { key = 'c', value = 3 },
  }
  context.clientEvents = {}

  world.state.entities = {
    { key = 'a', value = 1 },
    { key = 'b', value = 99 },
  }

  local patch = context.clientEvents[1].args[1].patch
  h.assertEqual(0, #patch.added)
  h.assertEqual(1, #patch.removed)
  h.assertEqual('c', patch.removed[1])
  h.assertEqual(1, #patch.changed)
  h.assertEqual('b', patch.changed[1].key)
  h.assertEqual(99, patch.changed[1].value)
end)

h.test('slice netSync diff scope sends full value to newly added players', function()
  local context = h.reset('server')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { entities = {} },
    netSync = {
      entities = { direction = 'sender', diff = true, scope = 'farmers' },
    },
  })

  world.state.entities = { { key = 'a', value = 1 } }
  context.clientEvents = {}

  world:scope('farmers'):add(5)

  h.assertEqual(1, #context.clientEvents)
  h.assertEqual(5, context.clientEvents[1].target)
  local payload = context.clientEvents[1].args[1]
  h.assertTrue(payload.full ~= nil)
  h.assertEqual(1, #payload.full)
  h.assertEqual('a', payload.full[1].key)
end)

h.test('slice netSync diff receiver applies patches onto state', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { entities = {} },
    netSync = {
      entities = { direction = 'receiver', diff = true },
    },
  })

  local handler = context.events['world:sync:entities']
  handler({ full = { { key = 'a', value = 1 }, { key = 'b', value = 2 } } })
  h.assertEqual(2, #world.state.entities)

  handler({ patch = { added = { { key = 'c', value = 3 } }, removed = { 'a' }, changed = {} } })

  table.sort(world.state.entities, function(a, b)
    return a.key < b.key
  end)
  h.assertEqual(2, #world.state.entities)
  h.assertEqual('b', world.state.entities[1].key)
  h.assertEqual('c', world.state.entities[2].key)
end)

h.test('slice netSync receiver mirrors incoming net events into state', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { count = 0 },
    netSync = { count = 'receiver' },
  })

  local handler = context.events['world:sync:count']
  h.assertTrue(handler ~= nil)
  handler(42)
  h.assertEqual(42, world.state.count)
end)

h.test('slice netSync sender on client triggers a server event', function()
  local context = h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = { count = 0 },
    netSync = { count = 'sender' },
  })

  world.state.count = 5
  h.assertEqual(1, #context.serverEvents)
  h.assertEqual('world:sync:count', context.serverEvents[1].name)
  h.assertEqual(5, context.serverEvents[1].args[1])
end)

h.test('slice transaction fires each watcher once with net change', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local fires = { onDuty = 0, streak = 0 }
  local seen = {}

  local duty = slice('duty')({
    state = { onDuty = false, streak = 0 },
    watch = {
      onDuty = function(_, value, previous)
        fires.onDuty = fires.onDuty + 1
        seen.onDuty = { value = value, previous = previous }
      end,
      streak = function(_, value, previous)
        fires.streak = fires.streak + 1
        seen.streak = { value = value, previous = previous }
      end,
    },
  })

  duty:transaction(function(s)
    s.state.onDuty = true
    s.state.streak = 1
    s.state.streak = 2
    s.state.streak = 3
  end)

  h.assertEqual(1, fires.onDuty)
  h.assertEqual(1, fires.streak)
  h.assertEqual(true, seen.onDuty.value)
  h.assertEqual(false, seen.onDuty.previous)
  h.assertEqual(3, seen.streak.value)
  h.assertEqual(0, seen.streak.previous)
end)

h.test('slice transaction skips watcher when value ends at original', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local fires = 0

  local duty = slice('duty')({
    state = { onDuty = false },
    watch = {
      onDuty = function()
        fires = fires + 1
      end,
    },
  })

  duty:transaction(function(s)
    s.state.onDuty = true
    s.state.onDuty = false
  end)

  h.assertEqual(0, fires)
end)

h.test('slice transaction handles nested calls and commits only at outer end', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')
  local fires = 0

  local duty = slice('duty')({
    state = { streak = 0 },
    watch = {
      streak = function()
        fires = fires + 1
      end,
    },
  })

  duty:transaction(function(s)
    s.state.streak = 1
    duty:transaction(function(inner)
      inner.state.streak = 2
    end)
    h.assertEqual(0, fires)
    s.state.streak = 3
  end)

  h.assertEqual(1, fires)
  h.assertEqual(3, duty.state.streak)
end)

h.test('slice auto-generates setX actions for every state key', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({
    state = {
      onDuty = false,
      streak = 0,
    },
  })

  h.assertTrue(type(duty.actions.setOnDuty) == 'function')
  h.assertTrue(type(duty.actions.setStreak) == 'function')

  duty.actions.setOnDuty(true)
  h.assertTrue(duty.state.onDuty)

  duty.actions.setStreak(7)
  h.assertEqual(7, duty.state.streak)
end)

h.test('slice spec.actions overrides auto-generated setters with the same name', function()
  h.reset('client')
  local slice = h.load('shared/modules/slice/index.lua')

  local duty = slice('duty')({
    state = { onDuty = false },
    actions = {
      setOnDuty = function(s, value)
        s.state.onDuty = value
        return 'custom'
      end,
    },
  })

  local result = duty.actions.setOnDuty(true)
  h.assertEqual('custom', result)
  h.assertTrue(duty.state.onDuty)
end)

h.test('slice every fires each interval when enough time has elapsed', function()
  h.reset('client')
  _G.CreateThread = function() end
  local slice = h.load('shared/modules/slice/index.lua')
  local ticks = { [500] = 0, [1500] = 0 }

  local world = slice('world')({
    state = {},
    every = {
      [500] = function()
        ticks[500] = ticks[500] + 1
      end,
      [1500] = function()
        ticks[1500] = ticks[1500] + 1
      end,
    },
  })

  world:_tickEvery(0)
  h.assertEqual(0, ticks[500])
  h.assertEqual(0, ticks[1500])

  world:_tickEvery(500)
  h.assertEqual(1, ticks[500])
  h.assertEqual(0, ticks[1500])

  world:_tickEvery(750)
  h.assertEqual(1, ticks[500])

  world:_tickEvery(1000)
  h.assertEqual(2, ticks[500])
  h.assertEqual(0, ticks[1500])

  world:_tickEvery(1500)
  h.assertEqual(3, ticks[500])
  h.assertEqual(1, ticks[1500])
end)

h.test('slice every returns the next due interval as suggested sleep', function()
  h.reset('client')
  _G.CreateThread = function() end
  local slice = h.load('shared/modules/slice/index.lua')

  local world = slice('world')({
    state = {},
    every = {
      [500] = function() end,
      [1500] = function() end,
    },
  })

  world:_tickEvery(0)
  local sleep = world:_tickEvery(100)
  h.assertEqual(400, sleep)

  sleep = world:_tickEvery(500)
  h.assertEqual(500, sleep)

  sleep = world:_tickEvery(1500)
  h.assertEqual(500, sleep)
end)

h.test('slice every ignores invalid entries', function()
  h.reset('client')
  _G.CreateThread = function() end
  local slice = h.load('shared/modules/slice/index.lua')
  local valid = 0

  local world = slice('world')({
    state = {},
    every = {
      [500] = function()
        valid = valid + 1
      end,
      [-100] = function()
        valid = valid + 1
      end,
      ['bad'] = function()
        valid = valid + 1
      end,
      [200] = 'not a function',
    },
  })

  world:_tickEvery(0)
  world:_tickEvery(1000)
  h.assertEqual(1, valid)
  world:_tickEvery(1500)
  h.assertEqual(2, valid)
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
