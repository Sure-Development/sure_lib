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

Available modules: `esx`, `player`, `cooldown`, `validator`, `track`, `hook`, `log`, `slice`, `config`, `spawn`, `keybind`, `db`, `lui`.

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

## Slice — declarative feature bundle

`slice` packages state, actions, event handlers, and lifecycle hooks for a feature in one declarative spec. Every name is auto-prefixed with the slice name so events, commands, and logs stay consistent across resources.

```lua
local slice = sure.getModule('slice')

return slice 'duty' {
  state = {
    onDuty = false,
    streak = 0,
  },

  actions = {
    toggle = function(s)
      s.state.onDuty = not s.state.onDuty
    end,
  },

  net = {
    sync = function(s, value)
      s.state.onDuty = value
    end,
  },

  watch = {
    onDuty = function(s, value)
      s.log.info('changed to ' .. tostring(value))
      s:emit('changed', value)
    end,
  },

  commands = {
    print = function(s)
      print(json.encode(s:snapshot()))
    end,
  },

  onLoad = function(s)
    s.log.info('ready')
  end,
}
```

- `state` becomes a reactive proxy; writing triggers `watch` and `subscribe` handlers.
- `actions` are pure mutators exposed as `slice.actions.<name>(...)`.
- `on` / `net` register listeners against `'<sliceName>:<eventName>'`.
- `emit` / `emitClient` / `emitServer` auto-prefix the same way.
- `commands` registers `<sliceName>:<commandName>` console commands.
- `onLoad` / `onUnload` only fire for the current resource.
- `every` spawns a single scheduling thread per slice that fires each interval handler when its window elapses, sleeping only until the next due interval.
- Auto-generates a `setX` action for every state key. Custom actions with the same name take precedence.
- `slice:transaction(fn)` batches mutations so each watcher fires once with the net change.
- `netSync = { stateKey = 'sender' | 'receiver' | { direction, scope, diff } }` mirrors state across server/client. Scopes are managed through `slice:scope(name)` with `add` / `remove` / `list` / `contains` accepting both player ids and ESX identifiers. Setting `diff = true` switches the wire format to a keyed-array patch (`{ added, removed, changed }`) and skips emits that produce an empty patch. Removing a player from a scope emits `{ cleared = true }` to that player for every diff field, which clears the receiver's mirror and lets `ref` cleanup tear down world entities.

### Keyed reactive list with `slice:ref`

`slice:ref(stateKey, fn)` watches an array of items, calls `fn(item, index)` for every new item, and re-runs only when an individual item's content changes (deep equal). Removed items run their cleanup function; unchanged items are left alone. Duplicate `key` values raise an error.

```lua
return slice 'world' {
  state = {
    entities = {
      { key = 'guard-1', entity = 0, coords = vector3(0, 0, 0) },
    },
  },

  onLoad = function(s)
    s:ref('entities', function(item)
      local ped = createGuard(item.coords)

      return function()
        DeleteEntity(ped)
      end
    end)
  end,
}
```

- Each item must expose a `key` field (`string` or `number`).
- Return a function from `fn` to register a cleanup; omit the return for no-op cleanup.
- `ref` returns a `dispose` function that unmounts every active item and stops watching. Every active ref also auto-disposes on `onResourceStop` for the current resource, after `spec.onUnload` runs.
- Array mutation helpers `slice:push(stateKey, item)`, `slice:patch(stateKey, itemKey, partial)`, and `slice:removeBy(stateKey, predicate)` filter + reassign the array so watchers and netSync diffs fire correctly without hand-written loops.
- The watcher fires when the array reference changes — assign a new table to `state.<key>` to trigger reconciliation.

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
