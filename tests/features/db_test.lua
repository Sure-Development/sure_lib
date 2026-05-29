local h = require('tests.support.harness')

h.test('db model builds stable findMany queries', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local users = db:schema('users', {
    tableName = 'players',
  })

  users:findMany({
    where = {
      identifier = 'license:abc',
      id = 10,
    },
  })

  h.assertEqual('query_async', context.mysqlQueries[1].method)
  h.assertEqual('SELECT * FROM `players` WHERE `id` = ? AND `identifier` = ?', context.mysqlQueries[1].sql)
  h.assertEqual(10, context.mysqlQueries[1].params[1])
  h.assertEqual('license:abc', context.mysqlQueries[1].params[2])
end)

h.test('db model builds stable insert queries', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local users = db:schema('users', {
    tableName = 'players',
  })

  local insertId = users:create({
    data = {
      name = 'sure',
      id = 5,
    },
  })

  h.assertEqual(1, insertId)
  h.assertEqual('insert_async', context.mysqlQueries[1].method)
  h.assertEqual('INSERT INTO `players` (`id`, `name`) VALUES (?, ?)', context.mysqlQueries[1].sql)
  h.assertEqual(5, context.mysqlQueries[1].params[1])
  h.assertEqual('sure', context.mysqlQueries[1].params[2])
end)

