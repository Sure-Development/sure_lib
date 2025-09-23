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

--- @param payload { [1]: integer, [2]: any[] }[]
--- @return boolean
function esx.Transactions(payload)
    local result = true
    if #payload > 0 then
        result = lib.callback.await('esx:transactions', false, payload) --[[@as boolean]]
    end

    return result
end

--- @param payload { name: string, count: number }[]
--- @return boolean
function esx.AddItems(payload)
    local action = 1
    local newPayload = {}
    for _, v in ipairs(payload) do
        newPayload[#newPayload + 1] = { v.name, v.count }
    end

    local result = esx.Transactions({
        [1] = { action, newPayload }
    })

    return result
end

--- @param name string
--- @param count integer
--- @return boolean
function esx.AddItem(name, count)
    return esx.AddItems({
        [1] = { name = name, count = count }
    })
end

--- @param payload { name: string, count: number }[]
--- @return boolean
function esx.RemoveItems(payload)
    local action = -1
    local newPayload = {}
    for _, v in ipairs(payload) do
        newPayload[#newPayload + 1] = { v.name, v.count }
    end

    local result = esx.Transactions({
        [1] = { action, newPayload }
    })

    return result
end

--- @param name string
--- @param count integer
--- @return boolean
function esx.RemoveItem(name, count)
    return esx.RemoveItems({
        [1] = { name = name, count = count }
    })
end

--- @param payload { name: string, count: number }[]
--- @return boolean
function esx.AddAccounts(payload)
    local action = 2
    local newPayload = {}
    for _, v in ipairs(payload) do
        newPayload[#newPayload + 1] = { v.name, v.count }
    end

    local result = esx.Transactions({
        [1] = { action, newPayload }
    })

    return result
end

--- @param name string
--- @param count integer
--- @return boolean
function esx.AddAccount(name, count)
    return esx.AddAccounts({
        [1] = { name = name, count = count }
    })
end

--- @param payload { name: string, count: number }[]
--- @return boolean
function esx.RemoveAccounts(payload)
    local action = -2
    local newPayload = {}
    for _, v in ipairs(payload) do
        newPayload[#newPayload + 1] = { v.name, v.count }
    end

    local result = esx.Transactions({
        [1] = { action, newPayload }
    })

    return result
end

--- @param name string
--- @param count integer
--- @return boolean
function esx.RemoveAccount(name, count)
    return esx.RemoveAccounts({
        [1] = { name = name, count = count }
    })
end

return esx