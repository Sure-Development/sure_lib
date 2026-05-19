@RTK.md

## Verification

Make sure you have updated @README.md if there's any data that readme must changed after codebase.

Run these commands before handing off changes:

```bash
rtk stylua --check .
rtk lua54 tests/run.lua
rtk git diff --check
```

Use `rtk stylua .` to format Lua files before the checks when needed.
