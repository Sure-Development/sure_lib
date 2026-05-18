# Serverside Functions

## Globals
These global variables are saved in the ESX table. You can freely use their data.

**Warning**
Directly accessing the global tables is strongly discouraged. These tables will be **empty** upon server startup, and any changes made to them **will not propagate** to importing resources. Instead, please utilize the provided backing functions to ensure proper data handling and synchronization:

- [ESX.GetExtendedPlayers](#getextendedplayers)
- [ESX.GetJobs](#getjobs)
- [ESX.GetNumPlayers](#getnumplayers)
- [ESX.GetItems](#getitems)

- Players
  - All loaded players.
- Jobs
  - All registered Jobs.
- JobsPlayerCount
  - All registered Jobs and their player count.
- Items
  - All registered Items.


## Print a Trace
This function prints a message to the console when Debug is enabled in the ESX Config.

**Arguments**
- msg: `string`
  - The message to print.

**Example**

```lua 
local xPlayer = ESX.GetPlayerFromId(playerId) 

if xPlayer.admin then
    ESX.Trace(xPlayer.name .. " is an Admin.") -- "[TRACE] John Doe is an Admin." when Debug is enabled.
end
```

## RegisterServerCallback
This function registers a server callback, which is used for sending Server Data, to a client.

See [*TriggerServerCallback*](../client/modules/callback.md#triggerservercallback)

**Arguments**
- name: `string`
  - The name of the callback.
- cb: `function`
  - The callback function.
- ...: `any`
  - The arguments to pass to the callback function.

**Example**
```lua
local myMemeServer = 'Meme data string'
-- The first argument of the handler function is the player source (NetID),
-- cb is the callback function we call when we want to return data to client
-- subsequent parameters were the arguments called from the client.
ESX.RegisterServerCallback('myScript:getMeme', function(src, cb, param1, param2)
  -- Logic needed to derive whatever data you would like to send back
  -- using the passed params on the handler (src, param1, param2, etc)

  -- Send back our meme data to client handler
  cb(myMemeServer)
end)
```

## TriggerClientCallback
This function triggers a client callback, which is used to get data from the client.

**Warning**
    This should be used with caution! You should never trust data from the client.
    So don't use it to get sensitive data, like money amount the player should receive.

**Arguments**
- player: `number`
  - The player source that the callback should get triggered for.
- eventName: `string`
  - The name of the callback.
- cb: `function`
  - The callback to trigger when the client responds.
- ...: `any`
  - The arguments that should be send to the client.

**Example**
```lua
ESX.TriggerClientCallback(player, "esx:GetVehicleType", function(vehicleType)
	print("The bati is a " .. vehicleType) -- "The bati is a bike"
end, "bati")
```

## AwaitClientCallback
This function trigger a previously registered client callback, but it will wait for the callback to return before continuing the script.

**Warning**
    This should be used with caution! You should never trust data from the client.
    So don't use it to get sensitive data, like money amount the player should receive.

**Arguments**
- player: `number`
  - The player source that the callback should get triggered for.
- eventName: `string`
  - The name of the callback.
- ...: `any`
  - The arguments that should be sent to the client.

**Example**
```lua
local vehicleType = ESX.AwaitClientCallback(player, "esx:getVehicleType", "bati")
print(("The bati is a %s"):format(vehicleType))
```

## RegisterCommand
This function registers a command.

**Arguments**
- name: `string` | `table`
  - The name of the command, or a list of aliases.
- group: `string` | `table`
  - The group able to run this command.
- cb: `function`
  - The callback function that gets ran.
  - xPlayer: `table`
    - The xPlayer object of the client.
  - args: `table`
    - The arguments the player has put in.
  - showError: `function`
    - The function to show an error message to the player.
- allowConsole?: `boolean`
  - If the command should be allowed to be run from the console.
- suggestion?: `table`
  - The suggestion that gets added to the chat.
  - help: `string`
    - The description of the command.
  - arguments: `table`
    - The arguments of the command.
    - name: `string`
      - The argument key.
    - help: `string`
      - Explanation of the argument.
    - type: `string`
      - Type of the argument. Possible Types: number, playerId, string, item, weapon, any, merge, coordinate.
    - Validator?: `table` Optional validation table for the argument.
      - validate: `function`
        - A validator function that gets the input passed as a param. Must return `true` or `false`.
      - err?: `string`
        - Optional error message if `validate` function is provided and returns false.

**Example**
```lua
ESX.RegisterCommand({'cardel', 'dv'}, 'admin', function(xPlayer, args, showError)
  if not args.radius then args.radius = 4 end
  xPlayer.triggerEvent('esx:deleteVehicle', args.radius)
end, false, {
    help = _U('command_cardel'), 
    arguments = {
        name = 'radius', 
        help = _U('command_cardel_radius'), 
        type = 'any',
        Validator = {
            validate = function(x) return x > 0 end,
            err = _U('commanderror_argumentmismatch_positive_number', 'radius')
        }
    }
})
```

## GetExtendedPlayers
This function returns all loaded xPlayers and if a filter is applied that match the filter. 
**Warning**
    This is no longer the prefered method to handle ESX player objects. Please refer to [ESX.ExtendedPlayers](#extendedplayers)

**Arguments**
- key?: `string`
  - The key to filter players from.
- value?: `any`
  - The value to filter players from.

**Returns**
A table with the xPlayer objects.

**Example**
```lua
local policeOfficers = ESX.GetExtendedPlayers('job', 'police')

for i, xPlayer in ipairs(policeOfficers) do
    print("Found Officer with " .. xPlayer.getJob().grade_label .. " rank.")
end
```

## GetNumPlayers
This function returns the amount of players online and if a filter is applied that match the filter. 

**Arguments**
- key?: `string`
  - The key to filter players from.
- value?: `any`
  - The value to filter players from.

**Returns**
A number with the players online matching the filter.

**Example**
```lua
local officersOnline = ESX.GetNumPlayers('job', 'police')

print("There are " .. officersOnline .. " officers online.")
```



## GetPlayerFromId
This function returns the xPlayer object of the specified playerId.
**Warning**
    This is no longer the prefered method to handle ESX player objects. Please refer to [ESX.Player](#player)

**Arguments**
- source: `number`
  - The player's server id.

**Returns**

The xPlayer object of the specified player.

**Example**
```lua
local xPlayer = ESX.GetPlayerFromId(5) -- Returns the xPlayer object of player 5

print("Player 5 is called " .. xPlayer.getName())
```


## GetPlayerFromIdentifier
This function returns the xPlayer object of the specified identifier.
**Warning**
    This is no longer the prefered method to handle ESX player objects. Please refer to [ESX.Player](#player)

**Arguments**
- identifier: `string`
  - The player's identifier.

**Returns**
The xPlayer object of the specified player.

**Example**
```lua
AddEventHandler('esx:onPlayerJoined', function ()
    local identifier = ESX.GetIdentifier(source)
    if ESX.GetPlayerFromIdentifier(identifier) then
        print("Player with the same identifier is already on the server.")
    end
end)
```

## Player
This function is the new preferred alternative to handle ESX player objects. It returns a lightweight table containing only the player's serverId. Subsequent function calls result in export calls, which can be more efficient.

**Arguments**
- source: `number` | `string`
  - The player's serverId or identifier.

**Returns**
A callable table representing the xPlayer object, which allows you to call player-related functions.

**Example**
```lua
AddEventHandler('esx:onPlayerJoined', function ()
    local xPlayer = ESX.Player(source)
    if not xPlayer then
        return
    end
    
    print(("Welcome %s!"):format(xPlayer.getName()))
end)
```

## ExtendedPlayers
This function is the new preferred alternative to handle multiple ESX player objects at once. It returns lightweight tables containing only the players' serverIds. Subsequent function calls result in export calls, which can be more efficient than working with full xPlayer objects.

**Arguments**
- key: `string?`
  - Optional filter key, e.g., `"job"`.
- val?: `any`
  - Optional value(s) to filter players by, e.g., `"police"` or `{"police", "ambulance"}`.

**Returns**
A table (or nested tables) of callable tables representing the xPlayer objects, which allow you to call player-related functions.

**Example**
```lua
local groupedPlayers = ESX.ExtendedPlayers("job", { "ambulance", "police" }) --[[@as table<string, StaticPlayer[]>]]
for group, players in pairs(groupedPlayers) do
    for i, xPlayer in ipairs(players) do
        print(group, xPlayer.getName())
    end
end

local xPlayers = ESX.ExtendedPlayers() --[=[@as StaticPlayer[]]=]
for i, xPlayer in ipairs(xPlayers) do
    print(xPlayer.getName())
end
```

## GetIdentifier
This function returns the identifier of the specified player. If in Cfx.re Development Kit will return "ESX-DEBUG-LICENSE"

**Arguments**
- playerId: `number`
  - The player's server id.

**Returns**
The identifier of the specified player.

**Example**
```lua
AddEventHandler('esx:onPlayerJoined', function ()
    local identifier = ESX.GetIdentifier(source)
    
    print("Player with the " .. identifier .. " identifier joined.")
end)
```

## GetVehicleType
This function returns the vehicle type of the speicified vehicle.

**Info**
    This function only works when a player is online as one needs to be specified.

**Arguments**
- model: `string` | `number`
  - The vehicle model as string or hash.
- source: `number`
  - The player's server id that should be used to check the model.
- cb: `function?`
  - Optional: The callback function that gets ran when the function finishes.

**Example**
```lua
-- Using cb
ESX.GetVehicleType("t20", 5, function(vehicleType)
    print("Vehicle type " .. vehicleType)
end)

-- Using promise
local vehicleType = ESX.GetVehicleType("t20", 5)
print("Vehicle type " .. vehicleType)
```

## DiscordLog
This function sends a discord log.

**Arguments**
- name: `string`
  - Webhook Name (found in Config.logs.lua)
- title: `string`
  - The title of the message.
- color: `string`
  - The color of the message. (found in Config.logs.lua)
- message: `table`
  - The message to log.

**Example**
```lua
ESX.DiscordLog(
    "UserActions", -- Name Of Webhook
    "User Joined", -- Message Title
    "green", -- Colour
    "A player joined" -- Message
)
```

## DiscordLogFields
This function sends a discord log with fields.

**Arguments**
- name: `string`
  - Webhook Name (found in Config.logs.lua)
- title: `string`
  - The title of the message.
- color: `string`
  - The color of the message. (found in Config.logs.lua)
- fields: `table`
  - The fields to log.

**Example**
```lua
ESX.DiscordLogFields("UserActions", "/car Triggered", "pink", {
    {name = "Player", value = xPlayer.name, inline = true},
    {name = "ID", value = xPlayer.source, inline = true},
    {name = "Vehicle", value = args.car, inline = true}
})
```

## CreateJob
This function creates a new job and inserts it into the database.

**Arguments**
- name: `string`
  - The job's name.
- label: `string`
  - The job's label.
- grades: `table`
  - The job's grades.

**Example**
```lua
ESX.CreateJob("baker", "Baker", {
    {grade = 0, name = "apprentice", label = "Apprentice", salary = 320},
    {grade = 1, name = "employee", label = "Employee", salary = 470},
    {grade = 2, name = "senior", label = "Senior Baker", salary = 610},
    {grade = 3, name = "owner", label = "Owner", salary = 910},
})
```

## RefreshJobs
This function gets all jobs from the database and updates the `ESX.Jobs` table.

**Example**
```lua
-- Function that changed something from the job data in the database.
ESX.RefreshJobs()
```

## AddItems
This function adds new items to ESX.Items and the database. Items already registered will be skipped.

> ⚠️ This function is only available if `Config.CustomInventory` is set to `false`.

**Arguments**
- `items`: `{ name: string, label: string, weight?: number, rare?: boolean, canRemove?: boolean }[]`  
  - An array of item objects to add.
    - `name`: Unique string identifier for the item.
    - `label`: Display name for the item.
    - `weight` (optional): Item weight. Defaults to `1`.
    - `rare` (optional): Whether the item is rare. Defaults to `false`.
    - `canRemove` (optional): Whether the item can be removed. Defaults to `true`.

**Example**
```lua
ESX.AddItems({
  {
    name = 'energy_drink',
    label = 'Energy Drink',
    weight = 1,
    rare = false,
    canRemove = true
  },
  {
    name = 'diamond_ring',
    label = 'Diamond Ring',
    weight = 2,
    rare = true
  }
})
```

## RefreshItems
This function reloads all items from the database into `ESX.Items` and updates the inventories of all online players accordingly.

It ensures that every player's inventory is synchronized with the current state of the item list. Any items that no longer exist in the database will be removed from players' inventories.

> ⚠️ This function is only available if `Config.CustomInventory` is set to `false`.

**Returns**
- `number`: The total number of items reloaded from the database.

**Example**
```lua
-- Reload all items from the database and update inventories
local newItemCount = ESX.RefreshItems()
print(('Reloaded %s items from DB.'):format(newItemCount))
```

## RegisterUsableItem
This function registers a usable item.

**Arguments**
- item: `string`
  - The item to register.
- cb: `function`(playerId: number)
  - The callback function that gets ran when the item is used.

**Example**
```lua
ESX.RegisterUsableItem('bread', function(playerId)
  local xPlayer = ESX.GetPlayerFromId(playerId)
  xPlayer.removeInventoryItem('bread', 1)
  xPlayer.showNotification('That was delicious.. right?')
end)
```

## UseItem
This function forces a player to use a item.

**Arguments**
- source: `number`
  - The player's server id.
- item: `string`
  - The item to use.
- ...?
  - The arguments to pass to the callback function of the item.

**Example**
```lua
ESX.UseItem(5, "bread") -- Force player to eat bread.
```

## RegisterPlayerFunctionOverrides
With this function you can override existing functions in the player object or add new ones.

**Warning**
    Please note, only one override can be active at a time. Ensure no other scripts are using this function simultaneously. This limitation may be lifted in future updates.

**Arguments**
- index: `string`
  - The index of the override.
- overrides: `table`
  - The table with the functions to be overriden with.

**Example**
```lua
local LeoJobs = { "police", "sheriff", "fib" }
local FireJobs = { "ambulance", "doctor", "firefighter" }
ESX.RegisterPlayerFunctionOverrides("myOverrides", {
    isLeo = function(self)
        return table.contains(LeoJobs, self.job.name)
    end,
    isMedic = function(self)
        return table.contains(FireJobs, self.job.name)
    end
})
```

## SetPlayerFunctionOverride
This function switches the function overrides.

**Warning**
    Please note, only one override can be active at a time. Ensure no other scripts are using this function simultaneously. This limitation may be lifted in future updates.

**Arguments**
- index: `string`
  - The index of the override.

**Example**
```lua
ESX.SetPlayerFunctionOverride("myOverrides")
```

## GetItemLabel
This function returns the item label of the given item.

**Arguments**
- item: `string`
  - The item to get the label from.

**Returns**
- label: `string`
  - The item label of the given item.

**Example**
```lua
local jetonLabel = ESX.GetItemLabel("jeton")

print("The play chips of the casino are called "..jetonLabel)
```

## GetJobs
This function returns all registered jobs.

**Returns**

A table of all the registered jobs.
- name: `string`
  - The job's name.
- label: `string`
  - The job's label.
- grades: `table`
  - The job's grades.

Grades:
- grade: `number`
  - The grade index.
- name: `string`
  - The grade's name.
- label: `string`
  - The grade's label.
- salary: `number`
  - The grade's salary.


**Example**
```lua
local jobs = ESX.GetJobs()

for jobName, jobData in pairs(jobs) do
    print(jobName .. " found with grade 0 called: " .. jobData.grades["0"].label)
end
```

## GetUsableItems
This function returns all usable items.

**Returns**

Returns a table with the key being the item and the value being a boolean if the item is usable.

**Example**
```lua
local usableItems = ESX.GetUsableItems()

for item, usable in pairs(usableItems) do
    if usable then
        print("Item " .. item .. " is usable")
    else
        print("Item " .. item .. " is not usable")
    end
end
```

## GetItems
This function returns all items.

**Returns**

Returns a table with all items.

**Example**
```lua
local items = ESX.GetItems()

for item, data in pairs(items) do
    print("Item " .. item .. " has a weight of " .. data.weight)
end
```

## CreatePickup
This function creates a pickup.

**Caution**
  This function does **not** exist with a 3rd party inventory installed.

**Arguments**
- itemType: `string`
  - The type of the item. Valid inputs: "item_standard", "item_money", "item_account", "item_weapon"
- name: `string`
  - The name of either the item, account or weapon.
- count: `number`
  - The amount of the item, account or weapon ammo.
- label: `string`
  - The label of the pickup.
- playerId: `number`
  - The player's server that created the pickup, used to determine pickup spawn point.
- components?: `table`
  - Only used when itemType is "item_weapon". An index-value table with the weapon components.
- tintIndex?: `number`
  - Only used when itemType is "item_weapon". The tint index of the weapon.

**Example**
```lua
ESX.CreatePickup("item_standard", "bread", 5, "Bread", 10)
-- Created item pickup with 5 bread at the position of player 10
end
```

## DoesJobExist
This function returns if the specified job and grade exist.

**Arguments**
- job: `string`
  - The job to check.
- grade: `number`
  - The grade to check.

**Returns**
- exists: `boolean`
  - Does the job and grade exist.


**Example**
```lua
local xPlayer = ESX.GetPlayerFromId(source)
local Job = 'police'
local Grade = 4 -- highest police grade

if ESX.DoesJobExist(Job, Grade) then -- make sure the Job and Grade are both defined in the database
  xPlayer.setJob(Job, Grade)
end
```

## TriggerClientEvent
Triggers an event for one or more clients.

**Arguments**
- eventName: `string`
  - The name of the event to trigger.
- playerIds: `Array|number`
  - If a number, represents a single player ID. If a table, represents an array of player IDs.
- ...: `any`
  - Additional arguments to pass to the event handler. These arguments will be packed and sent to the client.

**Example**
```lua
local jobPlayerIds = { 10, 15, 12, 5 }
local notifyTitle = "New Job Notification"
local notifyMessage = "Hello, World!"

-- Triggers 'resource:client:showJobNotification' for all players in the jobPlayerIds array.
ESX.TriggerClientEvent("resource:client:showJobNotification", jobPlayerIds, notifyTitle, notifyMessage) 
```
