# Serverside OneSync Functions
Functions used to get data that normally is available on the client. And functions to spawn synced entities.

## GetPlayersInArea
This function gets all players in the given radius. 

**Arguments**

- playerId?: `number`
  - The server id of the player you want to get the near players from.
- radius?: `number` (Default: `100`)
  - The radius to search for players.
- ignore?: `table`
  - A table with server id's that should be ignored.

**Returns**

This function will return a **`table`** with data or an empty **`table`** if no player was found. 
- id: `number`
  - The id from the player.
- ped: `string`
  - The ped handle of the player.
- coords: `vector3`
  - The coordinates of the player.
- dist: `number`
  - The distance to the player.


**Example**
```lua
local playersInArea = ESX.OneSync.GetPlayersInArea(1, 10.0, {
    [1] = true -- filter out player with the source 1
})
    
for i=1, #playersInArea do
    local player = playersInArea[i] 
end 
```

## GetClosestPlayer
This function returns the closest player from the given player. 

**Arguments**

- playerId?: `number`
  - The server id of the player you want to get the closest player from.
- radius?: `number` (Default: `100`)
  - The radius to search for players.
- ignore?: `table`
  - A table with server id's that should be ignored.

**Returns**

This function will return a **`table`** with data or an empty **`table`** if no player was found.
- id: `number`
  - The id from the player.
- ped: `string`
  - The ped handle of the player.
- coords: `vector3`
  - The coordinates of the player.
- dist: `number`
  - The distance to the player.

**Example**
```lua
local player = ESX.OneSync.GetClosestPlayer(1, 10.0, {
    [2] = true -- filter out player with source 2
})
```

## SpawnVehicle
This function will spawn a vehicle with the vehicle server setter, meaning the vehicle will belong to the server and won't be removed when no clients are active.

**Warning**
    When there is no player within a 300-meter radius of the coordinates, the vehicle will NOT spawn. Also, vehicle deformation will not be synced anymore once no player is in its scope.

**Arguments**
- model: `string`
  - The model name of the vehicle.
- coords: `vector3`
  - The coordinates where the vehicle should spawn.
- heading: `number`
  - The heading of the vehicle.
- properties: `table`
  - A table with properties that should be set on the vehicle.
- cb: `fun(networkId: number)?` 
  - A callback function that will be called when the vehicle is spawned. If not provided, a promise is used instead, and it resolves when the vehicle is spawned.
- vehType: `string?`
  - Optional: The vehicle type (automobile, bike, boat, heli, plane, submarine, trailer, train). If specified, allows vehicle to spawn even without a player in onesync range.

**Example**
```lua
-- With callback
ESX.OneSync.SpawnVehicle('blista', vector3(0, 0, 0), 0, {}, function(networkId)     
    local vehicle = NetworkGetEntityFromNetworkId(networkId)
end)  

-- With promise (no callback)
local networkId = ESX.OneSync.SpawnVehicle('blista', vector3(0, 0, 0), 0, {})
local vehicle = NetworkGetEntityFromNetworkId(networkId)

-- With vehicle type
local networkId = ESX.OneSync.SpawnVehicle('blista', vector3(0, 0, 0), 0, {}, nil, "automobile")
local vehicle = NetworkGetEntityFromNetworkId(networkId)
```

## SpawnObject 
This function will spawn an object from the Serverside. 

**Arguments**
- model: `number` | `string`
  - The model name or hash of the object.
- coords: `vector3`
  - The coordinates where the object should spawn.
- heading: `number`
  - The heading of the object.
- cb: `fun(networkId: number)?` 
  - A callback function that will be called when the object is spawned. If not provided, a promise is used instead, and it resolves when the object is spawned.

**Example**
```lua
ESX.OneSync.SpawnObject('prop_rub_boxpile_04', vector3(0,0,0), 0.0, function(networkId) 
    local obj = NetworkGetEntityFromNetworkId(networkId) 
end) 

-- With promise (no callback function)
local networkId = ESX.OneSync.SpawnObject('prop_rub_boxpile_04', vector3(0, 0, 0), 0.0)
``` 

## SpawnPed 
This function will spawn a ped.

**Arguments**
- model: `string`
  - The model name of the ped.
- coords: `vector3`
  - The coordinates where the ped should spawn.
- heading: `number`
  - The heading of the ped.
- cb: `fun(networkId: number)?` 
  - A callback function that will be called when the ped is spawned. If not provided, a promise is used instead, and it resolves when the ped is spawned.

