local db = {}
local tostring = tostring
local tonumber = tonumber
local type = type
local next = next
local resourceName = GetCurrentResourceName()
local commandName = resourceName .. ':db'

local fieldTypes = {
  integer = 'INT',
  bigint = 'BIGINT',
  float = 'FLOAT',
  double = 'DOUBLE',
  text = 'TEXT',
  boolean = 'TINYINT(1)',
  timestamp = 'TIMESTAMP',
  json = 'JSON',
}

local luaKeywords = {
  ['and'] = true,
  ['break'] = true,
  ['do'] = true,
  ['else'] = true,
  ['elseif'] = true,
  ['end'] = true,
  ['false'] = true,
  ['for'] = true,
  ['function'] = true,
  ['goto'] = true,
  ['if'] = true,
  ['in'] = true,
  ['local'] = true,
  ['nil'] = true,
  ['not'] = true,
  ['or'] = true,
  ['repeat'] = true,
  ['return'] = true,
  ['then'] = true,
  ['true'] = true,
  ['until'] = true,
  ['while'] = true,
}

local function quoteIdentifier(identifier)
  return ('`%s`'):format(tostring(identifier):gsub('`', '``'))
end

local function quoteString(value)
  return ("'%s'"):format(tostring(value):gsub("'", "''"))
end

