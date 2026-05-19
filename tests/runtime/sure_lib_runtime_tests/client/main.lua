local h = RuntimeTest
local configPath = '@sure_lib_runtime_tests.config.runtime'

local function testPlayerHelpers()
  h.assertEqual('table', type(sure.player))
  h.assertPresent(sure.player.ped, 'sure.player.ped should be available')
  h.assertPresent(sure.player.coords, 'sure.player.coords should be available')
  h.assertPresent(sure.player.health, 'sure.player.health should be available')
end

local function testConfigLoad()
  local config = sure.getModule('config')
  local validator = sure.getModule('validator')
  local schema = validator.object({
    enabled = validator.boolean().required(),
    name = validator.string().required(),
    retryCount = validator.integer().min(0),
  })

  local value = config:reload(configPath, schema)

  h.assertTrue(value.enabled)
  h.assertEqual('sure_lib_runtime_tests', value.name)
end

local function testSpawnScopeCleanup()
  local spawn = sure.getModule('spawn')
  local scope = spawn:scope()
  local coords = GetEntityCoords(PlayerPedId())
  local object = scope:object('prop_beachflag_le', {
    x = coords.x + 1.0,
    y = coords.y,
    z = coords.z - 1.0,
  }, {
    alpha = 0,
    collision = false,
    freeze = true,
  })

  h.assertPresent(object, 'spawn:object should return an entity handle')
  h.assertTrue(DoesEntityExist(object), 'spawned object should exist before cleanup')

  scope:deleteAll()
  Wait(0)

  h.assertEqual(false, DoesEntityExist(object), 'scope:deleteAll should delete spawned objects')
end

local clientTests = {
  {
    name = 'sure.player exposes runtime player helpers',
    fn = testPlayerHelpers,
  },
  {
    name = 'config loads on client through sure.config',
    fn = testConfigLoad,
  },
  {
    name = 'spawn scope creates and cleans up an object',
    fn = testSpawnScopeCleanup,
  },
}

RegisterCommand('suretest:client', function()
  h.run('client', clientTests)
end, false)

RegisterNetEvent('sure_lib_runtime_tests:client:start', function()
  h.run('client', clientTests)
end)
