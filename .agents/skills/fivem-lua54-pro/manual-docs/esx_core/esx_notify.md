# esx_notify
The notification system used by `es_extended`

**Arguments**
- message: `string`
- The notification message
- type: `string`
- The notification type
- length: `number`
- The notification length
- title: `string?`
- The notification title (optional)
- position: `string?`
- Teh notification position (optional)

**Notification Types**
- success
- error
- info
- warning

**Notification positions**
- top-right
- top-left
- top-middle
- bottom-right
- bottom-left
- bottom-middle
- middle-left
- middle-right (Default)

## Client Triggers

### ESX Function

**Example**
```lua
ESX.ShowNotification("message here", "success", 3000, "title here", "top-left")
```

### Export

**Example**
```lua
exports['esx_notify']:Notify('error', 'This is my new test.',  1500, "Test Notification", "top-left") 
```

## Server Triggers

**Example**
```lua
TriggerClientEvent("esx:showNotification", playerId, "This is my new test.", "error", 1500, "Test Notification", "top-left")
```
```
