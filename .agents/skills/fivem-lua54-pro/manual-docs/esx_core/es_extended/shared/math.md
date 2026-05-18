## Math

### Round
This function rounds the number to the specified amount of decimal places.

**Arguments**
- number: `number`
  - The number to round.
- numDecimalPlaces: `number`
  - The amount of decimal places to round to.

**Example**
```lua
local value - 5.444

print('value: ' .. value) -- returns 5.444
print('value rounded: ' .. ESX.Math.Round(value)) -- returns 5
print('value rounded: ' .. ESX.Math.Round(value, 1)) -- returns 5.4
```

### GroupDigits
This function groups numbers, making them easier to understand by humans. Used in most nofications when money is showed, for example when buying a new car at the vehicle shop.

**Arguments**
- number: `number`
  - The number to group.

**Example**
```lua
local value = 5555
local valueGrouped = ESX.Math.GroupDigits(5555)

print(value, valueGrouped) -- returns 5555, 5,555
```

### Trim
This function trims a string, removing all trailing whitespaces. Often used when sanitizing the `GetVehicleNumberPlateText()` native.

**Arguments**
- value: `string`
  - The string to trim.

**Example**
```lua
local vehicle = GetVehiclePedIsIn(ESX.PlayerData.ped, false) -- gets the vehicle the Player is in

local licencePlate = GetVehicleNumberPlateText(vehicle) -- returns the Vehicles Licence Plate

print(licencePlate) -- prints "ESX 123"

local trimmedPlate = ESX.Math.Trim(licencePlate)

print(trimmedPlate) -- prints "ESX123"
```

### GetHeadingFromCoords
This function calculates the heading (angle) between two 3D coordinates in the XY plane.

**Arguments**
- origin: `vector`
  - The starting point (origin) in 3D space.
- target: `vector`
  - The target point in 3D space.

**Returns**
- `number`
  - The heading in degrees, ranging from 0 to 360.

**Example**
```lua
local origin = vector2(100, 200)
local target = vector2(150, 250)

local heading = ESX.Math.GetHeadingFromCoords(origin, target)

print(heading) -- prints the heading in degrees, e.g., 315.0
```