local function sortedKeys(values)
  local keys = {}
  for key in pairs(values or {}) do
    keys[#keys + 1] = key
  end

  table.sort(keys)
  return keys
end

local function luaFieldKey(fieldName)
  if type(fieldName) == 'string' and not luaKeywords[fieldName] and fieldName:match('^[%a_][%w_]*$') then
    return fieldName
  end

  return '[' .. quoteString(fieldName) .. ']'
end

local function logInfo(message)
  lib.print.info(message)
end

local function logError(message)
  lib.print.error(message)
end

local function printQueryError(err)
  logError('[sure_lib][db] query error: ' .. tostring(err))
end

local function runQuery(defaultValue, callback)
  local ok, result = pcall(callback)
  if not ok then
    printQueryError(result)
    return defaultValue
  end

  return result
end

local function buildWhere(where)
  local keys = sortedKeys(where)
  local clauses = {}
  local params = {}

  for index, key in ipairs(keys) do
    clauses[index] = quoteIdentifier(key) .. ' = ?'
    params[index] = where[key]
  end

  if #clauses == 0 then
    return '', params
  end

  return ' WHERE ' .. table.concat(clauses, ' AND '), params
end

local function hasWhere(where)
  return type(where) == 'table' and next(where) ~= nil
end

local function requireWhere(action, tableName, where)
  if hasWhere(where) then
    return true
  end

  logError(('[sure_lib][db] %s requires a where clause on table: %s'):format(action, tableName))
  return false
end

local function orderedFields(fields)
  local ordered = {}

  if fields[1] ~= nil then
    for index, fieldEntry in ipairs(fields) do
      local fieldName = fieldEntry[1] or fieldEntry.name
      local field = fieldEntry[2] or fieldEntry.field or fieldEntry.definition
      ordered[index] = {
        name = fieldName,
        field = field,
      }
    end

    return ordered
  end

  for index, fieldName in ipairs(sortedKeys(fields)) do
    ordered[index] = {
      name = fieldName,
      field = fields[fieldName],
    }
  end

  return ordered
end

local function fieldSqlType(field)
  if field.type == 'string' then
    return ('VARCHAR(%d)'):format(field.length or 255)
  end

  return fieldTypes[field.type] or 'VARCHAR(255)'
end

local function formatSqlDefault(value)
  if type(value) == 'number' then
    return tostring(value)
  end

  if type(value) == 'boolean' then
    return value and '1' or '0'
  end

  if type(value) == 'string' and value:upper() == 'CURRENT_TIMESTAMP' then
    return value
  end

  return quoteString(value)
end

local function buildCreateTableSql(tableName, fields)
  local columns = {}
  local primaryKey = nil

  for _, fieldInfo in ipairs(orderedFields(fields)) do
    local fieldName = fieldInfo.name
    local field = fieldInfo.field
    local parts = {
      quoteIdentifier(fieldName),
      fieldSqlType(field),
    }

    if field.nullable == false then
      parts[#parts + 1] = 'NOT NULL'
    end

    if field.default ~= nil then
      parts[#parts + 1] = 'DEFAULT ' .. formatSqlDefault(field.default)
    end

    if field.autoIncrement == true then
      parts[#parts + 1] = 'AUTO_INCREMENT'
    end

    if field.unique == true then
      parts[#parts + 1] = 'UNIQUE'
    end

    if field.primaryKey == true then
      primaryKey = fieldName
    end

    columns[#columns + 1] = table.concat(parts, ' ')
  end

  if primaryKey ~= nil then
    columns[#columns + 1] = 'PRIMARY KEY (' .. quoteIdentifier(primaryKey) .. ')'
  end

  return 'CREATE TABLE IF NOT EXISTS ' .. quoteIdentifier(tableName) .. ' (\n  ' .. table.concat(columns, ',\n  ') .. '\n)'
end

local function modelFor(schemaName, definition)
  local model = {
    name = schemaName,
    tableName = definition.tableName or schemaName,
    fields = definition.fields or {},
  }

  function model:findMany(query)
    query = query or {}
    local whereSql, params = buildWhere(query.where)
    local sql = 'SELECT * FROM ' .. quoteIdentifier(self.tableName) .. whereSql

    return runQuery({}, function()
      return exports.oxmysql:query_async(sql, params)
    end)
  end

  function model:findFirst(query)
    query = query or {}
    local whereSql, params = buildWhere(query.where)
    local sql = 'SELECT * FROM ' .. quoteIdentifier(self.tableName) .. whereSql .. ' LIMIT 1'

    return runQuery(nil, function()
      local rows = exports.oxmysql:query_async(sql, params)
      return rows and rows[1] or nil
    end)
  end

  function model:create(query)
    query = query or {}
    local data = query.data or {}
    local keys = sortedKeys(data)
    local columns = {}
    local placeholders = {}
    local params = {}

    for index, key in ipairs(keys) do
      columns[index] = quoteIdentifier(key)
      placeholders[index] = '?'
      params[index] = data[key]
    end

    local sql = 'INSERT INTO ' .. quoteIdentifier(self.tableName) .. ' (' .. table.concat(columns, ', ') .. ') VALUES (' .. table.concat(placeholders, ', ') .. ')'

    return runQuery(nil, function()
      return exports.oxmysql:insert_async(sql, params)
    end)
  end

  function model:update(query)
    query = query or {}
    if not requireWhere('update', self.tableName, query.where) then
      return nil
    end

    local data = query.data or {}
    local keys = sortedKeys(data)
    local assignments = {}
    local params = {}

    for index, key in ipairs(keys) do
      assignments[index] = quoteIdentifier(key) .. ' = ?'
      params[index] = data[key]
    end

    local whereSql, whereParams = buildWhere(query.where)
    for _, value in ipairs(whereParams) do
      params[#params + 1] = value
    end

    local sql = 'UPDATE ' .. quoteIdentifier(self.tableName) .. ' SET ' .. table.concat(assignments, ', ') .. whereSql

    return runQuery(nil, function()
      return exports.oxmysql:update_async(sql, params)
    end)
  end

  function model:delete(query)
    query = query or {}
    if not requireWhere('delete', self.tableName, query.where) then
      return nil
    end

    local whereSql, params = buildWhere(query.where)
    local sql = 'DELETE FROM ' .. quoteIdentifier(self.tableName) .. whereSql

    return runQuery(nil, function()
      return exports.oxmysql:execute_async(sql, params)
    end)
  end

  function model:raw(sql, params)
    return runQuery(nil, function()
      return exports.oxmysql:query_async(sql, params or {})
    end)
  end

  return model
end

--- @param schemaName string
--- @param definition table
--- @return table
function db:schema(schemaName, definition)
  return modelFor(schemaName, definition or {})
end

local function loadSchemaFile(schemaName)
  local filePath = 'db/' .. schemaName .. '.lua'
  local content = LoadResourceFile(GetCurrentResourceName(), filePath)
  if content == nil then
    logError('[sure_lib][db] schema file not found: ' .. filePath)
    return nil
  end

  local sandboxDb = {}
  function sandboxDb:schema(name, definition)
    definition = definition or {}
    definition.name = name
    definition.tableName = definition.tableName or name
    return definition
  end

  local env = {
    math = math,
    table = table,
    string = string,
    pairs = pairs,
    ipairs = ipairs,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    db = sandboxDb,
    sure = {
      getModule = function(moduleName)
        if moduleName == 'db' then
          return sandboxDb
        end

        return nil
      end,
    },
  }

  local chunk, err = load(content, '@' .. filePath, 't', env)
  if chunk == nil then
    logError('[sure_lib][db] cannot load schema file: ' .. filePath .. ' (' .. tostring(err) .. ')')
    return nil
  end

  local ok, schema = pcall(chunk)
  if not ok then
    logError('[sure_lib][db] cannot load schema file: ' .. filePath .. ' (' .. tostring(schema) .. ')')
    return nil
  end

  return schema
end

local function pushSchema(schemaName)
  local schema = loadSchemaFile(schemaName)
  if schema == nil then
    return
  end

  local tableName = schema.tableName or schemaName
  local sql = buildCreateTableSql(tableName, schema.fields or {})

  local ok, err = pcall(function()
    return exports.oxmysql:execute_async(sql, {})
  end)

  if not ok then
    printQueryError(err)
    return
  end

  logInfo("[sure_lib][db] pushed -> table '" .. tableName .. "' is ready")
end

local function mysqlTypeToField(columnType)
  local normalized = columnType:lower()

  if normalized:find('^tinyint%(1%)') then
    return { type = 'boolean' }
  end

  if normalized:find('^bigint') then
    return { type = 'bigint' }
  end

  if normalized:find('^int') or normalized:find('^integer') then
    return { type = 'integer' }
  end

  if normalized:find('^float') then
    return { type = 'float' }
  end

  if normalized:find('^double') then
    return { type = 'double' }
  end

  local varcharLength = normalized:match('^varchar%((%d+)%)')
  if varcharLength ~= nil then
    return {
      type = 'string',
      length = tonumber(varcharLength),
    }
  end

  if normalized:find('text') then
    return { type = 'text' }
  end

  if normalized:find('^timestamp') or normalized:find('^datetime') then
    return { type = 'timestamp' }
  end

  if normalized:find('^json') then
    return { type = 'json' }
  end

  return { type = 'string' }
end

local function formatLuaValue(value)
  if type(value) == 'number' then
    return tostring(value)
  end

  if type(value) == 'boolean' then
    return value and 'true' or 'false'
  end

  local numeric = tonumber(value)
  if numeric ~= nil and tostring(numeric) == tostring(value) then
    return tostring(value)
  end

  return quoteString(value)
end

local function formatFieldDefinition(field)
  local parts = {
    "type = '" .. field.type .. "'",
  }

  if field.length ~= nil then
    parts[#parts + 1] = 'length = ' .. field.length
  end

  if field.primaryKey == true then
    parts[#parts + 1] = 'primaryKey = true'
  end

  if field.autoIncrement == true then
    parts[#parts + 1] = 'autoIncrement = true'
  end

  if field.unique == true then
    parts[#parts + 1] = 'unique = true'
  end

  if field.nullable == false then
    parts[#parts + 1] = 'nullable = false'
  end

  if field.default ~= nil then
    parts[#parts + 1] = 'default = ' .. formatLuaValue(field.default)
  end

  return '{ ' .. table.concat(parts, ', ') .. ' }'
end

local function buildPulledSchemaSource(targetTable, columns)
  local lines = {
    "local db = sure.getModule('db')",
    '',
    "return db:schema('" .. targetTable .. "', {",
    '  fields = {',
  }

  for _, column in ipairs(columns) do
    local field = mysqlTypeToField(column.COLUMN_TYPE)

    if column.IS_NULLABLE == 'NO' then
      field.nullable = false
    end

    if column.COLUMN_DEFAULT ~= nil then
      field.default = column.COLUMN_DEFAULT
    end

    if column.COLUMN_KEY == 'PRI' then
      field.primaryKey = true
    end

    if column.EXTRA and column.EXTRA:lower():find('auto_increment', 1, true) then
      field.autoIncrement = true
    end

    if column.COLUMN_KEY == 'UNI' then
      field.unique = true
    end

    lines[#lines + 1] = '    ' .. luaFieldKey(column.COLUMN_NAME) .. ' = ' .. formatFieldDefinition(field) .. ','
  end

  lines[#lines + 1] = '  },'
  lines[#lines + 1] = '})'
  lines[#lines + 1] = ''

  return table.concat(lines, '\n')
end

local function pullSchema(targetTable)
  local sql = [[
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT,
       COLUMN_KEY, EXTRA
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = ? AND TABLE_SCHEMA = DATABASE()
ORDER BY ORDINAL_POSITION
]]

  local columns = runQuery({}, function()
    return exports.oxmysql:query_async(sql, { targetTable })
  end)

  if #columns == 0 then
    logError("[sure_lib][db] table '" .. targetTable .. "' not found")
    return
  end

  local content = buildPulledSchemaSource(targetTable, columns)
  local targetPath = 'db/' .. targetTable .. '.lua'
  local ok = SaveResourceFile(GetCurrentResourceName(), targetPath, content, #content)
  if not ok then
    logError('[sure_lib][db] cannot save schema file: ' .. targetPath)
    return
  end

  logInfo("[sure_lib][db] pulled '" .. targetTable .. "' -> db/" .. targetTable .. '.lua')
end

RegisterCommand(commandName, function(source, args)
  if source ~= 0 then
    logError('[sure_lib][db] db commands are console-only')
    return
  end

  local action = args and args[1]
  local target = args and args[2]

  if action == 'push' and target ~= nil then
    pushSchema(target)
    return
  end

  if action == 'pull' and target ~= nil then
    pullSchema(target)
    return
  end

  logInfo('[sure_lib][db] usage: ' .. commandName .. ' push <schemaName> | ' .. commandName .. ' pull <targetTable>')
end, true)

return db
