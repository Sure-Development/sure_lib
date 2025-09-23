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