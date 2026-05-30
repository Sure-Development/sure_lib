local h = require('tests.support.harness')

h.test('spawn creates peds and applies ergonomic options', function()
  local context = h.reset('client', {
    modelHashes = {
      ['a_m_m_business_01'] = 123,
    },
  })
  local spawn = h.load('client/modules/spawn/index.lua')

  local handle = spawn:ped('a_m_m_business_01', { x = 1, y = 2, z = 3 }, 90, {
    alpha = 180,
    blockEvents = true,
    collision = false,
    freeze = true,
    invincible = true,
    networked = true,
    scenario = 'WORLD_HUMAN_CLIPBOARD',
  })

  h.assertEqual(1001, handle)
  h.assertEqual(123, context.requestedModels[1])
  h.assertEqual(123, context.spawnedPeds[1].modelHash)
  h.assertEqual(90, context.spawnedPeds[1].heading)
  h.assertTrue(context.spawnedPeds[1].networked)
  h.assertTrue(context.entityOptions[handle].freeze)
  h.assertTrue(context.entityOptions[handle].invincible)
  h.assertFalse(context.entityOptions[handle].collision)
  h.assertEqual(180, context.entityOptions[handle].alpha)
  h.assertTrue(context.entityOptions[handle].blockEvents)
  h.assertEqual('WORLD_HUMAN_CLIPBOARD', context.entityOptions[handle].scenario)
end)

h.test('spawn scopes delete spawned objects together', function()
  local context = h.reset('client', {
    modelHashes = {
      prop_barrel_02a = 321,
    },
  })
  local spawn = h.load('client/modules/spawn/index.lua')
  local scope = spawn:scope()

  local handle = scope:object('prop_barrel_02a', { x = 10, y = 20, z = 30 }, {
    rotation = { x = 0, y = 0, z = 90 },
  })
  scope:deleteAll()

  h.assertEqual(321, context.spawnedObjects[1].modelHash)
  h.assertEqual(90, context.entityOptions[handle].rotation.z)
  h.assertEqual(handle, context.deletedEntities[1])
end)

h.test('spawnOnNear streams entities and cleans them up on exit', function()
  local nearState = nil
  local context = h.reset('client', {
    modelHashes = {
      ['a_m_m_business_01'] = 123,
    },
  })
  local spawn = h.load('client/modules/spawn/index.lua')

  local entry = spawn:ped('a_m_m_business_01', { x = 1, y = 2, z = 3 }, 180, {
    spawnOnNear = {
      coords = { x = 50, y = 60, z = 70 },
      radius = 5,
      despawnRadius = 8,
      onNear = function(state)
        nearState = state
      end,
    },
  })

  h.assertEqual(8, context.points[1].distance)
  h.assertFalse(entry.spawned)

  context.points[1].nearby({
    currentDistance = 6,
  })

  h.assertFalse(entry.spawned)
  h.assertEqual(0, #context.spawnedPeds)
  h.assertFalse(nearState.spawned)
  h.assertEqual(6, nearState.distance)

  context.points[1].nearby({
    currentDistance = 4,
  })

  h.assertTrue(entry.spawned)
  h.assertEqual(1001, entry.handle)
  h.assertEqual(1001, nearState.handle)
  h.assertEqual(4, nearState.distance)

  context.points[1].onExit()

  h.assertFalse(entry.spawned)
  h.assertEqual(1001, context.deletedEntities[1])
end)

h.test('spawnOnNear accepts root onNear when explicit stream config is provided', function()
  local nearState = nil
  local context = h.reset('client', {
    modelHashes = {
      ['a_m_m_business_01'] = 123,
    },
  })
  local spawn = h.load('client/modules/spawn/index.lua')

  local entry = spawn:ped('a_m_m_business_01', { x = 1, y = 2, z = 3 }, 180, {
    spawnOnNear = {
      coords = { x = 50, y = 60, z = 70 },
      radius = 5,
      despawnRadius = 8,
    },
    onNear = function(state)
      nearState = state
    end,
  })

  context.points[1].nearby({
    currentDistance = 4,
  })

  h.assertTrue(entry.spawned)
  h.assertEqual(1001, nearState.handle)
  h.assertEqual(4, nearState.distance)
end)

h.test('spawnOnNear requires radius to avoid invalid point distances', function()
  h.reset('client')
  local spawn = h.load('client/modules/spawn/index.lua')

  h.assertErrorContains(function()
    spawn:object('prop_barrel_02a', { x = 0, y = 0, z = 0 }, {
      spawnOnNear = {
        coords = { x = 0, y = 0, z = 0 },
      },
    })
  end, 'spawnOnNear.radius is required')
end)
