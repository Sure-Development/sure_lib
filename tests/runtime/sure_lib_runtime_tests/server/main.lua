local h = RuntimeTest
local configPath = '@sure_lib_runtime_tests.config.runtime'

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
  h.assertEqual(2, value.retryCount)
end

local function testValidator()
  local validator = sure.getModule('validator')
  local schema = validator.object({
    name = validator.string().required(),
    count = validator.integer().between(1, 3),
  })

  h.assertTrue(schema.parse({
    name = 'runtime',
    count = 2,
  }))
end

local function testDbSafetyGuards()
  local db = sure.getModule('db')
  local users = db:schema('runtime_users', {
    tableName = 'sure_lib_runtime_users',
  })

  h.assertNil(users:update({
    data = {
      name = 'unsafe',
    },
  }))
  h.assertNil(users:delete({}))
end

local function testDbCrudWhenEnabled()
  if GetConvar('sure_lib_runtime_db', 'false') ~= 'true' then
    lib.print.info('[sure_lib_runtime_tests] skipped db crud test; setr sure_lib_runtime_db true to enable it')
    return
  end

  local db = sure.getModule('db')
  local users = db:schema('runtime_users', {
    tableName = 'sure_lib_runtime_users',
  })

  exports.oxmysql:execute_async('DROP TABLE IF EXISTS `sure_lib_runtime_users`', {})
  exports.oxmysql:execute_async(
    [[
CREATE TABLE `sure_lib_runtime_users` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `cash` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
]],
    {}
  )

  local id = users:create({
    data = {
      name = 'runtime',
      cash = 10,
    },
  })
  h.assertPresent(id, 'insert should return an id')

  local row = users:findFirst({
    where = {
      id = id,
    },
  })
  h.assertEqual('runtime', row.name)
  h.assertEqual(10, row.cash)

  users:update({
    data = {
      cash = 25,
    },
    where = {
      id = id,
    },
  })

  row = users:findFirst({
    where = {
      id = id,
    },
  })
  h.assertEqual(25, row.cash)

  users:delete({
    where = {
      id = id,
    },
  })

  row = users:findFirst({
    where = {
      id = id,
    },
  })
  h.assertNil(row)

  exports.oxmysql:execute_async('DROP TABLE IF EXISTS `sure_lib_runtime_users`', {})
end

local serverTests = {
  {
    name = 'config loads through sure.config with schema validation',
    fn = testConfigLoad,
  },
  {
    name = 'validator parses runtime object schemas',
    fn = testValidator,
  },
  {
    name = 'db update and delete guard missing where clauses',
    fn = testDbSafetyGuards,
  },
  {
    name = 'db crud works against oxmysql when enabled',
    fn = testDbCrudWhenEnabled,
  },
}

RegisterCommand('suretest:server', function(source)
  if source ~= 0 then
    lib.print.error('[sure_lib_runtime_tests] run suretest:server from the server console')
    return
  end

  h.run('server', serverTests)
end, true)

RegisterCommand('suretest:all', function(source)
  h.run('server', serverTests)

  if source > 0 then
    TriggerClientEvent('sure_lib_runtime_tests:client:start', source)
  else
    lib.print.info('[sure_lib_runtime_tests] run suretest:client from an in-game F8 console for client tests')
  end
end, false)
