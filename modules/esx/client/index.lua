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

--- Waits until the player has fully loaded into the server
--- This is a blocking function that uses Citizen.Await internally
-- @usage esx.WaitPlayerLoaded() -- Blocks execution until player is loaded
function esx.WaitPlayerLoaded()
    Citizen.Await(playerLoaded)
end

--- Gets an ESX item from player's inventory by its name
--- Searches through player's inventory to find an item with matching name.
--- Caches the item's index for future lookups to improve performance.
--- 
--- @param name string The name of the item to find
--- @return ESXItem? Returns the item if found, nil otherwise
--- @usage local item = esx.GetItem("bread")
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

--[[
    Retrieves a specific account from ESX player data by its name.
    Caches the account index for faster subsequent lookups.

    @param name The name of the account to retrieve
    @return ESXPlayerAccount|nil Returns the account if found, nil otherwise
    
    Example:
    local bank = esx.GetAccount('bank')
    local cash = esx.GetAccount('money')
]]
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

--- Processes multiple transactions in ESX
--- Handles multiple transactions in ESX system. Takes an array of transaction payloads and processes them server-side.
--- Each payload item should contain an integer operation type and an array of parameters.
--- Returns true if all transactions succeed, false otherwise.
--- If payload is empty, returns true without making server call.
---
--- @param payload { [1]: integer, [2]: any[] }[] Array of transaction payloads [opType, parameters[]]
--- @return boolean Success status of transactions
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

--[[
    Adds a specified amount of an item to the player's inventory.
    This is a convenience wrapper around AddItems for adding a single item.

    @param name The name/identifier of the item to add
    @param count The amount of the item to add
    @return boolean Returns true if the item was successfully added, false otherwise

    Example:
    local success = esx.AddItem('bread', 5)
    local success = esx.AddItem('water', 1) 
]]
--- @param name string
--- @param count integer
--- @return boolean
function esx.AddItem(name, count)
    return esx.AddItems({
        [1] = { name = name, count = count }
    })
end

--[[
    Removes multiple items from player's inventory in a single transaction.
    Takes an array of items with their respective quantities to remove.

    @param payload Array of objects containing item name and count to remove
    @return boolean Returns true if the transaction was successful, false otherwise

    Example:
    local result = esx.RemoveItems({
        { name = "bread", count = 2 },
        { name = "water", count = 1 }
    })
]]
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