h.test('db update and delete require where clauses', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local users = db:schema('users', {
    tableName = 'players',
  })

  h.assertNil(users:update({
    data = {
      name = 'danger',
    },
  }))
  h.assertNil(users:delete({}))

  h.assertEqual(0, #context.mysqlQueries)
  h.assertEqual('[sure_lib][db] update requires a where clause on table: players', context.logs.error[1])
  h.assertEqual('[sure_lib][db] delete requires a where clause on table: players', context.logs.error[2])
end)

h.test('db delete uses execute_async with a required where clause', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local users = db:schema('users', {
    tableName = 'players',
  })

  users:delete({
    where = {
      id = 5,
    },
  })

  h.assertEqual('execute_async', context.mysqlQueries[1].method)
  h.assertEqual('DELETE FROM `players` WHERE `id` = ?', context.mysqlQueries[1].sql)
  h.assertEqual(5, context.mysqlQueries[1].params[1])
end)

h.test('db schema array fields preserve create table order', function()
  local context = h.reset('server', {
    resourceFiles = {
      ['db/ordered.lua'] = [[
local db = sure.getModule('db')

return db:schema('ordered', {
  fields = {
    { 'id', { type = 'integer', primaryKey = true, autoIncrement = true, nullable = false } },
    { 'steam', { type = 'string', length = 64, nullable = false } },
    { 'cash', { type = 'integer', default = 0 } },
  },
})
]],
    },
  })

  h.load('server/modules/db/index.lua')
  context.commands['sure_lib:db'].callback(0, { 'push', 'ordered' })

  local createQuery = context.mysqlQueries[2]
  h.assertEqual('execute_async', createQuery.method)

  local sql = createQuery.sql
  local idIndex = sql:find('`id` INT', 1, true)
  local steamIndex = sql:find('`steam` VARCHAR(64)', 1, true)
  local cashIndex = sql:find('`cash` INT', 1, true)

  h.assertTrue(idIndex < steamIndex)
  h.assertTrue(steamIndex < cashIndex)
end)

h.test('db console push loads schema files and creates tables', function()
  local context = h.reset('server', {
    resourceFiles = {
      ['db/users.lua'] = [[
local db = sure.getModule('db')

return db:schema('users', {
  fields = {
    id = { type = 'integer', primaryKey = true, autoIncrement = true, nullable = false },
    name = { type = 'string', length = 50, nullable = false },
    createdAt = { type = 'timestamp', default = 'CURRENT_TIMESTAMP' },
  },
})
]],
    },
  })

  h.load('server/modules/db/index.lua')
  context.commands['sure_lib:db'].callback(0, { 'push', 'users' })

  h.assertEqual('query_async', context.mysqlQueries[1].method)
  h.assertTrue(context.mysqlQueries[1].sql:find('INFORMATION_SCHEMA.COLUMNS', 1, true) ~= nil)
  h.assertEqual('execute_async', context.mysqlQueries[2].method)
  h.assertTrue(context.mysqlQueries[2].sql:find('CREATE TABLE IF NOT EXISTS `users`', 1, true) ~= nil)
  h.assertTrue(context.mysqlQueries[2].sql:find('`createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP', 1, true) ~= nil)
  h.assertTrue(context.mysqlQueries[2].sql:find('PRIMARY KEY (`id`)', 1, true) ~= nil)
  h.assertEqual("[sure_lib][db] pushed -> table 'users' is ready", context.logs.info[1])
end)

h.test('db console pull writes schema files from database columns', function()
  local context = h.reset('server')
  exports.oxmysql.query_async = function(_, sql, params)
    context.mysqlQueries[#context.mysqlQueries + 1] = {
      method = 'query_async',
      sql = sql,
      params = params,
    }

    return {
      {
        COLUMN_NAME = 'id',
        COLUMN_TYPE = 'int(11)',
        IS_NULLABLE = 'NO',
        COLUMN_DEFAULT = nil,
        COLUMN_KEY = 'PRI',
        EXTRA = 'auto_increment',
      },
      {
        COLUMN_NAME = 'local',
        COLUMN_TYPE = 'varchar(50)',
        IS_NULLABLE = 'NO',
        COLUMN_DEFAULT = nil,
        COLUMN_KEY = '',
        EXTRA = '',
      },
    }
  end

  h.load('server/modules/db/index.lua')
  context.commands['sure_lib:db'].callback(0, { 'pull', 'users' })

  local content = context.savedResourceFiles['db/users.lua']

  h.assertTrue(content:find("return db:schema('users'", 1, true) ~= nil)
  h.assertTrue(content:find("id = { type = 'integer', primaryKey = true, autoIncrement = true, nullable = false }", 1, true) ~= nil)
  h.assertTrue(content:find("['local'] = { type = 'string', length = 50, nullable = false }", 1, true) ~= nil)
  h.assertEqual("[sure_lib][db] pulled 'users' -> db/users.lua", context.logs.info[1])
end)

h.test('db pull treats empty column results as not found', function()
  local context = h.reset('server')
  h.load('server/modules/db/index.lua')

  context.commands['sure_lib:db'].callback(0, { 'pull', 'missing' })

  h.assertEqual("[sure_lib][db] table 'missing' not found", context.logs.error[1])
end)

h.test('server init registers the resource-prefixed db console command', function()
  local context = h.reset('server')
  require('@sure_lib.init')
  h.load('server/init.lua')

  h.assertNil(context.commands.db)
  h.assertEqual('function', type(context.commands['sure_lib:db'].callback))
end)

h.test('db console command reports errors through ox_lib print helpers', function()
  local context = h.reset('server')
  h.load('server/modules/db/index.lua')

  context.commands['sure_lib:db'].callback(1, { 'push', 'users' })
  context.commands['sure_lib:db'].callback(0, { 'push', 'missing' })
  context.commands['sure_lib:db'].callback(0, {})

  h.assertEqual('[sure_lib][db] db commands are console-only', context.logs.error[1])
  h.assertEqual('[sure_lib][db] schema file not found: db/missing.lua', context.logs.error[2])
  h.assertEqual('[sure_lib][db] usage: sure_lib:db push <schemaName> | sure_lib:db pull <targetTable>', context.logs.info[1])
end)

h.test('db count returns COUNT(*) of the matching rows', function()
  local context = h.reset('server')
  exports.oxmysql.query_async = function(_, sql, params)
    context.mysqlQueries[#context.mysqlQueries + 1] = {
      method = 'query_async',
      sql = sql,
      params = params,
    }

    return { { count = 7 } }
  end

  local db = h.load('server/modules/db/index.lua')
  local users = db:schema('users', { tableName = 'players' })

  local total = users:count({ where = { job = 'police' } })

  h.assertEqual(7, total)
  h.assertEqual('SELECT COUNT(*) AS `count` FROM `players` WHERE `job` = ?', context.mysqlQueries[1].sql)
end)

h.test('db findMany supports select, orderBy, limit and offset', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local users = db:schema('users', { tableName = 'players' })

  users:findMany({
    select = { 'id', 'name' },
    where = { active = 1 },
    orderBy = { { 'created_at', 'desc' }, 'id' },
    limit = 25,
    offset = 50,
  })

  local sql = context.mysqlQueries[1].sql
  h.assertEqual('SELECT `id`, `name` FROM `players` WHERE `active` = ? ORDER BY `created_at` DESC, `id` ASC LIMIT 25 OFFSET 50', sql)
end)

h.test('db upsert builds INSERT ... ON DUPLICATE KEY UPDATE', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local duty = db:schema('duty', { tableName = 'nrq_duty' })

  duty:upsert({
    data = { identifier = 'license:abc', duty = 1 },
  })

  local query = context.mysqlQueries[1]
  h.assertEqual('insert_async', query.method)
  h.assertEqual('INSERT INTO `nrq_duty` (`duty`, `identifier`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `duty` = ?, `identifier` = ?', query.sql)
end)

h.test('db upsert lets caller override the update clause', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local model = db:schema('counters', { tableName = 'counters' })

  model:upsert({
    data = { name = 'kills', value = 1 },
    update = { value = 1 },
  })

  local query = context.mysqlQueries[1]
  h.assertEqual('INSERT INTO `counters` (`name`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?', query.sql)
end)

h.test('db bulkInsert emits a single INSERT statement', function()
  local context = h.reset('server')
  local db = h.load('server/modules/db/index.lua')
  local model = db:schema('items', { tableName = 'items' })

  model:bulkInsert({
    data = {
      { name = 'apple', amount = 1 },
      { name = 'banana', amount = 2 },
      { name = 'cherry', amount = 3 },
    },
  })

  local query = context.mysqlQueries[1]
  h.assertEqual('insert_async', query.method)
  h.assertEqual('INSERT INTO `items` (`amount`, `name`) VALUES (?, ?), (?, ?), (?, ?)', query.sql)
  h.assertEqual(1, query.params[1])
  h.assertEqual('apple', query.params[2])
  h.assertEqual(3, query.params[5])
  h.assertEqual('cherry', query.params[6])
end)

h.test('db transaction forwards rows to oxmysql transaction_async', function()
  local context = h.reset('server')
  context.transactionCalls = {}
  exports.oxmysql.transaction_async = function(_, queries)
    context.transactionCalls[#context.transactionCalls + 1] = queries
    return true
  end

  local db = h.load('server/modules/db/index.lua')

  local ok = db:transaction({
    { query = 'UPDATE players SET cash = cash - ? WHERE id = ?', values = { 50, 1 } },
    { query = 'UPDATE players SET cash = cash + ? WHERE id = ?', values = { 50, 2 } },
  })

  h.assertTrue(ok)
  h.assertEqual(2, #context.transactionCalls[1])
end)

h.test('db push alters table to add missing columns', function()
  local context = h.reset('server', {
    resourceFiles = {
      ['db/players.lua'] = [[
local db = sure.getModule('db')

return db:schema('players', {
  fields = {
    { 'id', { type = 'integer', primaryKey = true, autoIncrement = true, nullable = false } },
    { 'name', { type = 'string', length = 50, nullable = false } },
    { 'cash', { type = 'integer', default = 0 } },
  },
})
]],
    },
  })

  exports.oxmysql.query_async = function(_, sql, params)
    context.mysqlQueries[#context.mysqlQueries + 1] = {
      method = 'query_async',
      sql = sql,
      params = params or {},
    }

    return {
      { COLUMN_NAME = 'id' },
      { COLUMN_NAME = 'name' },
    }
  end

  h.load('server/modules/db/index.lua')
  context.commands['sure_lib:db'].callback(0, { 'push', 'players' })

  h.assertEqual('execute_async', context.mysqlQueries[2].method)
  h.assertEqual('ALTER TABLE `players` ADD COLUMN `cash` INT DEFAULT 0', context.mysqlQueries[2].sql)
  h.assertEqual("[sure_lib][db] pushed -> table 'players' altered (1 column(s) added)", context.logs.info[1])
end)

h.test('db push reports tables that are already up to date', function()
  local context = h.reset('server', {
    resourceFiles = {
      ['db/players.lua'] = [[
local db = sure.getModule('db')

return db:schema('players', {
  fields = {
    { 'id', { type = 'integer', primaryKey = true } },
  },
})
]],
    },
  })

  exports.oxmysql.query_async = function(_, sql, params)
    context.mysqlQueries[#context.mysqlQueries + 1] = {
      method = 'query_async',
      sql = sql,
      params = params or {},
    }

    return { { COLUMN_NAME = 'id' } }
  end

  h.load('server/modules/db/index.lua')
  context.commands['sure_lib:db'].callback(0, { 'push', 'players' })

  h.assertEqual(1, #context.mysqlQueries)
  h.assertEqual("[sure_lib][db] table 'players' is already up to date", context.logs.info[1])
end)
