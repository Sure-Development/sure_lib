# Client

## Global variables
All variables available on the client side inside the ESX Object.

### ESX.PlayerData
This is the player data object. See the [Player Data](./playerdata) page for more information.

### ESX.PlayerLoaded
Is the player and his character loaded?

**Example**
```lua
if ESX.PlayerLoaded then
    print('Player is loaded')
end
```

### ESX.playerId
The player's local id, a cached value of `PlayerId()`.

### ESX.serverId
The player's server id, a cached value of `GetPlayerServerId(PlayerId())`.
