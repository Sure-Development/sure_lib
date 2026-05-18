# Functions 
This topic includes most functions that are existing in ESX. 

## IsPlayerLoaded 
This function will return a `bool` if the player has sucessfully loaded.
This should be checked before manipulating or checking data of the player.

**Example** 
```lua
while not ESX.IsPlayerLoaded() do 
    Wait(250) 
end 

print('player is loaded') 
```

## GetPlayerData
This function simply returns [ESX.PlayerData](../playerdata.md).

**Example**
```lua
local playerData = ESX.GetPlayerData()

print("The client's identifier: " .. playerData.identifier)
```

## SecureNetEvent
This function will register a client net event that can only be triggered by the server side.
Useful for ensuring clients (like cheaters) are not triggering it.

**Arguments**
- name: `string`
  - The name of the net event.
- func: `function`
  - The function that will be executed when the net event is triggered.

**Example**
```lua
ESX.SecureNetEvent("esx:requestModel", function(model)
    ESX.Streaming.RequestModel(model)
end)
```

## DisableSpawnManager
This function will disable the spawnmanager resource provided by FiveM.

**Example**
```lua
ESX.DisableSpawnManager()
```

## SearchInventory 
Can be used to check for items in the player's Inventory

**Arguments** 
- items: `string` or table
  - A string or table containing the items.

**Example**
```lua
local items = ESX.SearchInventory({'bread', 'water'}, true) 

for key, value in pairs(items) do 
    print(string.format(('You have %sx %s'), value, key)) 
end 

local item = ESX.SearchInventory('bread') 
local count = item.count
```

**Output** 
- usable: `boolean`
  - If the item is usable or not.
- count: `number`
  - How many of the item is found.
- canRemove: `number`
  - This returns 1 when it can be removed otherwise 0
- label: `string`
  - The item label that is shown in the inventory.
- name: `string`
  - The name of the item
- rare: `number`
  - Is the item rare?

## SetPlayerData
This function you can set playerdata with.

**Arguments** 
- key: `string`
  - The key of the playerdata.
- value: `value`
  - The data to be set.

**Example** 
```lua
ESX.SetPlayerData('test', 'a nice test')
 
print(ESX.PlayerData.test) -- this will print 'a nice test'
```

## SpawnPlayer
This function will spawn the player at the given coords and set the given skin.

## Progressbar 
ESX has a progress bar system by default as a seperate resource. See more at [esx_progressbar](../../esx_progressbar.md).

## Context
ESX has a context system by default as a seperate resource. See more at [esx_context](../../esx_context.md).

## ShowNotification 
ESX has a custom notification system as a seperate resource. See more at [esx_notify](../../esx_notify.md).

## TextUI 
ESX has a Text UI system by default as a seperate resource. See more at [esx_textui](../../esx_textui.md).

## ShowAdvancedNotification
This function will show a default GTA 5 notification 

**Arguments** 
- sender: `string`
  - The notification title.
- subject: `string`
  - The notification subtitle
- msg: `string`
  - The notification message
- textureDict: `string`
  - The texture dictionary for the icon
- iconType: `string`
  - The icon type, see the list below.
- flash?: `boolean` (Default: `false`)
  - According to the fivem natives, this var never works no matter what.
- saveToBrief?: `boolean` (Default: `false`)
  - Makes the notification appear in the "Pause Menu > Info/Brief > Notifications" section.
- hudColorIndex?: `number`
  - The background color for the notification.

**Icon types**
1. Chat Box  
2. Email  
3. Add Friend Request  
4. Nothing  
5. Nothing  
6. Nothing  
7. Right Jumping Arrow  
8. RP Icon  
9. $ Icon 

**[Hud color indexes](https://docs.fivem.net/docs/game-references/hud-colors/)**

**Example** 
```lua
local handle = RegisterPedheadshot(PlayerPedId())
while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
    Wait(0)
end
local txd = GetPedheadshotTxdString(handle)
local title = GetPlayerName(PlayerId())
local subtitle = 'Private Message'
local iconType = 0
ESX.ShowAdvancedNotification(title, subtitle, 'this is the message that we send to you', txd, iconType, false, true, 6)
```

## ShowHelpNotification
This function shows a help notification on the top left of the screen. 
Either needs to be ran every frame or a duration can be optionally set.

**Arguments**
- msg: `string`
  - The message content.
- thisFrame?: `boolean` (Default: `false`)
  - Should it only be displayed this frame.
- beep?: `boolean` (Default: `false`)
  - Should it play a beep sound?
- duration?: `number` (Default: `-1`)
  - The duration of how long this should show. 

**Example** 
```lua
RegisterCommand('help', function (source, args, raw)
    ESX.ShowHelpNotification("We won't give you help, we are truly not sorry.", false, true, 3500)
end)
```

## ShowFloatingHelpNotification 
This function shows a floating help notification, this is needs to be ran every millisecond.

**Arguments**
- msg: `string`
  - The floating message.
- coords: `vector3`
  - The coords of where it should be displayed 

**Example** 
```lua
local coords = vector3(0, 0, 0) 

CreateThread(function() 
    while true do
        ESX.ShowFloatingHelpNotification('ESX is so cool', coords) 
        Wait(0) 
    end 
end)
```

## DrawMissionText
This function will draw a Rockstar style mission text.

**Arguments**
- msg: `string`
  - The message that should be displayed.
- time: `number`
  - The time the message should be displayed.

**Example**
```lua
ESX.DrawMissionText('This is a mission text that is shown for 5 seconds', 5000)
```

## HashString
Wrongly named function but this function will return you the input hash/mapping of a command. Giving you the ability to display it inside of a [`ShowHelpNotification`](#showhelpnotification)

**Arguments**
- str: `string`
  - The string that should be hashed.

**Example** 
```lua
RegisterCommand('howtosit', function (source, args, raw)
    local inputMapping = ESX.HashString("sit")
    ESX.ShowHelpNotification("You can sit down using "..inputMapping , false, true, 3500)
end)
```

## RegisterInput 
This functions registers an input.

**Arguments** 
- command_name: `string`
  - The name of the command that should be executed.
- label: `string`
  - The label of the keybind.
- input_group: `string`
  - The input group.
- key: `string`
  - The key used for the keybind.
- on_press: `function`
  - The function that will be executed when pressing the key.
- on_release?: `function`
  - The function that will be executed when releasing the key.

**[Input Groups](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/)** 

**Example** 
```lua
ESX.RegisterInput('testinput', 'Test', 'keyboard', 'f6', function()
    print('pressed')
end, function() 
    print('released')
end)  
```

## GetAccount
Returns the player's specified account

**Arguments**
- account: `string`
  - The account name.

**Example**
```lua
local account = ESX.GetAccount('money')

print("The client has " .. account.money .. ' currently in his purse!')
```

## ShowInventory
Opens the player's inventory. (Default es_extended inventory)

## GetVehicleTypeClient
Returns the vehicle type of the given model.

**Arguments**


**Returns**
- vehicleType: `string`
  - The type of the vehicle.

**Vehicle Types**
- automobile
- bike
- trailer
- bike
- boat
- heli
- plane
- train
