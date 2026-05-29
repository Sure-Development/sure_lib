local h = require('tests.support.harness')

h.test('log level filter suppresses messages below threshold', function()
  local context = h.reset('shared')
  local log = h.load('shared/modules/log/index.lua')

  log.setLevel('warn')
  log.info('hidden')
  log.warn('shown')

  h.assertEqual(0, #context.logs.info)
  h.assertEqual(1, #context.logs.error)
  h.assertTrue(context.logs.error[1]:find('shown', 1, true) ~= nil)
end)

h.test('log create returns a tagged logger', function()
  local context = h.reset('shared')
  local log = h.load('shared/modules/log/index.lua')

  log.setLevel('debug')
  local logger = log.create('inventory')
  logger:info('hello')

  h.assertEqual('[inventory] hello', context.logs.info[1])
end)

h.test('log error always reaches lib.print.error', function()
  local context = h.reset('shared')
  local log = h.load('shared/modules/log/index.lua')

  log.setLevel('info')
  log.error('boom')

  h.assertEqual(1, #context.logs.error)
  h.assertTrue(context.logs.error[1]:find('boom', 1, true) ~= nil)
end)
