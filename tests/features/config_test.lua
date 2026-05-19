local h = require('tests.support.harness')

local function setupConfig(resourceFiles)
  local context = h.reset('shared', {
    resourceFiles = resourceFiles,
  })
  require('@sure_lib.init')

  return sure.getModule('config'), context
end

h.test('config loads and caches lua config files', function()
  local config, context = setupConfig({
    ['config/settings.lua'] = "return { shopName = 'Sure', taxRate = 0.1, coords = vector3(1, 2, 3) }",
  })

  local first = config:load('config/settings.lua')
  context.resourceFiles['config/settings.lua'] = "return { shopName = 'Changed', taxRate = 0.2 }"
  local cached = config:load('config/settings.lua')
  local reloaded = config:reload('config/settings.lua')

  h.assertEqual('Sure', first.shopName)
  h.assertEqual(1, first.coords.x)
  h.assertEqual(first, cached)
  h.assertEqual('Changed', reloaded.shopName)
  h.assertEqual('config.settings', context.loadedFiles[1].filePath)
  h.assertEqual('config.settings', context.loadedFiles[2].filePath)
  h.assertEqual(2, #context.loadedFiles)
end)

h.test('config validates optional schema fields', function()
  local config = setupConfig({
    ['config/settings.lua'] = 'return { shopName = 100 }',
  })
  local validator = sure.getModule('validator')
  local schema = validator.object({
    shopName = validator.string(),
  })

  h.assertErrorContains(function()
    config:load('config/settings.lua', schema)
  end, 'Expected type "string"')
end)

h.test('config validates cached values when a schema is supplied later', function()
  local config = setupConfig({
    ['config/settings.lua'] = 'return { shopName = 100 }',
  })
  local validator = sure.getModule('validator')

  config:load('config/settings.lua')

  h.assertErrorContains(function()
    config:load(
      'config/settings.lua',
      validator.object({
        shopName = validator.string(),
      })
    )
  end, 'Expected type "string"')
end)

h.test('config reports missing files with a helpful error', function()
  local config = setupConfig({})

  h.assertErrorContains(function()
    config:load('config/missing.lua')
  end, '[sure_lib][config] cannot load file: config/missing.lua')
end)
