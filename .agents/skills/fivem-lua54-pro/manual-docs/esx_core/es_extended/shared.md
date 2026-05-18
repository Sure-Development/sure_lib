# Shared Functions
Functions that can be used on both server and client.

## GetRandomString
This function returns a random string in the specified length.

**Arguments**
- length: `number`
  - The length of the string to be generated.

**Example**
```lua
local randomName = ESX.GetRandomString(5)
print("Pomni's name could have been: " .. randomName)
```

## IsFunctionReference
This function validates if the inputted value is a function reference, useful for ensuring users do not pass in unexpected values

**Arguments**
- val: `any`
  - the varaiable to validate

**Example**
```lua
if not ESX.IsFunctionReference(conditionFunc) then
  error("Condition Function should be a function reference.")
end
```

## GetConfig
This function returns the esx config or a specific config value.

**Arguments**
- key: `string?`
  - Optional: The config key.

**Example**
```lua
-- Getting whole config:
local config = ESX.GetConfig()

-- Checking if EnableDebug is enabled
local debugEnabled = ESX.GetConfig("EnableDebug")
```

## GetWeapon
Get the weapon from the weapons config and it's index in it using the weapon name.

**Arguments**
- weaponName: `string`
  - The name of the weapon to get.

**Returns**
- index: `number`
  - The index of the weapon in the weapons config.
- weapon: `table`
  - The weapon data from the weapons config.

**Example**
```lua
local index, weapon = ESX.GetWeapon("weapon_pistol")

print("The weapon is called " .. weapon.label .. " and can have a max of " .. weapon.ammo .. " bullets.")
```

## GetWeaponFromHash
Get the weapon from the weapons config and it's index using the weapon's hash.

**Arguments**
- weaponHash: `number`
  - The hash of the weapon to get.

**Returns**
- index: `number`
  - The index of the weapon in the weapons config.
- weapon: `table`
  - The weapon data from the weapons config.

**Example**
```lua
local index, weapon = ESX.GetWeaponFromhash(joaat("weapon_pistol"))

print("The weapon is called " .. weapon.label .. " and can have a max of " .. weapon.ammo .. " bullets.")
```

## GetWeaponList
Get all weapons either with the name or hash as key.

**Arguments**
- byHash: `boolean`
  - Should it return the weapon hashes instead of the key.

## GetWeaponLabel
Get the specified weapon's label

**Arguments**
- weaponName: `string`
  - The name of the weapon to get the label of.

**Returns**
- label: `string`
  - The label of the weapon.

**Example**
```lua
local label = ESX.GetWeaponLabel("weapon_pistol")

print("Weapon is a: " .. weaponLabel)
```

## GetWeaponComponent
This function returns the possible data of the specified component for the specified weapon.

**Arguments**
- weaponName: `string`
  - The name of the weapon to get the component data for.
- componentName: `string`
  - The name of the component to get the data for.

**Returns**
- component: `table`
  - The component data from the weapons config.

## Await
This function is a simple wrapper, that allows you to await a condition.

**Warning**
  It is not recommended to rely on this function on the server side.

**Arguments**
- condition: `function`
  - A function that is repeatedly called until it returns a truthy value or the timeout is exceeded.
- errorMessage: `string?`
  - If set, an error will be thrown with this message if the condition is not met within the timeout. If not set, no error will be thrown.
- timeoutMs: `number?`
  - The maximum time to wait (in milliseconds) for the condition to be met. Defaults to 1000ms.

**Returns**
- success: `boolean`
  - Whether the condition was met within the timeout.
- result: `any`
  - The result of the condition function.

**Example**

```lua
local success, result = ESX.Await(function()
  return PlayerPedId() ~= 0
end, "Player ped was not found")
```

## ValidateType  
Validates whether a given value matches any of the expected Lua types.

**Arguments**  
- `value`: any  
  The value to validate.  
- `...types`: string  
  One or more strings representing the Lua types to check against (e.g., `"string"`, `"number"`).

**Returns**  
- `success`: boolean  
  Returns `true` if the value matches one of the given types, otherwise `false`.  
- `errorMessage`: string?  
  An optional error message describing the mismatch, returned only if the validation fails.

**Example**
```lua
local success, err = ESX.ValidateType("hello", "string", "number") -- true
local success, err = ESX.ValidateType(123, "string") -- false, "bad value (string expected, got number)"
```

## IsValidLocaleString  
Checks whether a string contains only valid characters according to the current locale and optional digit allowance.

**Arguments**  
- `str`: string  
  The input string to validate.
- `allowDigits`: boolean?  
  Whether to allow numeric characters (`0-9`) in the string. Optional.

**Returns**  
- `isValid`: boolean  
  Returns `true` if all characters in the string are valid according to the locale and configuration, `false` otherwise.

**Behavior**
- Valid characters always include:  
  - Basic Latin letters (A-Z, a-z), space, dash (`-`), and Latin extended characters.
- Digits (`0-9`) are allowed only if `allowDigits` is `true`.
- Locale-specific ranges are used based on `Config.Locale` (e.g., Greek, Cyrillic, Arabic, Chinese).
- Additional locales can be enabled via `Config.ValidCharacterSets`.

**Example**
```lua
local ok = ESX.IsValidLocaleString("Test-Αθήνα") -- true for Greek locale
local ok = ESX.IsValidLocaleString("123Name", true) -- true if digits are allowed
local ok = ESX.IsValidLocaleString("名字") -- true for zh-cn locale
```
