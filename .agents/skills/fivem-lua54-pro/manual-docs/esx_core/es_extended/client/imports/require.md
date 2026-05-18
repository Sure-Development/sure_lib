# Require

Loads the given module. The function starts by indexing the loaded table to determine whether `modname` is already loaded. If it is, then `require` returns the value stored at `loaded[modname]`.
    - Module names are the path to a file relative to the resource.
    - The module name must point to a `.lua` file.
    - Use `.` to separate directories in a path.
    - Modules can be loaded from external resources using `@resource.modname`.

## Examples

```lua
require '@resource.client.modname'
```

**Warning**
    Client modules must be defined in the `file` section of the resource manifest.
    ```lua
        file 'modname.lua'
        -- or
        files {
        'modname.lua'
        }
    ```

> Credit to [Overextended](https://overextended.dev/ox_lib/Modules/Require/Shared) for the documentation.
