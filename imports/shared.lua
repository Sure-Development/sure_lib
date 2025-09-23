--- @alias SURELIB.IMPORTS.MODULES
--- | 'ESX'

local namespace = 'client'
if IsDuplicityVersion() then
    namespace = 'server'
end

--- @param module string
--- @param file string
--- @param customNamespace string?
local generatePath = function(module, file, customNamespace)
    if customNamespace == nil then
        customNamespace = namespace
    end

    return ('@sure_lib.modules.%s.%s.%s'):format(module, customNamespace, file)
end

local pathAliases = {
    ['ESX'] = generatePath('esx', 'index'),
    ['Cooldown'] = generatePath('cooldown', 'index'),
    ['Validator'] = generatePath('validator', 'index'),
    ['Track'] = generatePath('track', 'index', 'shared')
}

--- @param name SURELIB.IMPORTS.MODULES
--- @return any
function GetModule(name)
    if pathAliases[name] then
        local modular = require(pathAliases[name])
        return modular
    end
end

if IsDuplicityVersion() then
    local actionToFuncs = {
        ['1'] = 'addInventoryItem',
        ['2'] = 'addAccountMoney',
        ['-1'] = 'removeInventoryItem',
        ['-2'] = 'removeAccountMoney'
    }

    --- @param source integer
    --- @param payload { [1]: integer, [2]: any[] }[]
    lib.callback.register('esx:transactions', function(source, payload)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for _, transaction in ipairs(payload) do
                local action = tostring(transaction[1])
                local allArgs = transaction[2]

                if actionToFuncs[action] then
                    local functionName = actionToFuncs[action]
                    for _, args in ipairs(allArgs) do
                        xPlayer[functionName](table.unpack(args))
                    end
                else
                    lib.print.info(('Error during action %s does not exists'):format(action))
                end
            end

            return true
        end

        return false
    end)
end