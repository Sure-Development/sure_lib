local app = {}

--- @alias SURELIB.VALIDATOR.TYPES 'object'
--- | 'array'
--- | 'string'
--- | 'number'
--- | 'boolean'
--- | 'function'
local valid_types = { 'object', 'array', 'string', 'number', 'boolean', 'function' }

--- @param value SURELIB.VALIDATOR.TYPES
--- @return boolean
local function isValidTypes(value)
    for _, validType in ipairs(valid_types) do
        if validType == value then
            return true
        end
    end
    return false
end

--- @param condition boolean
--- @param message string
local function customAssert(condition, message)
    if not condition then
        error('Validation Error: ' .. message, 2)
    end
end

--- @param targetType SURELIB.VALIDATOR.TYPES
function app.createInstance(targetType)
    customAssert(isValidTypes(targetType), 'Incorrect type for creating instance: ' .. tostring(targetType))

    local instance = {
        type = targetType,
        __required = false
    }

    function instance.Required()
        instance.__required = true
        return instance
    end

    function instance.Parse(data)
        if instance.__required and data == nil then
            customAssert(false, 'Required field is missing.')
        end

        local receiveType = type(data)
        if data == nil then
            return true
        end

        if instance.type == 'object' then
            customAssert(receiveType == 'table', 'Expected type "object", but received "' .. receiveType .. '".')
            for name, fieldSchema in pairs(instance.fields) do
                local fieldData = data[name]
                fieldSchema.Parse(fieldData)
            end
            return true
        elseif instance.type == 'array' then
            customAssert(receiveType == 'table', 'Expected type "array", but received "' .. receiveType .. '".')
            for _, item in ipairs(data) do
                instance.ref.Parse(item)
            end
            return true
        else
            customAssert(receiveType == instance.type, ('Expected type "%s", but received "' .. receiveType .. '".'):format(instance.type))
            return receiveType == instance.type
        end
    end

    return instance
end

function app.Object(schema)
    local instance = app.createInstance('object')
    instance.fields = {}
    customAssert(type(schema) == 'table', 'Object schema must be a table.')
    for name, class in pairs(schema) do
        customAssert(type(class) == 'table' and class.parse ~= nil, 'Invalid schema for field "' .. name .. '".')
        instance.fields[name] = class
    end
    return instance
end

function app.Array(refClass)
    local instance = app.createInstance('array')
    customAssert(type(refClass) == 'table' and refClass.parse ~= nil, 'Array schema requires a valid schema class.')
    instance.ref = refClass
    return instance
end

function app.String()
    return app.createInstance('string')
end

function app.Number()
    return app.createInstance('number')
end

function app.Boolean()
    return app.createInstance('boolean')
end

function app.Fn()
    return app.createInstance('function')
end

return app