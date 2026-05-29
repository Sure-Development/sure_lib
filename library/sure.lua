---@meta sure_lib
---
--- Language Server type stubs for sure_lib.
---
--- Drop this file into your resource by adding it to `.luarc.json`:
---
---     {
---       "workspace.library": [
---         "../sure_lib/library"
---       ]
---     }
---
--- After that, `sure`, `sure.getModule(...)` and module returns are typed.

---@alias SURELIB.MODULE_NAME
---| 'esx'
---| 'player'
---| 'cooldown'
---| 'validator'
---| 'track'
---| 'hook'
---| 'spawn'
---| 'config'
---| 'db'
---| 'lui'
---| 'log'
---| 'keybind'
---| 'slice'

---@class SureLib
---@field player SurePlayer client-side: auto-loaded after init
sure = {}

---@generic T
---@param name SURELIB.MODULE_NAME
---@return T?
function sure.getModule(name) end

---@class SureValidatorRule
---@field type string
---@field parse fun(data: any): boolean
---@field required fun(message: string?): SureValidatorRule
---@field message fun(message: string?): SureValidatorRule
---@field min fun(value: number): SureValidatorRule
---@field max fun(value: number): SureValidatorRule
---@field between fun(min: number, max: number): SureValidatorRule
---@field oneOf fun(values: any[]): SureValidatorRule

---@class SureValidator
---@field object fun(fields: table<string, SureValidatorRule>): SureValidatorRule
---@field array fun(itemRule: SureValidatorRule): SureValidatorRule
---@field string fun(): SureValidatorRule
---@field number fun(): SureValidatorRule
---@field integer fun(): SureValidatorRule
---@field boolean fun(): SureValidatorRule
---@field callback fun(): SureValidatorRule

---@class SureHookContext
---@field name string event name being dispatched
---@field args any[] mutable list of arguments forwarded to the handler

---@alias SureHookMiddleware fun(ctx: SureHookContext, next: fun(): any): any

---@class SureHookHandle
---@field expect fun(self: SureHookHandle, ...: SureValidatorRule): SureHookHandle
---@field use fun(self: SureHookHandle, middleware: SureHookMiddleware): SureHookHandle

---@class SureHookInjectionContext
---@field name string hook name being dispatched on the target resource
---@field args any[] mutable arguments forwarded to the target's handler
---@field cancelled boolean set to true to short-circuit and skip the handler

---@alias SureHookInjection fun(ctx: SureHookInjectionContext): any

---@class SureHook
---@field use fun(self: SureHook, middleware: SureHookMiddleware): SureHook
---@field on fun(self: SureHook, name: string, callback: fun(...)): SureHookHandle
---@field onNet fun(self: SureHook, name: string, callback: fun(...)): SureHookHandle
---@field dispatch fun(self: SureHook, name: string, ...: any)
---@field dispatchClient fun(self: SureHook, target: integer|string, name: string, ...: any)
---@field dispatchServer fun(self: SureHook, name: string, ...: any)
---@field injectResource fun(self: SureHook, targetResource: string, hookName: string, middleware: SureHookInjection): SureHook

---@class SureLogger
---@field debug fun(self: SureLogger, message: any)
---@field info fun(self: SureLogger, message: any)
---@field warn fun(self: SureLogger, message: any)
---@field error fun(self: SureLogger, message: any)

---@class SureLog
---@field debug fun(message: any)
---@field info fun(message: any)
---@field warn fun(message: any)
---@field error fun(message: any)
---@field create fun(tag: string): SureLogger
---@field setLevel fun(level: 'debug'|'info'|'warn'|'error')

---@class SureKeybindSpec
---@field name string
---@field description string
---@field defaultKey string?
---@field defaultMapper string?
---@field secondaryKey string?
---@field secondaryMapper string?
---@field onPressed fun(self: any)?
---@field onReleased fun(self: any)?

---@class SureKeybind
---@field register fun(spec: SureKeybindSpec): any
---@field get fun(name: string): any?
---@field disable fun(name: string)
---@field enable fun(name: string)

---@class SureTrackGetter
---@field isReactive boolean
---@field stateName string

---@class SureTrack
---@field state fun(name: string, initial: any): SureTrackGetter, fun(newValue: any|fun(current: any): any)
---@field effect fun(callback: fun(), dependencies: SureTrackGetter[]): fun()  --- returns dispose
---@field computed fun(name: string, compute: fun(): any, dependencies: SureTrackGetter[]): SureTrackGetter

