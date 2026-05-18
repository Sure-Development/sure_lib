# ESX.Game
Functions related to modifying the game/client.

### GetPedMugshot 
This function takes a mugshot from given ped and returns it as a texture.

**Arguments** 
- ped: `ped` object
  - The ped you want a mugshot from.
- transparent?: `boolean` (Default: `false`)
  - Should the picture be transparent?

**Returns**
- mugshot: `string`
  - The mugshot
- txd: `string`
  - The mugshot texture as base64 string

**Example** 
```lua
local ped = PlayerPedId() 
local mugshot, txd = ESX.Game.GetPedMugshot(ped, true)
```

---

### Teleport
Teleports the given entity to the given coords and triggers the callback once finished.

**Arguments**
- entity: `entity` handle
  - The entity to teleport.
- coords: `vector3` | `vector4`
  - The coords the entity should be teleported to.
- cb?: `function`
  - The callback function that will be triggered after.

**Example** 
```lua
local entity = PlayerPedId() 

ESX.Game.Teleport(entity, vector3(0,0,0), function() 
      print('player is teleported') 
end)
```

---

### SpawnObject 
This function will spawn an object with given model at given coords. And can be networked.

**Arguments**
- model: `string` or hash
  - The model name or hash of the object
- coords: `vector3`
  - Where the object should be spawned
- cb?: `function`
  - the callback function
- networked?: `boolean` (Default: `true`)
  - If the object should be networked(Sent to other players) or not

**Callback Example** 
```lua
local coords = GetEntityCoords(PlayerPedId()) 
ESX.Game.SpawnObject('prop_tool_bluepnt', coords, function() 
  print(("object was spawned with the id %s"):format(object)) 
end, true)
```

---

**Return-Based Example** 
```lua
local coords = GetEntityCoords(PlayerPedId())
local object = ESX.Game.SpawnObject('prop_tool_bluepnt', coords, nil, false)
print(("object was spawned with the id %s"):format(object)) 
```

### SpawnLocalObject 
This function will spawn a local object with given model at given coords.

**Info**
    This function only exits for backwards compatibility. You should use `ESX.Game.SpawnObject(model, coords, cb, false)` instead.

**Arguments**
- model: `string` | `number`
  - The model name or hash of the object.
- coords: `vector3`
  - Where the object needs to be spawned.
- cb?: `function`
  - The callback function.

**Example** 
```lua
local coords = GetEntityCoords(PlayerPedId()) 
ESX.Game.SpawnObject('prop_tool_bluepnt', coords, function() 
  print('object is spawned') 
end)
```

---

### DeleteVehicle 
This function will delete given vehicle.

**Arguments**
- vehicle: `number` (vehicle handle)
  - The vehicle that should be removed

**Example** 
```lua
local vehicle = GetVehiclePedIsIn(PlayerPedId(), false) 
ESX.Game.DeleteVehicle(vehicle) 
```

---

### DeleteObject
This function will delete given object.

**Arguments**
- object: `number` (object handle)
  - the object that needs to be removed

**Example** 
```lua
ESX.Game.DeleteObject(object) 
```

---

### SpawnVehicle
This function spawns the given vehicle model at the specified coordinates. If a callback is provided, it will be called once the vehicle is spawned.

**Arguments**
- vehicleModel: `string` | `number`
  - The model name or hash of the vehicle to spawn.
- coords: `vector3`
  - The coordinates where the vehicle needs to be spawned.
- heading: `number`
  - The heading of the vehicle.
- cb: `function?`
  - The callback function to be invoked once the vehicle is spawned. If not provided, a promise is used instead, and it resolves when the vehicle is spawned.
- networked: `boolean?`
  - If the vehicle should be networked or local. Default is `true` (networked) if not provided.

**Returns**
- `number?` vehicle
  - The vehicle entity handle. This is returned if no callback is provided and a promise is used instead.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())

-- Example with callback:
ESX.Game.SpawnVehicle('blista', coords, 0.0, function(vehicle)
    print("Vehicle spawned with callback:", vehicle) -- prints the vehicle entity handle
end, true)

