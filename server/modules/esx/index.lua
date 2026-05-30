local app = {}

-- es_extended depends on sure_lib, so it starts AFTER us. Resolve the shared object
-- asynchronously (poll every 1s) instead of at load time — a blocking wait here would
-- deadlock (sure_lib waiting on es_extended while es_extended waits on sure_lib to boot),
-- and calling the export before es_extended is started throws "No such export".
local ESX
CreateThread(function()
  while ESX == nil do
    if GetResourceState('es_extended') == 'started' then
      local ok, obj = pcall(function()
        return exports.es_extended:getSharedObject()
      end)
      if ok and obj then
        ESX = obj
      end
    end
    if ESX == nil then
      Wait(1000)
    end
  end
end)

local unpack = table.unpack

local actionToFuncs = {
  ['1'] = 'addInventoryItem',
  ['2'] = 'addAccountMoney',
  ['-1'] = 'removeInventoryItem',
  ['-2'] = 'removeAccountMoney',
}

--- @param playerSource integer
--- @return table?
local function getPlayer(playerSource)
  if type(playerSource) ~= 'number' then
    return nil
  end

  return ESX.GetPlayerFromId(playerSource)
end

--- @param entries { itemName: string?, accountName: string?, amount: number }[]
--- @param nameKey 'itemName'|'accountName'
--- @return any[][]?
local function normalizeEntries(entries, nameKey)
  local normalized = {}

  for _, entry in ipairs(entries or {}) do
    if type(entry) ~= 'table' or type(entry[nameKey]) ~= 'string' or type(entry.amount) ~= 'number' then
      return nil
    end

    normalized[#normalized + 1] = { entry[nameKey], entry.amount }
  end

  return normalized
end

--- @param playerSource integer
--- @param entries { [1]: integer, [2]: any[] }[]
--- @return boolean
function app.transactions(playerSource, entries)
  if type(entries) ~= 'table' then
    return false
  end

  local xPlayer = getPlayer(playerSource)
  if not xPlayer then
    return false
  end

  for _, transaction in ipairs(entries) do
    if type(transaction) ~= 'table' then
      return false
    end

    local action = tostring(transaction[1])
    local allArgs = transaction[2]
    local functionName = actionToFuncs[action]

    if functionName == nil or type(allArgs) ~= 'table' then
      lib.print.info(('Error during action %s does not exist'):format(action))
      return false
    end

    for _, args in ipairs(allArgs) do
      if type(args) ~= 'table' then
        return false
      end

      xPlayer[functionName](unpack(args))
    end
  end

  return true
end

--- @param playerSource integer
--- @param items { itemName: string, amount: number }[]
--- @return boolean
function app.giveItems(playerSource, items)
  local normalized = normalizeEntries(items, 'itemName')
  if normalized == nil then
    return false
  end

  return app.transactions(playerSource, {
    [1] = { 1, normalized },
  })
end

--- @param playerSource integer
--- @param itemName string
--- @param amount integer
--- @return boolean
function app.giveItem(playerSource, itemName, amount)
  return app.giveItems(playerSource, {
    [1] = { itemName = itemName, amount = amount },
  })
end

--- @param playerSource integer
--- @param items { itemName: string, amount: number }[]
--- @return boolean
function app.removeItems(playerSource, items)
  local normalized = normalizeEntries(items, 'itemName')
  if normalized == nil then
    return false
  end

  return app.transactions(playerSource, {
    [1] = { -1, normalized },
  })
end

--- @param playerSource integer
--- @param itemName string
--- @param amount integer
--- @return boolean
function app.removeItem(playerSource, itemName, amount)
  return app.removeItems(playerSource, {
    [1] = { itemName = itemName, amount = amount },
  })
end

--- @param playerSource integer
--- @param accounts { accountName: string, amount: number }[]
--- @return boolean
function app.addMoneyEntries(playerSource, accounts)
  local normalized = normalizeEntries(accounts, 'accountName')
  if normalized == nil then
    return false
  end

  return app.transactions(playerSource, {
    [1] = { 2, normalized },
  })
end

--- @param playerSource integer
--- @param accountName string
--- @param amount integer
--- @return boolean
function app.addMoney(playerSource, accountName, amount)
  return app.addMoneyEntries(playerSource, {
    [1] = { accountName = accountName, amount = amount },
  })
end

--- @param playerSource integer
--- @param accounts { accountName: string, amount: number }[]
--- @return boolean
function app.removeMoneyEntries(playerSource, accounts)
  local normalized = normalizeEntries(accounts, 'accountName')
  if normalized == nil then
    return false
  end

  return app.transactions(playerSource, {
    [1] = { -2, normalized },
  })
end

--- @param playerSource integer
--- @param accountName string
--- @param amount integer
--- @return boolean
function app.removeMoney(playerSource, accountName, amount)
  return app.removeMoneyEntries(playerSource, {
    [1] = { accountName = accountName, amount = amount },
  })
end

return app