---@class SureCooldownDefinition
---@field initialDurationMs integer
---@field durationMs integer
---@field pauseTimerOn integer?
---@field resetAfterZeroTicks integer?

---@class SureCooldown
---@field define fun(key: string, definition: SureCooldownDefinition)
---@field start fun(key: string, position: vector3, durationMs: integer?)
---@field getRemaining fun(key: string, position: vector3): integer?
---@field startById fun(key: string, identifier: string|integer, durationMs: integer?)
---@field getRemainingById fun(key: string, identifier: string|integer): integer?
---@field all fun(): table

---@class SurePlayer
---@field loaded boolean
---@field ped integer
---@field health integer
---@field armor integer
---@field coords vector3
---@field vehicle integer?
---@field serverId integer
---@field data table
---@field inventory table
---@field accounts table
---@field loadout table
---@field waitUntilLoaded fun()
---@field currentVehicleProperties table?

---@class SureDbField
---@field type 'integer'|'bigint'|'float'|'double'|'string'|'text'|'boolean'|'timestamp'|'json'
---@field length integer?
---@field nullable boolean?
---@field default any?
---@field primaryKey boolean?
---@field autoIncrement boolean?
---@field unique boolean?

---@class SureDbOrderBy
---@field [1] string column name
---@field [2] 'asc'|'desc'?

---@class SureDbQueryOptions
---@field where table?
---@field data table?
---@field update table?
---@field select string[]?
---@field orderBy (string|SureDbOrderBy)[]?
---@field limit integer?
---@field offset integer?

---@class SureDbModel
---@field name string
---@field tableName string
---@field findMany fun(self: SureDbModel, query: SureDbQueryOptions?): table[]
---@field findFirst fun(self: SureDbModel, query: SureDbQueryOptions?): table?
---@field count fun(self: SureDbModel, query: SureDbQueryOptions?): integer
---@field create fun(self: SureDbModel, query: SureDbQueryOptions): integer?
---@field bulkInsert fun(self: SureDbModel, query: SureDbQueryOptions): integer?
---@field upsert fun(self: SureDbModel, query: SureDbQueryOptions): integer?
---@field update fun(self: SureDbModel, query: SureDbQueryOptions): integer?
---@field delete fun(self: SureDbModel, query: SureDbQueryOptions): integer?
---@field raw fun(self: SureDbModel, sql: string, params: any[]?): any

---@class SureSliceInstance
---@field name string
---@field state table
---@field actions table<string, fun(...): any>
---@field log SureLogger
---@field subscribe fun(self: SureSliceInstance, key: string, handler: fun(value: any, previous: any)): SureSliceInstance
---@field snapshot fun(self: SureSliceInstance): table
---@field emit fun(self: SureSliceInstance, eventName: string, ...: any): SureSliceInstance
---@field emitClient fun(self: SureSliceInstance, target: integer|string, eventName: string, ...: any): SureSliceInstance
---@field emitServer fun(self: SureSliceInstance, eventName: string, ...: any): SureSliceInstance
---@field ref fun(self: SureSliceInstance, stateKey: string, handler: SureSliceRefHandler): fun()

---@alias SureSliceRefCleanup fun()
---@alias SureSliceRefHandler fun(item: table, index: integer): SureSliceRefCleanup?

---@class SureSliceSpec
---@field state table?
---@field actions table<string, function>?
---@field on table<string, function>?
---@field net table<string, function>?
---@field watch table<string, function>?
---@field commands table<string, function>?
---@field onLoad function?
---@field onUnload function?

--- Create a slice. Extend `SureSliceInstance` with a typed `state` field
--- to drive autocomplete on every handler:
---
---     ---@class FarmingState
---     ---@field entities { key: string, model: string, coords: vector3 }[]
---
---     ---@class FarmingSlice : SureSliceInstance
---     ---@field state FarmingState
---
---     local slice = sure.getModule('slice') --[[@as SureSlice]]
---
---     slice 'farming' {
---       state = { entities = {} },
---       actions = {
---         ---@param s FarmingSlice
---         addEntity = function(s, item)
---           s.state.entities[#s.state.entities + 1] = item
---         end,
---       },
---       ---@param s FarmingSlice
---       onLoad = function(s)
---         s:ref('entities', function(item) end)
---       end,
---     }
---
---@alias SureSlice fun(name: string): fun(spec: SureSliceSpec): SureSliceInstance

---@class SureDb
---@field schema fun(self: SureDb, name: string, definition: table): SureDbModel
---@field transaction fun(self: SureDb, queries: { query: string, values: any[]? }[]): boolean
