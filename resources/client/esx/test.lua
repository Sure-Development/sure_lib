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