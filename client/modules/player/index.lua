local ESX = exports.es_extended:getSharedObject()
local upper = string.upper

local player = {}
local playerLoaded = promise.new()

CreateThread(function()
  while not ESX.IsPlayerLoaded() do
    Wait(500)
  end

  playerLoaded:resolve()
end)

--- @param entries table[]
--- @param entryName string
--- @return table?
local function findByName(entries, entryName)
  for _, entry in ipairs(entries) do
    if entry.name == entryName then
      return entry
    end
  end

  return nil
end

--- @param weaponName string
--- @return string
local function normalizeWeaponName(weaponName)
  local normalized = upper(weaponName)
  if normalized:sub(1, 7) == 'WEAPON_' then
    return normalized
  end

  return 'WEAPON_' .. normalized
end

--- @param entries table[]?
--- @param lookup fun(entryName: string): table?
--- @return table
local function withLookup(entries, lookup)
  entries = entries or {}
  return setmetatable(entries, {
    __index = function(_, key)
      if type(key) ~= 'string' then
        return nil
      end

      return lookup(key)
    end,
  })
end

--- @return table
local function getPlayerData()
  return ESX.GetPlayerData() or {}
end

return setmetatable(player, {
  __index = function(_, key)
    if key == 'inventory' then
      local inventory = getPlayerData().inventory
      return withLookup(inventory, function(itemName)
        return findByName(inventory or {}, itemName)
      end)
    end

    if key == 'accounts' then
      local accounts = getPlayerData().accounts
      return withLookup(accounts, function(accountName)
        return findByName(accounts or {}, accountName)
      end)
    end

    if key == 'loadout' then
      local loadout = getPlayerData().loadout
      return withLookup(loadout, function(weaponName)
        return findByName(loadout or {}, normalizeWeaponName(weaponName))
      end)
    end

    if key == 'data' then
      return getPlayerData()
    end

    if key == 'loaded' then
      return ESX.IsPlayerLoaded()
    end

    if key == 'ped' then
      return PlayerPedId()
    end

    if key == 'health' then
      return GetEntityHealth(PlayerPedId())
    end

    if key == 'armor' then
      return GetEntityArmor(PlayerPedId())
    end

    if key == 'coords' then
      return GetEntityCoords(PlayerPedId())
    end

    if key == 'vehicle' then
      return cache.vehicle
    end

    if key == 'serverId' then
      return cache.serverId
    end

    if key == 'waitUntilLoaded' then
      return function()
        return Citizen.Await(playerLoaded)
      end
    end

    if key == 'currentVehicleProperties' then
      return cache.vehicle and ESX.Game.GetVehicleProperties(cache.vehicle) or nil
    end

    return nil
  end,
})
