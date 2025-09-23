local esx = {}
local playerLoaded = promise.new()
local itemIndexes = {}

CreateThread(function(threadId)
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end

    playerLoaded:resolve()
    TerminateThread(threadId)
end)

function esx.WaitPlayerLoaded()
    Citizen.Await(playerLoaded)
end

--- @param name string
--- @return ESXItem?
function esx.GetItem(name)
    local index = itemIndexes[name]
    local inventory = ESX.GetPlayerData().inventory
    if index == nil then
        for k, v in ipairs(inventory) do
            if v.name == name then
                itemIndexes[name] = k
                index = k
                break
            end
        end
    end

    return inventory[index]
end

return esx