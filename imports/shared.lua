--- @alias SURELIB.IMPORTS.MODULES
--- | 'ESX'

local namespace = 'client'
if IsDuplicityVersion() then
    namespace = 'server'
end

--- @param module string
--- @param file string
local generatePath = function(module, file)
    return ('@sure_lib.modules.%s.%s.%s'):format(module, namespace, file)
end

local pathAliases = {
    ['ESX'] = generatePath('esx', 'index'),
    ['Cooldown'] = generatePath('cooldown', 'index'),
    ['Validator'] = generatePath('validator', 'index'),
}

--- @param name SURELIB.IMPORTS.MODULES
--- @return any
function GetModule(name)
    if pathAliases[name] then
        local modular = require(pathAliases[name])
        return modular
    end
end