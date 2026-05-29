# sure_lib

Modern-first Lua 5.4 utility library for FiveM resources.

## Features

- ESX client/server helpers
- Shared cooldown state — by position **or** by identifier
- Runtime schema validation
- Reactive state tracking (`state`, `effect` with disposers, `computed`)
- Hook pipeline: validated event handlers with composable middleware
- Namespaced logger with configurable levels
- ox_lib keybind wrapper with idempotent registration
- Lua-driven NUI rendering with `lui`, hybrid declarative node trees, motion, shadcn-like components, theme overrides, and runtime utility styles
- Text and Iconify-powered LUI icons through ergonomic Lua props
- Database module with `count`, `select`, `orderBy`, `limit/offset`, `upsert`, `bulkInsert`, `transaction`, and ALTER-aware `db push`
- Console diagnostics via `<resource>:doctor`
- Drop-in Language Server type stubs in `library/`

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/esx_core)

## Loading

Add the shared loader to resources that use this library:

```lua
shared_script '@sure_lib/init.lua'
```

Modules are loaded through `sure.getModule(moduleName)`.

Available modules: `esx`, `player`, `cooldown`, `validator`, `track`, `hook`, `log`, `config`, `spawn`, `keybind`, `db`, `lui`.

> `listener` was renamed to `hook` and now supports a `use(middleware)` pipeline and explicit `dispatch` / `dispatchClient` / `dispatchServer` verbs.

Other resources can inject middleware into a hook through exports:

```lua
-- from another resource that depends on sure_lib
local hook = sure.getModule('hook')

hook:injectResource('resourceWithHook', 'hookName', function(ctx)
  ctx.args[1] = ctx.args[1]:upper() -- mutate
  -- ctx.cancelled = true            -- short-circuit
end)
```

The target resource must be started before `injectResource` runs.

For Lua UI, point your resource NUI page at the bundled renderer:

```lua
ui_page 'https://cfx-nui-sure_lib/web/lui/index.html'
```

Enable LUI debug traces with `?luiDebug=1` or `localStorage.setItem('sure:lui:debug', '1')` in NUI Devtools.

`lui` supports both nested callback builders and declarative node factories, so larger interfaces can be split into small Lua component functions.

## Language Server types

The repo ships LLS stubs in `library/`. Add the folder to your `.luarc.json`:

```json
{
  "runtime.version": "Lua 5.4",
  "workspace.library": ["../sure_lib/library"],
  "diagnostics.globals": ["sure", "lib", "cache", "exports"]
}
```

See `library/README.md` for details.

## Console commands

- `<resource>:db push <schemaName>` — `CREATE TABLE IF NOT EXISTS` or `ALTER TABLE ... ADD COLUMN` for new fields.
- `<resource>:db pull <tableName>` — write a schema file from a live table.
- `sure_lib:doctor` — verifies that `ox_lib`, `es_extended`, `oxmysql`, and the required `lib.*` helpers are reachable.

Documentation: https://docs.sure-developer.com
