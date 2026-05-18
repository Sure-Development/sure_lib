# Single

Returns all selected columns for a single row.

## Promise

```lua
local row = MySQL.single.await('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ? LIMIT 1', {
    identifier
})

if not row then return end

print(row.firstname, row.lastname)
```

**Aliases**

- `exports.oxmysql.single_async`

## Callback

```lua
MySQL.single('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ? LIMIT 1', {
    identifier
}, function(row)
    if not row then return end

    print(row.firstname, row.lastname)
end)
```

**Aliases**

- `exports.oxmysql.single`