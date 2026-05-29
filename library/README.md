# sure_lib LLS types

Drop-in type annotations for the [Lua Language Server](https://luals.github.io/).

## Wire it up

In your consuming resource, create or extend `.luarc.json`:

```json
{
  "runtime.version": "Lua 5.4",
  "workspace.library": [
    "../sure_lib/library"
  ],
  "diagnostics.globals": [
    "sure",
    "lib",
    "cache",
    "exports"
  ]
}
```

After reloading the language server you should get autocomplete on:

- `sure.getModule(<name>)` — narrowed by `SURELIB.MODULE_NAME`
- All module APIs (`SureHook`, `SureDb`, `SureValidator`, …)
- Player shortcut `sure.player.*` (client side)

You can also annotate locals when `getModule` cannot infer:

```lua
---@type SureDb
local db = sure.getModule('db')
```
