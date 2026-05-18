local h = require('tests.support.harness')

h.test('track getter returns initial value and setter notifies dependencies', function()
  h.reset('shared')
  local reactive = h.load('shared/modules/track/index.lua')
  local amount, setAmount = reactive.state('amount', 1)
  local calls = 0
  local lastValue = nil

  reactive.effect(function()
    calls = calls + 1
    lastValue = amount()
  end, { amount })

  setAmount(2)

  h.assertEqual(2, amount())
  h.assertEqual(1, calls)
  h.assertEqual(2, lastValue)
end)

h.test('track does not notify unrelated dependencies', function()
  h.reset('shared')
  local reactive = h.load('shared/modules/track/index.lua')
  local amount, setAmount = reactive.state('amount', 1)
  local item = reactive.state('item', 'bread')
  local calls = 0

  reactive.effect(function()
    calls = calls + 1
  end, { item })

  setAmount(2)

  h.assertEqual(2, amount())
  h.assertEqual(0, calls)
end)

h.test('track clones table values on read boundary', function()
  h.reset('shared')
  local reactive = h.load('shared/modules/track/index.lua')
  local value, setValue = reactive.state('state', { count = 1 })
  local initial = value()

  initial.count = 99
  setValue({ count = 2 })

  h.assertEqual(2, value().count)
end)
