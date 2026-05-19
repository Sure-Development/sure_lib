# sure_lib

Modern-first Lua 5.4 utility library for FiveM resources.

## Features

- ESX client/server helpers
- Shared cooldown state
- Runtime schema validation
- Reactive state tracking
- Validated event listeners
- Lua-driven NUI rendering with `lui`, hybrid declarative node trees, motion, shadcn-like components, theme overrides, and runtime utility styles
- Text and Iconify-powered LUI icons through ergonomic Lua props

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)

## Loading

Add the shared loader to resources that use this library:

```lua
shared_script '@sure_lib/init.lua'
```

Modules are loaded through `sure.getModule(moduleName)`.

Available modules: `esx`, `player`, `cooldown`, `validator`, `track`, `listener`, `config`, `spawn`, `db`, `lui`.

For Lua UI, point your resource NUI page at the bundled renderer:

```lua
ui_page 'https://cfx-nui-sure_lib/web/lui/index.html'
```

Enable LUI debug traces with `?luiDebug=1` or `localStorage.setItem('sure:lui:debug', '1')` in NUI Devtools.

`lui` supports both nested callback builders and declarative node factories, so larger interfaces can be split into small Lua component functions.

Documentation: https://docs.sure-developer.com