**Example**
```lua
ESX.OneSync.SpawnPed('a_f_m_beach_01', vector3(0,0,0), 0.0, function(networkId) 
    local ped = NetworkGetEntityFromNetworkId(networkId) 
end) 

-- With promise (no callback function)
local networkId = ESX.OneSync.SpawnPed('a_f_m_beach_01', vector3(0, 0, 0), 0.0)
``` 

## SpawnPedInVehicle 
This function will spawn a ped inside a vehicle.

**Arguments**
- model: `string`
  - The model name of the ped.
- vehicle: `number`
  - The network id of the vehicle.
- seat: `number`
  - The seat where the ped should spawn in.
- cb: `fun(networkId: number)?` 
  - A callback function that will be called when the ped is spawned. If not provided, a promise is used instead, and it resolves when the ped is spawned.

**Example**
```lua
local vehicles = GetAllVehicles()

if #vehicles < 1 then return end 
ESX.OneSync.SpawnPedInVehicle('a_f_m_beach_01', vehicles[math.random(1, #vehicles)], -1, function(networkId)
    local ped = NetworkGetEntityFromNetworkId(networkId) 
end)

-- With promise (no callback function)
local networkId = ESX.OneSync.SpawnPedInVehicle('a_f_m_beach_01', vehicles[math.random(1, #vehicles)] -1)
```

## GetPedsInArea 
This function will get all peds in given area.

**Arguments**

- coords: `vector3`
  - The coordinates where the peds should be searched.
- radius: `number`
  - The radius to search for peds.
- modelFilter?: `table`
  - A table with model's that should be ignored.

**Returns**

This function will return a **`table`** with the network id's from the found peds.


**Example**
```lua
local peds = ESX.OneSync.GetPedsInArea(vector3(0,0,0), 30.0, {
    [joaat('a_f_m_beach_01')] = true -- joaat is a function of lua v5.4 that returns a hash
})

for i=1, #peds do 
    local ped = NetworkGetEntityFromNetworkId[peds[i]] 
end 
```

## GetObjectsInArea 
This function will get all objects in given area.

**Arguments**

- coords: `vector3`
  - The coordinates where the objects should be searched.
- radius: `number`
  - The radius to search for objects.
- modelFilter?: `table`
  - A table with model's that should be ignored.

**Returns**

This function will return a table with the network id's from the found objects

**Example**
```lua
local objects = ESX.OneSync.GetObjectsInArea(vector3(0,0,0), 30.0, {
    [joaat('prop_rub_boxpile_04')] = true -- joaat is a function of lua v5.4 that returns a hash
})

for i=1, #objects do 
    local object = NetworkGetEntityFromNetworkId[objects[i]]   
end 
```

## GetVehiclesInArea 
This function will get all vehicles in given area.

**Arguments**
- coords: `vector3`
  - The coordinates where the vehicles should be searched.
- radius: `number`
  - The radius to search for vehicles.
- modelFilter?: `table`
  - A table with model's that should be ignored.

**Returns**

This function will return a table with the network id's from the found objects

**Example**
```lua
local vehicles = ESX.OneSync.GetVehiclesInArea(vector3(0,0,0), 30.0, {
    [joaat('zentorno')] = true -- joaat is a function of lua v5.4 that returns a hash
})

for i=1, #vehicles do 
    local vehicle = NetworkGetEntityFromNetworkId[vehicles[i]]   
end 
```

## GetClosestPed 
This function will return the closest object to given coords.

**Arguments**
- coords: `vector3`
  - The coordinates where the closest ped should be searched.
- modelFilter?: `table`
  - A table with model's that should be ignored.


**Example**
```lua
local networkId, distance, closestCoords = ESX.OneSync.GetClosestPed(vector3(0,0,0), {
    [joaat('mp_m_freemode_01')] = true -- joaat is a function of lua v5.4 that returns a hash
})
```

## GetClosestObject 
This function will return the closest object to given coords.

**Arguments**
- coords: `vector3`
  - The coordinates where the closest object should be searched.
- modelFilter?: `table`
  - A table with model's that should be ignored.

**Example**
```lua
local networkId, distance, closestCoords = ESX.OneSync.GetClosestObject(vector3(0,0,0), {
    [joaat('prop_rub_boxpile_04')] = true -- joaat is a function of lua v5.4 that returns a hash
})
```

## GetClosestVehicle
This function will return the closest vehicle to given coords

**Arguments**
- coords: `vector3`
  - The coordinates where the closest vehicle should be searched.
- modelFilter?: `table`
  - A table with model's that should be ignored.

**Example**
```lua
local networkId, distance, closestCoords = ESX.OneSync.GetClosestVehicle(vector3(0,0,0), {
    [joaat('zentorno')] = true -- joaat is a function of lua v5.4 that returns a hash
})
```
