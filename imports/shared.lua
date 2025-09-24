--- @alias SURELIB.IMPORTS.MODULES
--- | 'ESX'
--- | 'Cooldown'
--- | 'Validator'
--- | 'Track'

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

--- Gets a module from the pathAliases table by its name
--- This function looks up a module path in the pathAliases table and requires it
--- @param name SURELIB.IMPORTS.MODULES The name/identifier of the module to retrieve
--- @return any The required module if found, nil otherwise
function GetModule(name)
    if pathAliases[name] then
        local modular = require(pathAliases[name])
        return modular
    end
end