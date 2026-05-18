---
name: fivem-lua54-pro
description: Expert guidance for FiveM resource development with Lua 5.4. Use when writing, reviewing, refactoring, optimizing, or debugging FiveM client/server/shared scripts, fxmanifest structure, ox_lib integration, oxmysql queries, strict EmmyLua type annotations, performance-sensitive loops, state bags, callbacks, commands, zones, cache usage, and maintainable modular resource architecture.
---

# fivem-lua54-pro

Build high-quality FiveM resources with Lua 5.4, modular architecture, strict EmmyLua annotations, ox_lib/oxmysql patterns, and performance-aware client/server boundaries.

**Important:** Use 2 spaces for indentation and prefer single quotes for Lua strings.

## Core Workflow

1. Identify the execution side first: `client`, `server`, `shared`, `config/public`, or `config/secret`.
2. Keep `fxmanifest.lua` minimal and load code through side-specific `init.lua` files whenever practical.
3. Read only the reference files needed for the requested feature. Use the indexes below to select targeted examples instead of loading every bundled file.
4. Add or preserve EmmyLua annotations for public functions, exported modules, callbacks, config objects, and non-trivial tables.
5. Prefer ox_lib primitives for callbacks, cache values, zones, points, commands, keybinds, timers, streaming, and common utilities.
6. Prefer oxmysql prepared/query helpers for database work and keep SQL/config that contains secrets server-only.
7. Validate performance-sensitive code by checking loop frequency, native call placement, distance checks, cache usage, and server/client data flow.

## Project Structure

Use a strict, modular folder structure to keep code readable and data access explicit. [recommended-folder-structure](examples/recommended-folder-strcuture/)

```text
.
├── fxmanifest.lua
├── server/
│   ├── init.lua          # Main server-side entry point
│   └── modules/          # Server-only logic and authority
├── client/
│   ├── init.lua          # Main client-side entry point
│   └── modules/          # Client-only gameplay/UI logic
├── shared/
│   └── [FILE/FOLDER]     # Shared code or data between client and server
└── config/
    ├── public/           # General configurations accessible by the client
    └── secret/           # Sensitive configurations such as API keys and SQL
```

## Coding Standards

- **Code logic:** Use `camelCase` for variables and functions, for example `local playerData` and `getVehiclePlate()`.
- **Configuration:** Use `camelCase` for config keys, for example `Config.spawnLocation` and `Config.enableDebug`.
- **Modules:** Use `init.lua` as the side-specific loader and require modules in the required execution order.
- **Events/callbacks:** Validate input at boundaries and keep trust-sensitive logic on the server.
- **Exports:** Document exported functions with EmmyLua `---@param` and `---@return`.
- **Comments:** Add comments only for non-obvious behavior, ownership boundaries, or performance-sensitive decisions.

## Strict Type Documentation

Do not leave complex data as untyped tables. Define clear classes, aliases, and function signatures so IntelliSense and review can catch mistakes early.

```lua
---@class VehicleInfo
---@field model string The model name of the vehicle
---@field plate string The vehicle's license plate
---@field fuel number The fuel level from 0 to 100

---@param playerSource number
---@return VehicleInfo
local function getDetailedVehicleInfo(playerSource)
  -- Implementation
end
```

## Performance Rules

- Localize frequently used globals and table functions in hot paths. See [localizing global/table functions](./best-practices/localizing-global-table-function.md).
- Avoid native calls inside tight loops. Cache values before loops when possible.
- Prefer squared-distance checks or ox_lib point/zone helpers over repeated heavy scans.
- Use `cache.ped`, `cache.vehicle`, `cache.serverId`, and related ox_lib cache values instead of polling natives repeatedly.
- Use state bags for replicated state that multiple clients need, but avoid noisy high-frequency state updates.
- Keep database calls server-side and avoid blocking gameplay loops on SQL round trips.
- Use `Wait` intervals intentionally; do not run `Wait(0)` loops unless frame-level work is required.
- Prefered `point` and `require` from **ox_lib** instead of **ESX**

## Reference Selection

Use bundled references only when they are relevant to the current request:

- For ox_lib APIs, open the [ox_lib manual index](./manual-docs/ox_lib/references.md), then read only the matching feature file such as callbacks, cache, zones, points, commands, keybinds, timers, or game helpers.
- For oxmysql APIs, open the [oxmysql manual index](./manual-docs/oxmysql/references.md), then read only the needed query method such as `query`, `single`, `scalar`, `insert`, `update`, `prepare`, `rawExecute`, or `transaction`.
- For ESX core APIs, open the [ESX core manual index](./manual-docs/esx_core/references.md), then read only the matching resource or `es_extended` feature file.
- For local performance style, open [localizing global/table functions](./best-practices/localizing-global-table-function.md).

## ox_lib Guidance

- Use `lib.callback` / `lib.callback.await` for request/response communication instead of custom event pairs.
- Use `lib.callback.register` on the side that owns the data or authority.
- Use `cache` values for common player/ped/vehicle/server identity access.
- Use `lib.zones`, `lib.points`, and game helper functions for spatial logic instead of ad hoc polling where practical.
- Use `lib.addCommand` and `lib.addKeybind` for consistent command and input behavior.
- Use `lib.requestModel`, animation dictionary helpers, and related streaming utilities before creating or using streamed assets.

## oxmysql Guidance

- Use `MySQL.query` for result sets, `single` for one row, `scalar` for one value, `insert` for insert IDs, and `update` for affected rows.
- Use `prepare` or parameterized query arguments for repeated SQL and untrusted values.
- Use `transaction` when multiple writes must succeed or fail together.
- Keep SQL that exposes sensitive table structure or secrets in `server/` or `config/secret/`.
- Return normalized typed objects from database access modules instead of leaking raw row shapes through the codebase.

## esx_core Guidance

When you need to work with es_extended please don't import file in shared_script but use

```lua
local ESX = exports.es_extended:getSharedObject()
```

for performance because `@es_extended/imports.lua` has to create a same event in resource that import this file it will slow down client-side

## Technical References

- [FiveM Native Reference](https://docs.fivem.net/natives/)
- [FiveM Documentation](https://docs.fivem.net/)
- [ox_lib Documentation](https://overextended.dev/ox_lib)
- [oxmysql Documentation](https://overextended.dev/oxmysql)

## Bundled Manuals

- [Best practice: localizing global/table functions](./best-practices/localizing-global-table-function.md)
- [ESX core manual index](./manual-docs/esx_core/references.md)
- [ox_lib manual index](./manual-docs/ox_lib/references.md)
- [oxmysql manual index](./manual-docs/oxmysql/references.md)

## Libraries

- [LibDeflate.lua](https://safeteewow.github.io/LibDeflate/source/LibDeflate.lua.html) - Compression library
