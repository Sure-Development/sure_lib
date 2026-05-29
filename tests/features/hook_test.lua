local h = require('tests.support.harness')

h.test('hook validates local event parameters before callback', function()
  local context = h.reset('client')
  local validator = h.load('shared/modules/validator/index.lua')
  local hook = h.load('shared/modules/hook/index.lua')
  local receivedPrefix = nil
  local receivedSuffix = nil

  hook
    :on('say', function(prefix, suffix)
      receivedPrefix = prefix
      receivedSuffix = suffix
    end)
    :expect(validator.string().required(), validator.string().required())

  context.events.say('hello', 'world')

  h.assertEqual('hello', receivedPrefix)
  h.assertEqual('world', receivedSuffix)
  h.assertErrorContains(function()
    context.events.say('hello', 2)
  end, 'Parameter index')
end)

h.test('hook preserves boolean false arguments', function()
  local context = h.reset('client')
  local validator = h.load('shared/modules/validator/index.lua')
  local hook = h.load('shared/modules/hook/index.lua')
  local received = nil

  hook
    :on('toggle', function(value)
      received = value
    end)
    :expect(validator.boolean().required())

  context.events.toggle(false)

  h.assertFalse(received)
end)

h.test('hook global middleware runs before handler', function()
  local context = h.reset('client')
  local hook = h.load('shared/modules/hook/index.lua')
  local trace = {}

  hook:use(function(ctx, next)
    trace[#trace + 1] = 'before:' .. ctx.name
    next()
    trace[#trace + 1] = 'after:' .. ctx.name
  end)

  hook:on('ping', function(value)
    trace[#trace + 1] = 'handle:' .. value
  end)

  context.events.ping('one')

  h.assertEqual('before:ping', trace[1])
  h.assertEqual('handle:one', trace[2])
  h.assertEqual('after:ping', trace[3])
end)

h.test('hook handler-scoped middleware can mutate args', function()
  local context = h.reset('client')
  local hook = h.load('shared/modules/hook/index.lua')
  local received = nil

  hook
    :on('multiply', function(value)
      received = value
    end)
    :use(function(ctx, next)
      ctx.args[1] = ctx.args[1] * 2
      next()
    end)

  context.events.multiply(5)

  h.assertEqual(10, received)
end)

h.test('hook middleware can short-circuit by not calling next', function()
  local context = h.reset('client')
  local hook = h.load('shared/modules/hook/index.lua')
  local called = false

  hook:use(function()
    -- intentionally do not call next
  end)

  hook:on('block', function()
    called = true
  end)

  context.events.block()

  h.assertFalse(called)
end)

h.test('hook dispatch fires registered local handlers', function()
  local context = h.reset('client')
  local hook = h.load('shared/modules/hook/index.lua')
  local received = nil

  hook:on('say', function(message)
    received = message
  end)

  hook:dispatch('say', 'cave')

  h.assertEqual('cave', received)
  h.assertEqual('say', context.localEvents[1].name)
end)

h.test('hook dispatchServer is client-only', function()
  h.reset('server')
  local hook = h.load('shared/modules/hook/index.lua')

  local ok, err = pcall(function()
    hook:dispatchServer('whatever')
  end)

  h.assertFalse(ok)
  h.assertTrue(tostring(err):find('client-only', 1, true) ~= nil)
end)

h.test('hook dispatchClient is server-only', function()
  h.reset('client')
  local hook = h.load('shared/modules/hook/index.lua')

  local ok, err = pcall(function()
    hook:dispatchClient(1, 'whatever')
  end)

  h.assertFalse(ok)
  h.assertTrue(tostring(err):find('server-only', 1, true) ~= nil)
end)

h.test('hook injectResource runs middleware before handler on same resource', function()
  local context = h.reset('client', { resourceName = 'resA' })
  local hook = h.load('shared/modules/hook/index.lua')
  local trace = {}

  hook:on('say', function(value)
    trace[#trace + 1] = 'handle:' .. value
  end)

  hook:injectResource('resA', 'say', function(ctx)
    trace[#trace + 1] = 'inject:' .. ctx.args[1]
  end)

  context.events.say('one')

  h.assertEqual('inject:one', trace[1])
  h.assertEqual('handle:one', trace[2])
end)

h.test('hook injectResource can mutate args', function()
  local context = h.reset('client', { resourceName = 'resA' })
  local hook = h.load('shared/modules/hook/index.lua')
  local received = nil

  hook:on('multiply', function(value)
    received = value
  end)

  hook:injectResource('resA', 'multiply', function(ctx)
    ctx.args[1] = ctx.args[1] * 3
  end)

  context.events.multiply(4)

  h.assertEqual(12, received)
end)

h.test('hook injectResource short-circuits via ctx.cancelled', function()
  local context = h.reset('client', { resourceName = 'resA' })
  local hook = h.load('shared/modules/hook/index.lua')
  local called = false

  hook:on('block', function()
    called = true
  end)

  hook:injectResource('resA', 'block', function(ctx)
    ctx.cancelled = true
  end)

  context.events.block()

  h.assertFalse(called)
end)

h.test('hook injectResource is silent when target resource is not started', function()
  local context = h.reset('client', { resourceName = 'resA' })
  local hook = h.load('shared/modules/hook/index.lua')

  hook:injectResource('ghostResource', 'say', function(ctx)
    ctx.args[1] = 'mutated'
  end)

  hook:on('say', function(value)
    context.localEvents = context.localEvents or {}
    context.received = value
  end)

  context.events.say('original')

  h.assertEqual('original', context.received)
end)

h.test('hook injectResource preserves order of multiple injections from same source', function()
  local context = h.reset('client', { resourceName = 'resA' })
  local hook = h.load('shared/modules/hook/index.lua')
  local trace = {}

  hook:on('chain', function(value)
    trace[#trace + 1] = 'handle:' .. value
  end)

  hook:injectResource('resA', 'chain', function(ctx)
    trace[#trace + 1] = 'first'
    ctx.args[1] = ctx.args[1] .. '-a'
  end)

  hook:injectResource('resA', 'chain', function(ctx)
    trace[#trace + 1] = 'second'
    ctx.args[1] = ctx.args[1] .. '-b'
  end)

  context.events.chain('start')

  h.assertEqual('first', trace[1])
  h.assertEqual('second', trace[2])
  h.assertEqual('handle:start-a-b', trace[3])
end)

h.test('hook injectResource rejects invalid arguments', function()
  h.reset('client', { resourceName = 'resA' })
  local hook = h.load('shared/modules/hook/index.lua')

  h.assertErrorContains(function()
    hook:injectResource('', 'say', function() end)
  end, 'targetResource is required')

  h.assertErrorContains(function()
    hook:injectResource('resB', '', function() end)
  end, 'hookName is required')

  h.assertErrorContains(function()
    hook:injectResource('resB', 'say', 'not a function')
  end, 'middleware must be a function')
end)
