local esx = GetModule('ESX')

RegisterCommand('additem', function(_, args)
    esx.AddItem(args[1], tonumber(args[2]))
    print(args[1], args[2])
end, true)

RegisterCommand('addaccount', function(_, args)
    esx.AddAccount(args[1], tonumber(args[2]))
    print(args[1], args[2])
end, true)

RegisterCommand('removeitem', function(_, args)
    esx.RemoveItem(args[1], tonumber(args[2]))
    print(args[1], args[2])
end, true)

RegisterCommand('removeaccount', function(_, args)
    esx.RemoveAccount(args[1], tonumber(args[2]))
    print(args[1], args[2])
end, true)

--[[
    -------------------------------------------
    Track Testing (Reactive-System) with ESX
    -------------------------------------------
]]

local t = GetModule('Track')
local Track = t.Track
local Effect = t.Effect

local itemToAdd, setItemToAdd = Track('item', 'painkiller')
local addAmount, setAddAmount = Track('amount', 0)

Effect(function()
    esx.AddItem(itemToAdd(), addAmount())
    print(itemToAdd(), addAmount())
end, { addAmount, itemToAdd })

RegisterCommand('setitem', function(_, args)
    setItemToAdd(args[1])
end, true)

RegisterCommand('setamount', function(_, args)
    setAddAmount(tonumber(args[1]))
end, true)