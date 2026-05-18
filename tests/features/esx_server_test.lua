local h = require('tests.support.harness')

local function createServerEsx(calls)
  local xPlayer = {}

  function xPlayer.addInventoryItem(name, count)
    calls[#calls + 1] = { 'addInventoryItem', name, count }
  end

  function xPlayer.removeInventoryItem(name, count)
    calls[#calls + 1] = { 'removeInventoryItem', name, count }
  end

  function xPlayer.addAccountMoney(name, count)
    calls[#calls + 1] = { 'addAccountMoney', name, count }
  end

  function xPlayer.removeAccountMoney(name, count)
    calls[#calls + 1] = { 'removeAccountMoney', name, count }
  end

  return {
    GetPlayerFromId = function(playerSource)
      if playerSource == 7 then
        return xPlayer
      end

      return nil
    end,
  }
end

h.test('server esx applies item and account transactions for a player source', function()
  local calls = {}
  h.reset('server', {
    esx = createServerEsx(calls),
  })
  local esx = h.load('server/modules/esx/index.lua')

  h.assertTrue(esx.giveItem(7, 'bread', 2))
  h.assertTrue(esx.addMoney(7, 'bank', 100))

  h.assertEqual('addInventoryItem', calls[1][1])
  h.assertEqual('bread', calls[1][2])
  h.assertEqual(2, calls[1][3])
  h.assertEqual('addAccountMoney', calls[2][1])
  h.assertEqual('bank', calls[2][2])
  h.assertEqual(100, calls[2][3])
end)

h.test('server esx rejects malformed requests and missing players', function()
  h.reset('server', {
    esx = createServerEsx({}),
  })
  local esx = h.load('server/modules/esx/index.lua')

  h.assertFalse(esx.giveItem(99, 'bread', 2))
  h.assertFalse(esx.giveItems(7, {
    { itemName = 'bread', amount = '2' },
  }))
  h.assertFalse(esx.transactions(7, {
    { 99, { { 'bread', 1 } } },
  }))
end)
