local h = require('tests.support.harness')

local function findLog(logs, needle)
  for _, message in ipairs(logs) do
    if tostring(message):find(needle, 1, true) ~= nil then
      return message
    end
  end

  return nil
end

h.test('doctor command reports all checks ok when dependencies are started', function()
  local context = h.reset('server', {
    resourceStates = {
      ox_lib = 'started',
      es_extended = 'started',
      oxmysql = 'started',
    },
    resourceMetadata = {
      ox_lib = { version = '3.20.0' },
    },
  })
  require('@sure_lib.init')
  h.load('server/init.lua')

  context.commands['sure_lib:doctor'].callback(0)

  h.assertTrue(findLog(context.logs.info, 'running diagnostics') ~= nil)
  h.assertTrue(findLog(context.logs.info, 'all checks passed') ~= nil)
end)

h.test('doctor command reports failing checks when a dependency is missing', function()
  local context = h.reset('server', {
    resourceStates = {
      ox_lib = 'started',
      es_extended = 'stopped',
      oxmysql = 'started',
    },
    resourceMetadata = {
      ox_lib = { version = '3.20.0' },
    },
  })
  require('@sure_lib.init')
  h.load('server/init.lua')

  context.commands['sure_lib:doctor'].callback(0)

  h.assertTrue(findLog(context.logs.info, 'check(s) failed') ~= nil)
end)

h.test('doctor command rejects non-console invocations', function()
  local context = h.reset('server')
  require('@sure_lib.init')
  h.load('server/init.lua')

  context.commands['sure_lib:doctor'].callback(1)

  h.assertEqual('[sure_lib][doctor] doctor command is console-only', context.logs.error[1])
end)
