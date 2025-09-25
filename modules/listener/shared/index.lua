--- @class Listener : OxClass
local Listener = lib.class('Listener')

function Listener:Listen(name, cb, fn)
    local meta = {
        name = name,
        params = {},
        cb = cb
    }

    function meta.AddParams(...)
        meta.params = { ... }
    end

    fn(name, function(...)
        local args = { ... }
        for index, validator in ipairs(meta.params) do
            local arg = args[index] or nil

            local success = pcall(function()
                validator.Parse(arg)
            end)

            if not success then
                print(('[^1ERROR^7] Parameter index ^1%s^7, expected ^1%s^7 got ^1%s^7 of event ^1%s^7 is not valid'):format(index, validator.type, type(arg), meta.name))
                error(nil, 2)
            end
        end

        cb(...)
    end)

    return meta
end

function Listener:Local(name, fn)
    return Listener:Listen(name, fn, AddEventHandler)
end

function Listener:Net(name, fn)
    return Listener:Listen(name, fn, RegisterNetEvent)
end

local app = Listener:new()

return app