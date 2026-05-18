# sure_lib

Modern-first Lua 5.4 utility library for FiveM resources.

## Features

- ESX client/server helpers
- Shared cooldown state
- Runtime schema validation
- Reactive state tracking
- Validated event listeners

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)

## Loading

Add the shared loader to resources that use this library:

```lua
shared_script '@sure_lib/init.lua'
```

Modules are loaded through `sure.getModule(moduleName)`.

Available modules: `esx`, `player`, `cooldown`, `validator`, `track`, `listener`.

Full documentation will be added separately.
