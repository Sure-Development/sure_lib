local h = require('tests.support.harness')

h.test('keybind register forwards spec to lib.addKeybind', function()
  local context = h.reset('client')
  local keybind = h.load('client/modules/keybind/index.lua')

  local instance = keybind.register({
    name = 'reload',
    description = 'Reload',
    defaultKey = 'r',
    onPressed = function() end,
  })

  h.assertEqual(1, #context.keybinds)
  h.assertEqual('reload', context.keybinds[1].name)
  h.assertEqual('r', context.keybinds[1].defaultKey)
  h.assertEqual('keyboard', context.keybinds[1].defaultMapper)
  h.assertEqual(instance, keybind.get('reload'))
end)

h.test('keybind register is idempotent by name', function()
  local context = h.reset('client')
  local keybind = h.load('client/modules/keybind/index.lua')

  keybind.register({ name = 'shoot', description = 'Shoot', defaultKey = 'g' })
  keybind.register({ name = 'shoot', description = 'Shoot', defaultKey = 'h' })

  h.assertEqual(1, #context.keybinds)
end)

h.test('keybind disable and enable toggle disable on the instance', function()
  h.reset('client')
  local keybind = h.load('client/modules/keybind/index.lua')

  keybind.register({ name = 'jump', description = 'Jump', defaultKey = 'space' })
  keybind.disable('jump')

  h.assertEqual(true, keybind.get('jump').disabled)

  keybind.enable('jump')
  h.assertEqual(false, keybind.get('jump').disabled)
end)
