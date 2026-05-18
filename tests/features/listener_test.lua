local h = require('tests.support.harness')

h.test('listener validates local event parameters before callback', function()
  local context = h.reset('client')
  local validator = h.load('shared/modules/validator/index.lua')
  local listener = h.load('shared/modules/listener/index.lua')
  local receivedPrefix = nil
  local receivedSuffix = nil

  listener
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

h.test('listener preserves boolean false arguments', function()
  local context = h.reset('client')
  local validator = h.load('shared/modules/validator/index.lua')
  local listener = h.load('shared/modules/listener/index.lua')
  local received = nil

  listener
    :on('toggle', function(value)
      received = value
    end)
    :expect(validator.boolean().required())

  context.events.toggle(false)

  h.assertFalse(received)
end)
