local app = {}

--- @alias SURELIB.VALIDATOR.TYPES 'object'
--- | 'array'
--- | 'string'
--- | 'number'
--- | 'integer'
--- | 'boolean'
--- | 'function'
local knownTypes = { 'object', 'array', 'string', 'number', 'integer', 'boolean', 'function' }

--- @param value SURELIB.VALIDATOR.TYPES
--- @return boolean
local function isKnownType(value)
  for _, knownType in ipairs(knownTypes) do
    if knownType == value then
      return true
    end
  end

  return false
end

--- @param condition boolean
--- @param message string
local function assertValid(condition, message)
  if not condition then
    error('Validation Error: ' .. message, 2)
  end
end

--- @param values any[]
--- @return string
local function joinValues(values)
  local parts = {}
  for index, value in ipairs(values) do
    parts[index] = tostring(value)
  end

  return table.concat(parts, ', ')
end

--- @param targetType SURELIB.VALIDATOR.TYPES
function app.createRule(targetType)
  assertValid(isKnownType(targetType), 'Incorrect type for creating rule: ' .. tostring(targetType))

  local instance = {
    type = targetType,
    __required = false,
    __message = nil,
    __checks = {},
  }

  --- @param message string?
  function instance.message(message)
    instance.__message = message
    return instance
  end

  --- @param message string?
  function instance.required(message)
    instance.__required = true
    if message ~= nil then
      instance.__message = message
    end

    return instance
  end

  --- @param check fun(data: any)
  local function addCheck(check)
    instance.__checks[#instance.__checks + 1] = check
    return instance
  end

  --- @param message string
  local function fail(message)
    assertValid(false, instance.__message or message)
  end

  --- @param minValue number
  function instance.min(minValue)
    return addCheck(function(data)
      if data < minValue then
        fail(('Expected value to be greater than or equal to %s.'):format(minValue))
      end
    end)
  end

  --- @param maxValue number
  function instance.max(maxValue)
    return addCheck(function(data)
      if data > maxValue then
        fail(('Expected value to be less than or equal to %s.'):format(maxValue))
      end
    end)
  end

  --- @param minValue number
  --- @param maxValue number
  function instance.between(minValue, maxValue)
    return instance.min(minValue).max(maxValue)
  end

  --- @param values any[]
  function instance.oneOf(values)
    return addCheck(function(data)
      for _, value in ipairs(values) do
        if data == value then
          return
        end
      end

      fail(('Expected one of: %s.'):format(joinValues(values)))
    end)
  end

  function instance.parse(data)
    if instance.__required and data == nil then
      fail('Required field is missing.')
    end

    if data == nil then
      return true
    end

    local receiveType = type(data)
    if instance.type == 'object' then
      if receiveType ~= 'table' then
        fail('Expected type "object", but received "' .. receiveType .. '".')
      end

      for fieldName, fieldRule in pairs(instance.fields) do
        fieldRule.parse(data[fieldName])
      end
    elseif instance.type == 'array' then
      if receiveType ~= 'table' then
        fail('Expected type "array", but received "' .. receiveType .. '".')
      end

      for _, item in ipairs(data) do
        instance.itemRule.parse(item)
      end
    elseif instance.type == 'integer' then
      if receiveType ~= 'number' or data % 1 ~= 0 then
        fail('Expected integer, but received "' .. receiveType .. '".')
      end
    elseif receiveType ~= instance.type then
      fail(('Expected type "%s", but received "' .. receiveType .. '".'):format(instance.type))
    end

    for _, check in ipairs(instance.__checks) do
      check(data)
    end

    return true
  end

  return instance
end

function app.object(fields)
  local instance = app.createRule('object')
  instance.fields = {}

  assertValid(type(fields) == 'table', 'Object schema must be a table.')
  for fieldName, rule in pairs(fields) do
    assertValid(type(rule) == 'table' and rule.parse ~= nil, 'Invalid schema for field "' .. fieldName .. '".')
    instance.fields[fieldName] = rule
  end

  return instance
end

function app.array(itemRule)
  local instance = app.createRule('array')
  assertValid(type(itemRule) == 'table' and itemRule.parse ~= nil, 'Array schema requires a valid schema class.')
  instance.itemRule = itemRule
  return instance
end

function app.string()
  return app.createRule('string')
end

function app.number()
  return app.createRule('number')
end

function app.integer()
  return app.createRule('integer')
end

function app.boolean()
  return app.createRule('boolean')
end

function app.callback()
  return app.createRule('function')
end

return app
