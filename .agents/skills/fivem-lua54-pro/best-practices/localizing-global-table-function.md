# Localizing Global/Table Function

This practice improves performance by reducing table lookups and can make code more readable.

**Remember: To do alias just table lookups not FiveM Native like PlayerPedId(), and except Citizen.Method liek Citizen.CreateThread**

## Good
```lua
local info = lib.print.info
local warning = lib.print.warning
local error = lib.print.error

info('Hello World')
warning('Hello World')
error('Hello World')
```

## Bad
```lua
lib.print.info('Hello World')
lib.print.warning('Hello World')
lib.print.error('Hello World')
```