-- Example with promise (no callback):
local vehicle = ESX.Game.SpawnVehicle('blista', coords, 0.0, nil, true)
print("Vehicle spawned with promise:", vehicle) -- prints the vehicle entity handle
```

---

### SpawnLocalVehicle
This function will spawn given vehicle with model at given coords.

**Warning**
    This function is maintained solely for backwards compatibility. Please use [ESX.Game.SpawnVehicle](#spawnvehicle) instead.

**Arguments**
- vehicleModel: `string`| `number`
  - The model name or hash.
- coords: `vector3`
  - Where the vehicle needs to be spawned.
- heading: `number`
  - The heading of the vehicle
- cb: `function`
  - The callback function.

**Example** 
```lua
ESX.Game.SpawnLocalVehicle('blista', coords, 0.0, function(vehicle)
    print(vehicle) 
end)  
```

---

### IsVehicleEmpty
This function will return a `boolean` if the vehicle is empty.

**Arguments**
- vehicle: `number`(vehicle handle)
  - The vehicle you want to check

**Example** 
```lua
local vehicle = GetVehiclePedIsIn(PlayerPedId(), true) 
local isEmpty = ESX.Game.IsVehicleEmpty(vehicle)

if isEmpty then
    print('Vehicle is empty!')
end
```

---

### GetObjects
Returns all objects the client has currently loaded.

**Info**
    This function only exits for backwards compatibility. You could use `GetGamePool('CObject')` instead.

**Example** 
```lua
local objects = ESX.Game.GetObjects() 

for i=1, #objects do 
    local object = objects[i] 
end 
```

---

### GetPeds
Returns all peds the client has currently loaded.

**Arguments**
- onlyOtherPeds: `boolean`
  - Should the own ped be filtered out?

**Example** 
```lua
local objects = ESX.Game.GetPeds(true) 

