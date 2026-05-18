# Streaming
This model is used to request all kind of streaming related stuff.

## Functions

### RequestModel
Request the model to be used.

**Arguments**
- model: `number`|`string`
  - The model to request.
- cb?: `function`
  - The callback function to be called when the model is loaded.

**Returns**
- modelHash: `number`
  - The model hash.

**Callback Example**
```lua
ESX.Streaming.RequestModel('a_m_y_skater_01', function(model)
    local ped = CreatePed(4, model, 0, 0, 0, 0, false, true)
end)
```

**Return-based Example**
```lua
local model = ESX.Streaming.RequestModel('a_m_y_skater_01')
local ped = CreatePed(4, model, 0, 0, 0, 0, false, true)
```

### RequestStreamedTextureDict
Request the texture dictionary to be used.

**Arguments**
- textureDict: `string`
  - The texture dictionary to request.
- cb?: `function`
  - The callback function to be called when the texture dictionary is loaded.

**Returns**
- textureDict: `string`
  - The texture dictionary.

**Callback Example**
```lua
-- TODO: TEST if actually works (Taken from forum)
ESX.Streaming.RequestStreamedTextureDict('shopui_title_sm_biker', function(textureDict)
    local scaleform = RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')
    BeginScaleformMovieMethod(scaleform, 'SHOW_SHARD_WASTED_MP_MESSAGE')
    ScaleformMovieMethodAddParamTextureNameString(textureDict)
    EndScaleformMovieMethod()
end)
```

**Return-based Example**
```lua
-- TODO: TEST if actually works (Taken from forum)
local textureDict = ESX.Streaming.RequestStreamedTextureDict('shopui_title_sm_biker')
local scaleform = RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')
BeginScaleformMovieMethod(scaleform, 'SHOW_SHARD_WASTED_MP_MESSAGE')
ScaleformMovieMethodAddParamTextureNameString(textureDict)
EndScaleformMovieMethod()
```

### RequestNamedPtfxAsset
Request the named particle effect asset to be used.

**Arguments**
- assetName: `string`
  - The asset name to request.
- cb?: `function`
  - The callback function to be called when the asset is loaded.

**Returns**
- assetName: `string`
  - The asset name.

**Callback Example**
```lua
-- TODO: TEST if actually works (Taken from forum)
ESX.Streaming.RequestNamedPtfxAsset('core')
UseParticleFxAssetNextCall('core')
StartParticleFxLoopedAtCoord('ent_amb_fbi_smoke', 0, 0, 0, 0, 0, 0, 1, false, false, false, false)
```

**Return-based Example**
```lua
-- TODO: TEST if actually works (Taken from forum)
local assetName = ESX.Streaming.RequestNamedPtfxAsset('core')
UseParticleFxAssetNextCall(assetName)
StartParticleFxLoopedAtCoord('ent_amb_fbi_smoke', 0, 0, 0, 0, 0, 0, 1, false, false, false, false)
```

### RequestAnimSet
Request the animation set to be used.

**Arguments**
- animSet: `string`
  - The animation set to request.
- cb?: `function`
  - The callback function to be called when the animation set is loaded.

**Returns**
- animSet: `string`
  - The animation set.

**Callback Example**
```lua
ESX.Streaming.RequestAnimSet('move_m@drunk@verydrunk', function(animSet)
    etPedMovementClipset(PlayerPedId(), animSet, true)
end)
```

**Return-based Example**
```lua
local animSet = ESX.Streaming.RequestAnimSet('move_m@drunk@verydrunk')
SetPedMovementClipset(PlayerPedId(), animSet, true)
```

### RequestAnimDict
Request the animation dictionary to be used.

**Arguments**
- animDict: `string`
  - The animation dictionary to request.
- cb?: `function`
  - The callback function to be called when the animation dictionary is loaded.

**Returns**
- animDict: `string`
  - The animation dictionary.

**Callback Example**
```lua
ESX.Streaming.RequestAnimDict('mini@repair', function(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, 'plant_floor', 8.0, 1.0, 1000, 16, 0.0, false, false, false)
end)
```

**Return-based Example**
```lua
local animDict = ESX.Streaming.RequestAnimDict('weapons@first_person@aim_rng@generic@projectile@sticky_bomb@')
TaskPlayAnim(PlayerPedId(), animDict, 'plant_floor', 8.0, 1.0, 1000, 16, 0.0, false, false, false)
```

### RequestWeaponAsset
Request the weapon asset to be used.

**Arguments**
- weaponHash: `string`
  - The weapon name to request.
- cb?: `function`
  - The callback function to be called when the weapon asset is loaded.

**Returns**
- weaponHash: `string`
  - The weapon name.

**Callback Example**
```lua
ESX.Streaming.RequestWeaponAsset(joaat('WEAPON_PISTOL'), function(weaponHash)
    local coords = GetEntityCoords(PlayerPedId())
    local weaponObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
end)
```

**Return-based Example**
```lua
local weaponHash = ESX.Streaming.RequestWeaponAsset(joaat('WEAPON_PISTOL'))
local coords = GetEntityCoords(PlayerPedId())
local weaponObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
```
