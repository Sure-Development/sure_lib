local esx = {}
local playerLoaded = promise.new()
local itemIndexes = {}
local accountIndexes = {}

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

--- @param name string
--- @return ESXPlayerAccount?
function esx.GetAccount(name)
    local index = accountIndexes[name]
    local accounts = ESX.GetPlayerData().accounts
    if index == nil then
        for k, v in ipairs(accounts) do
            if v.name == name then
                accountIndexes[name] = k
                index = k
                break
            end
        end
    end

    return accountIndexes[index]
end

return esx