print('We found ' .. #objects .. ' peds other then you!')
```

---

### GetVehicles
Returns all vehicles the client has loaded.

**Info**
    This function only exits for backwards compatibility. You could use `GetGamePool('CVehicle')` instead.

**Example** 
```lua
local vehicles = ESX.Game.GetVehicles() 

for i=1, #vehicles do
    local vehicle = vehicles[i] 
end 
```

---

### GetPlayers
Returns all players the client has currently loaded.

**Arguments**
- onlyOtherPlayers: `boolean`
  - Should the own player be filtered out?
- returnPeds?: `boolean` (Default: `false`)
  - Should the value be the ped? Otherwise player id. (Value always ped with `returnKeyValue` true)

### GetClosestEntity
Returns the closest entity's handle and distance to the object in the given table.

**Arguments**
- entities: `table`
  - The entities to filter through
- isPlayerEntities: `boolean`
  - Is the table filled with players?
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- filter: `table`
  - Only look for specific value (model / player id)

**Returns**
- closestObject: `number`(object handle)
  - The handle of the closest object.
- closestObjectDistance: `number`
  - The distance to the object.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local closestObject, distance = ESX.Game.GetClosestObject(coords, {
    ["prop_weed_01"] = true,
    ["prop_weed_02"] = true,
})
```

---

### GetClosestObject
Returns the closest object's handle and distance to the object.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- modelFilter: `table`
  - Only look for specific models

**Returns**
- closestObject: `number`(object handle)
  - The handle of the closest object.
- closestObjectDistance: `number`
  - The distance to the object.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local closestObject, distance = ESX.Game.GetClosestObject(coords, {
    ["prop_weed_01"] = true,
    ["prop_weed_02"] = true,
})
```

---

### GetClosestPed
Returns the closest ped's handle and distance to the ped.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- modelFilter: `table`
  - Only look for specific models

**Returns**
- closestPed: `number`(ped handle)
  - The handle of the closest ped.
- closestPedDistance: `number`
  - The distance to the ped.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local closestPed, distance = ESX.Game.GetClosestPed(coords, {
    ["a_f_m_beach_01"] = true,
    ["a_m_y_hipster_02"] = true,
})
```

---

### GetClosestPlayer
Returns the closest player's id and distance to the player.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- modelFilter: `table`
  - Only look for specific models

**Returns**
- closestPed: `number`(ped handle)
  - The player id of the closest player.
- closestPedDistance: `number`
  - The distance to the player.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local closestPlayer, distance = ESX.Game.GetClosestPlayer(coords, {
    [5] = true,
    [9] = true,
})
```

---

### GetClosestVehicle
Returns the closest vehicle's handle and distance to the vehicle.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- modelFilter: `table`
  - Only look for specific models

**Returns**
- closestVehicle: `number`(ped handle)
  - The handle of the closest vehicle.
- closestVehicleDistance: `number`
  - The distance to the vehicle.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local closestVehicle, distance = ESX.Game.GetClosestVehicle(coords, {
    ["t20"] = true,
    ["zentorno"] = true,
})
```

---

### GetPlayersInArea
Returns all players in specified radius.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- maxDistance: `table`
  - The radius to search in.


**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local playersInArea = ESX.Game.GetPlayersInArea(coords, 20)

print('Found ' .. #playersInArea .. ' player in area')
```

---

### GetVehiclesInArea
Returns all vehicles in speicified radius.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- maxDistance: `table`
  - The radius to search in.

**Example**
```lua
local coords = GetEntityCoords(PlayerPedId())
local vehiclesInArea = ESX.Game.GetVehiclesInArea(coords, 20)

print('Found ' .. #vehiclesInArea .. ' vehicles in area')
```

---

### IsSpawnPointClear
Returns a `boolean` saying if the given space is clear of other vehicles.

**Arguments**
- coords: `vector` (Default: Player coords)
  - Coordinates to search at.
- maxDistance: `table`
  - The radius to search in.

**Example**
```lua
RegisterCommand('spawnCoolVehicle', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if ESX.Game.IsSpawnPointClear(coords, 10) then
        ESX.Game.SpawnVehicle('t20', coords, heading, function(vehicle)
            print(vehicle) 
        end, true)  
    end
end)
```

---

### GetShapeTestResultSync
Returns the result of a shape test/raycast.

**Arguments**
- shape: `number`
  - The return of the shape test probe.

**Returns**
- hit: `boolean`
  - Did the shape test hit something?
- coords: `vec3`
  - The coords of the hit.
- normal: `number`
  - The surface normal of the hit.
- material: `number`
  - The material of the thing hit.
- entity: `number`
  - The entity that was hit(if one was hit).

**Example**
```lua
--- Taken straight from ESX
function ESX.Game.RaycastScreen(depth, ...)
	local world, normal = GetWorldCoordFromScreenCoord(.5, .5)
	local origin = world + normal
	local target = world + normal * depth
	return target, ESX.Game.GetShapeTestResultSync(StartShapeTestLosProbe(origin.x, origin.y, origin.z, target.x, target.y, target.z, ...))
end
```

---

### RaycastScreen
Returns the result of a raycast from the screen.

**Trace flags**
-1. Intersect with everything
0. Don't intersect with anything
1. Intersects with the World
2. Intersects with Vehicles
4. Intersects with Peds
8. Intersects with Ragdolls
16. Intersects with Objects
32. Intersects with Water
64. Intersects with Glass
128. Intersects with Rivers
256. Intersects with Foliage

**Arguments**
- depth: `number`
  - The depth of the raycast.
- traceFlags?: `number`
  - The trace flags that define what the shape test will intersect with
- entity?: `number`
  - The entity that should be ignored.
- options?: `number`
  - The options for the shape test. Either 1, 2, 4 or 7. Usually 4 or 7.

**Example**
```lua
local _, hit, coords, _, _ = ESX.Game.RaycastScreen(10.0, -1, PlayerPedId(), 7)
print(("There is %s infront of the player at %s"):format(hit, coords))
```

---

### GetVehicleInDirection
Returns vehicle in front of player.

**Returns**
- vehicle: `number`(vehicle handle)
  - The handle of the vehicle.
- coords: `number`
  - The coords of the vehicle.

**Example**
```lua
local vehicle, coords = ESX.Game.GetVehicleInDirection()

if vehicle then
    print('Vehicle found!')
    print('It has ' .. GetEntityHealth(vehicle) .. ' health!')
end
```

---

### GetVehicleProperties  
Returns detailed properties about the given vehicle.

**Arguments**
- vehicle: `number` (vehicle handle)  
  - The handle of the vehicle.

**Returns**
- model: `number`  
  - The model hash of the vehicle.
- doorsBroken: `table`  
  - The vehicle doors and if they are broken.
- windowsBroken: `table`  
  - The vehicle windows and if they are broken.
- tyreBurst: `table`  
  - The vehicle tyres and if they are burst.
- tyresCanBurst: `boolean`  
  - Can the tyres burst?
- plate: `string`  
  - The vehicle plate.
- plateIndex: `number`  
  - The plate style index.
- bodyHealth: `number`  
  - The body health of the vehicle.
- engineHealth: `number`  
  - The engine health of the vehicle.
- tankHealth: `number`  
  - The petrol tank health.
- fuelLevel: `number`  
  - The vehicle's fuel level.
- dirtLevel: `number`  
  - The level of dirt on the vehicle.
- color1: `number | table`  
  - Primary color of the vehicle. Can be a color index or an RGB table like `{255, 255, 255}`.
- color2: `number | table`  
  - Secondary color of the vehicle. Can be a color index or an RGB table like `{255, 255, 255}`.
- pearlescentColor: `number`  
  - The pearlescent color index.
- wheelColor: `number`  
  - The wheel color index.
- dashboardColor: `number`  
  - The dashboard color index.
- interiorColor: `number`  
  - The interior color index.
- wheels: `number`  
  - The wheel type of the vehicle.
- windowTint: `number`  
  - The window tint of the vehicle.
- xenonColor: `number`  
  - The xenon lights color index.
- customXenonColor: `table`  
  - The custom xenon light RGB color `{255, 255, 255}`.
- neonEnabled: `table`  
  - Boolean table `{true, true, false, false}` for each neon side (LF, RF, LR, RR).
- neonColor: `table`  
  - The RGB color of the neon lights.
- extras: `table`  
  - The extras of the vehicle.
- tyreSmokeColor: `table`  
  - The color of the tyre smoke in RGB format.
- modSpoilers: `number`  
- modFrontBumper: `number`  
- modRearBumper: `number`  
- modSideSkirt: `number`  
- modExhaust: `number`  
- modFrame: `number`  
- modGrille: `number`  
- modHood: `number`  
- modFender: `number`  
- modRightFender: `number`  
- modRoof: `number`  
- modRoofLivery: `number`  
- modEngine: `number`  
- modBrakes: `number`  
- modTransmisson: `number`  
- modHorns: `number`  
- modSuspension: `number`  
- modArmor: `number`  
- modTurbo: `boolean`  
- modSmokeEnabled: `boolean`  
- modXenon: `boolean`  
- modFrontWheels: `number`  
- modCustomFrontWheels: `boolean`  
- modBackWheels: `number`  
- modCustomBackWheels: `boolean`  
- modPlateHolder: `number`  
- modVanityPlate: `number`  
- modTrimA: `number`  
- modOrnaments: `number`  
- modDashboard: `number`  
- modDial: `number`  
- modDoorSpeaker: `number`  
- modSeats: `number`  
- modSteeringWheel: `number`  
- modShifterLeavers: `number`  
- modAPlate: `number`  
- modSpeakers: `number`  
- modTrunk: `number`  
- modHydrolic: `number`  
- modEngineBlock: `number`  
- modAirFilter: `number`  
- modStruts: `number`  
- modArchCover: `number`  
- modAerials: `number`  
- modTrimB: `number`  
- modTank: `number`  
- modWindows: `number`  
- modLivery: `number`  
- modLightbar: `number`  

**Example**
```lua
local vehicle = GetVehiclePedIsIn(PlayerPedId(), false) 
local properties = ESX.Game.GetVehicleProperties(vehicle)

print("The vehicle has " .. #properties.doorsBroken .. " doors broken.")
```

---

### SetVehicleProperties
This function sets properties to the vehicle.

**Arguments**
- vehicle: `number`(vehicle handle)
  - The handle of the vehicle.

**Example**
```lua
local vehicle = GetVehiclePedIsIn(PlayerPedId(), false) 
ESX.Game.SetVehicleProperties(vehicle, {
    ["plate"] = "ABCD1234",
    ["fuelLevel"] = 100.0
})
```

---

### DrawText3D
This function draws a 3D Text

**Arguments**
- coords: `vec3`
  - The coords of where it should be displayed.
- text: `string`
  - Text that should be displayed.
- size?: `string` (Default: `1`)
  - What size the 3D Text should have
- font?: `string` (Default: `0`)
  - The font it should have (ID)

**Example**
```lua
CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        ESX.Game.Utils.DrawText3D(coords, "This person is a really cool guy")
        Wait(0)
    end
end)
```
