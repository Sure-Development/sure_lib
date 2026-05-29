local spawn = {}
local registry = {}
local streamEntries = {}
local tostring = tostring
local type = type

local function cloneSpawnOpts(opts)
  local cloned = {}
  for key, value in pairs(opts or {}) do
    if key ~= 'spawnOnNear' then
      cloned[key] = value
    end
  end

  return cloned
end

local function resolveModel(model)
  if type(model) == 'string' then
    return GetHashKey(model)
  end

  return model
end

local function awaitModel(model, modelHash)
  local modelPromise = promise.new()

  CreateThread(function()
    local timeout = GetGameTimer() + 10000
    RequestModel(modelHash)

    while not HasModelLoaded(modelHash) do
      if GetGameTimer() >= timeout then
        print('[sure_lib][spawn] model timeout: ' .. tostring(model))
        modelPromise:resolve(false)
        return
      end

      Wait(0)
    end

    modelPromise:resolve(true)
  end)

  return Citizen.Await(modelPromise)
end

local function awaitAnimDict(dict)
  local animPromise = promise.new()

  CreateThread(function()
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
      Wait(0)
    end

    animPromise:resolve(true)
  end)

  return Citizen.Await(animPromise)
end

local function registerHandle(handle, scopeState)
  if handle == nil then
    return
  end

  registry[handle] = true
  if scopeState then
    scopeState.handles[handle] = true
  end
end

local function unregisterHandle(handle, scopeState)
  if handle == nil then
    return
  end

  registry[handle] = nil
  if scopeState then
    scopeState.handles[handle] = nil
  end
end

local function deleteHandle(handle, scopeState)
  if handle == nil then
    return
  end

  if DoesEntityExist(handle) then
    if NetworkGetEntityIsNetworked(handle) then
      NetworkRequestControlOfEntity(handle)
      SetEntityAsMissionEntity(handle, true, true)
    end

    DeleteEntity(handle)
  end

  unregisterHandle(handle, scopeState)
end

local function applySharedOpts(handle, opts)
  if opts.freeze ~= nil then
    FreezeEntityPosition(handle, opts.freeze)
  end

  if opts.invincible ~= nil then
    SetEntityInvincible(handle, opts.invincible)
  end

  SetEntityCollision(handle, opts.collision ~= false, true)

  if opts.alpha ~= nil then
    SetEntityAlpha(handle, opts.alpha, false)
  end
end

local function applyPedOpts(handle, opts)
  if opts.blockEvents ~= nil then
    SetBlockingOfNonTemporaryEvents(handle, opts.blockEvents)
  end

  SetPedDiesWhenInjured(handle, opts.diesOnInjury == true)

  if opts.scenario ~= nil then
    TaskStartScenarioInPlace(handle, opts.scenario, 0, true)
  end

  if opts.animation ~= nil then
    awaitAnimDict(opts.animation.dict)
    TaskPlayAnim(handle, opts.animation.dict, opts.animation.clip, 8.0, -8.0, -1, opts.animation.flag or 0, 0.0, false, false, false)
  end
end

local function spawnEntityInternal(kind, model, coords, heading, opts, scopeState)
  opts = opts or {}

  local modelHash = resolveModel(model)
  if not awaitModel(model, modelHash) then
    return nil
  end

  local networked = opts.networked == true
  local handle = nil

  if kind == 'ped' then
    handle = CreatePed(4, modelHash, coords.x, coords.y, coords.z, heading or 0.0, networked, false)
  else
    handle = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, networked, false, false)
  end

  applySharedOpts(handle, opts)

  if kind == 'ped' then
    applyPedOpts(handle, opts)
  else
    if opts.rotation ~= nil then
      SetEntityRotation(handle, opts.rotation.x, opts.rotation.y, opts.rotation.z, 2, true)
    end

    if opts.placeOnGround == true then
      PlaceObjectOnGroundProperly(handle)
    end
  end

  SetModelAsNoLongerNeeded(modelHash)
  registerHandle(handle, scopeState)

  return handle
end

local function removePoint(entry)
  if entry.point == nil then
    return
  end

  entry.point:remove()
  entry.point = nil
end

local function deleteEntry(entry)
  removePoint(entry)
  deleteHandle(entry.handle, entry.scopeState)
  entry.handle = nil
  entry.spawned = false
end

local function registerStreamEntry(kind, model, coords, heading, opts, scopeState)
  local spawnOnNear = opts.spawnOnNear
  if spawnOnNear.coords == nil then
    error('[sure_lib][spawn] spawnOnNear.coords is required', 3)
  end

  if spawnOnNear.radius == nil then
    error('[sure_lib][spawn] spawnOnNear.radius is required', 3)
  end

  local entry = {
    handle = nil,
    point = nil,
    scopeState = scopeState,
    spawned = false,
  }

  entry.point = lib.points.new({
    coords = spawnOnNear.coords,
    distance = spawnOnNear.despawnRadius or spawnOnNear.radius * 1.5,

    onEnter = function() end,

    nearby = function(point)
      if not entry.spawned and point.currentDistance <= spawnOnNear.radius then
        entry.handle = spawnEntityInternal(kind, model, coords, heading, cloneSpawnOpts(opts), scopeState)
        entry.spawned = entry.handle ~= nil
      end

      if entry.spawned and spawnOnNear.onNear then
        spawnOnNear.onNear({
          handle = entry.handle,
          distance = point.currentDistance,
          coords = spawnOnNear.coords,
          spawned = entry.spawned,
        })
      end
    end,

    onExit = function()
      if entry.spawned then
        deleteHandle(entry.handle, scopeState)
        entry.handle = nil
        entry.spawned = false
      end
    end,
  })

  streamEntries[#streamEntries + 1] = entry
  if scopeState then
    scopeState.entries[#scopeState.entries + 1] = entry
  end

  return entry
end

local function spawnPed(model, coords, heading, opts, scopeState)
  opts = opts or {}
  if opts.spawnOnNear ~= nil then
    return registerStreamEntry('ped', model, coords, heading, opts, scopeState)
  end

  return spawnEntityInternal('ped', model, coords, heading, opts, scopeState)
end

local function spawnObject(model, coords, opts, scopeState)
  opts = opts or {}
  if opts.spawnOnNear ~= nil then
    return registerStreamEntry('object', model, coords, nil, opts, scopeState)
  end

  return spawnEntityInternal('object', model, coords, nil, opts, scopeState)
end

function spawn:ped(model, coords, heading, opts)
  return spawnPed(model, coords, heading, opts, nil)
end

function spawn:object(model, coords, opts)
  return spawnObject(model, coords, opts, nil)
end

function spawn:scope()
  local scopeState = {
    entries = {},
    handles = {},
  }

  local scope = {}

  function scope:ped(model, coords, heading, opts)
    return spawnPed(model, coords, heading, opts, scopeState)
  end

  function scope:object(model, coords, opts)
    return spawnObject(model, coords, opts, scopeState)
  end

  function scope:deleteAll()
    for _, entry in ipairs(scopeState.entries) do
      deleteEntry(entry)
    end

    for handle in pairs(scopeState.handles) do
      deleteHandle(handle, scopeState)
    end
  end

  return scope
end

function spawn:deleteAll()
  for _, entry in ipairs(streamEntries) do
    removePoint(entry)
  end

  for handle in pairs(registry) do
    deleteHandle(handle, nil)
  end
end

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end

  spawn:deleteAll()
end)

return spawn
