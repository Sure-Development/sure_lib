local app = {}
local registered = {}

local function assertOxLib()
  if type(lib) ~= 'table' or type(lib.addKeybind) ~= 'function' then
    error('[sure_lib][keybind] ox_lib lib.addKeybind is not available', 3)
  end
end

local function asTable(spec)
  return {
    name = spec.name,
    description = spec.description,
    defaultKey = spec.defaultKey or spec.key,
    defaultMapper = spec.defaultMapper or spec.mapper or 'keyboard',
    secondaryKey = spec.secondaryKey,
    secondaryMapper = spec.secondaryMapper,
    onPressed = spec.onPressed or spec.onPress,
    onReleased = spec.onReleased or spec.onRelease,
    disabled = spec.disabled,
  }
end

--- @param spec SureKeybindSpec
--- @return any
function app.register(spec)
  assertOxLib()

  if type(spec) ~= 'table' or type(spec.name) ~= 'string' then
    error('[sure_lib][keybind] register expects a table with a "name" field', 2)
  end

  if registered[spec.name] ~= nil then
    return registered[spec.name]
  end

  local instance = lib.addKeybind(asTable(spec))
  registered[spec.name] = instance
  return instance
end

--- @param name string
--- @return any?
function app.get(name)
  return registered[name]
end

local function setDisabled(name, value)
  local instance = registered[name]
  if instance == nil then
    return
  end

  if type(instance.disable) == 'function' then
    instance:disable(value)
  end
end

--- @param name string
function app.disable(name)
  setDisabled(name, true)
end

--- @param name string
function app.enable(name)
  setDisabled(name, false)
end

--- @return table<string, any>
function app.all()
  return registered
end

return app
