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

h.test('track functional setter composes concurrent increments from latest state', function()
  h.reset('shared')
  local reactive = h.load('shared/modules/track/index.lua')
  local count, setCount = reactive.state('count', 0)

  local increment = function(value)
    return value + 1
  end

  setCount(increment)
  setCount(increment)
  setCount(increment)

  h.assertEqual(3, count())
end)

h.test('track effect returns a dispose that stops notifications', function()
  h.reset('shared')
  local reactive = h.load('shared/modules/track/index.lua')
  local count, setCount = reactive.state('count', 0)
  local calls = 0

  local dispose = reactive.effect(function()
    calls = calls + 1
  end, { count })

  setCount(1)
  dispose()
  setCount(2)

  h.assertEqual(1, calls)
end)

h.test('track computed derives a state from its dependencies', function()
  h.reset('shared')
  local reactive = h.load('shared/modules/track/index.lua')
  local price, setPrice = reactive.state('price', 10)
  local total = reactive.computed('total', function()
    return price() * 2
  end, { price })

  h.assertEqual(20, total())

  setPrice(15)

  h.assertEqual(30, total())
end)
