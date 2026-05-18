@RTK.md

## Verification

Run these commands before handing off changes:

```bash
rtk stylua --check .
rtk lua54 tests/run.lua
rtk git diff --check
```

Use `rtk stylua .` to format Lua files before the checks when needed.
