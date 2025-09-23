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