local app = {}
local watchers = {}

--- @param name string
--- @param initialValue any
--- @return any, fun(newValue: any)
function app.Track(name, initialValue)
    local data = nil
    if type(initialValue) == 'table' then
        data = lib.table.deepclone(initialValue)
    else
        data = initialValue
    end

    local getter = {}

    local setter = function(newValue)
        if newValue ~= data then
            if type(newValue) == 'table' then
                data = lib.table.deepclone(newValue)
            else
                data = newValue
            end

            local indexesToCall = {}
            for k, watcher in ipairs(watchers) do
                local deps = watcher?.deps
                if deps then
                    for _, dep in ipairs(deps) do
                        if dep?.trackerName == name then
                            indexesToCall[#indexesToCall + 1] = k
                        end
                    end
                end
            end

            for _, id in ipairs(indexesToCall) do
                if type(watchers[id].fn) == 'function' then
                    watchers[id].fn()
                end
            end
        end
    end

    local meta = {
        __index = {
            isReactive = true,
            trackerName = name
        },

        __call = function()
            return data
        end
    }

    setmetatable(getter, meta)

    return getter, setter
end

--- @param fn fun()
--- @param dependencies any[]
function app.Effect(fn, dependencies)
    local index = #watchers + 1
    watchers[index] = {
        fn = fn,
        deps = dependencies
    }
end

return app