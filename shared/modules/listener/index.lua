--- @class Listener : OxClass
local Listener = lib.class('Listener')

function Listener:listen(eventName, callback, register)
  local meta = {
    name = eventName,
    params = {},
    callback = callback,
  }

  function meta:expect(...)
    meta.params = { ... }
    return meta
  end

  register(eventName, function(...)
    local args = { ... }
    for index, validator in ipairs(meta.params) do
      local arg = args[index]

      local success = pcall(function()
        validator.parse(arg)
      end)

      if not success then
        local message = ('[^1ERROR^7] Parameter index ^1%s^7, expected ^1%s^7 got ^1%s^7 of event ^1%s^7 is not valid'):format(
          index,
          validator.type,
          type(arg),
          meta.name
        )

        print(message)
        error(message, 2)
      end
    end

    callback(...)
  end)

  return meta
end

function Listener:on(eventName, callback)
  return Listener:listen(eventName, callback, AddEventHandler)
end

function Listener:onNet(eventName, callback)
  return Listener:listen(eventName, callback, RegisterNetEvent)
end

local app = Listener:new()

return app
