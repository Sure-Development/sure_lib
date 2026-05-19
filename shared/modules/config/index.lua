local config = {}
local cache = {}

local safeEnv = {
  math = math,
  table = table,
  string = string,
  pairs = pairs,
  ipairs = ipairs,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  vector3 = vector3,
  vector4 = vector4,
}

local function cannotLoad(filePath)
  error('[sure_lib][config] cannot load file: ' .. filePath, 3)
end

local function normalizeLoadPath(filePath)
  return filePath:gsub('%.lua$', ''):gsub('/', '.'):gsub('\\', '.')
end

local function parseSchema(filePath, schema, result)
  if schema == nil then
    return result
  end

  if type(schema.parse) ~= 'function' then
    error('[sure_lib][config] validation schema must expose parse(data)', 3)
  end

  local ok, err = pcall(schema.parse, result)
  if not ok then
    error('[sure_lib][config] validation failed in ' .. filePath .. ': ' .. tostring(err), 3)
  end

  return result
end

local function loadConfig(filePath, schema)
  local env = {}
  for key, value in pairs(safeEnv) do
    env[key] = value
  end

  local ok, result = pcall(lib.load, normalizeLoadPath(filePath), env)
  if not ok then
    cannotLoad(filePath)
  end

  return parseSchema(filePath, schema, result)
end

--- Loads a Lua config file from the consuming resource root.
---
--- Example:
--- local config = sure.getModule('config')
--- local validator = sure.getModule('validator')
--- local schema = validator.object({
---   taxRate = validator.number().min(0).max(1),
---   shopName = validator.string().required(),
--- })
--- local cfg = config:load('config.lua', schema)
--- @param filePath string
--- @param schema table?
--- @return table
function config:load(filePath, schema)
  if cache[filePath] ~= nil then
    return parseSchema(filePath, schema, cache[filePath])
  end

  local result = loadConfig(filePath, schema)
  cache[filePath] = result
  return result
end

--- @param filePath string
--- @param schema table?
--- @return table
function config:reload(filePath, schema)
  local result = loadConfig(filePath, schema)
  cache[filePath] = result
  return result
end

return config
