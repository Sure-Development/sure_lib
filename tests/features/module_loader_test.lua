local h = require('tests.support.harness')

h.test('sure.getModule loads shared modules from the sure_lib resource', function()
  h.reset('client')
  require('@sure_lib.init')

  local validator = sure.getModule('validator')

  h.assertTrue(validator.string().parse('ok'))
end)

h.test('sure.getModule resolves side-specific modules', function()
  h.reset('server', {
    esx = {
      GetPlayerFromId = function()
        return nil
      end,
    },
  })
  require('@sure_lib.init')

  local esx = sure.getModule('esx')

  h.assertEqual('function', type(esx.transactions))
  h.assertNil(esx.waitPlayerLoaded)
end)

h.test('sure.getModule returns nil for unknown modules', function()
  h.reset('client')
  require('@sure_lib.init')

  h.assertNil(sure.getModule('missing'))
end)
