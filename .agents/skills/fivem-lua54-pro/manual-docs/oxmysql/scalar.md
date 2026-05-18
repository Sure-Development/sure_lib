# Scalar

Returns the first column for a single row.

## Promise

```lua
local firstName = MySQL.scalar.await('SELECT `firstname` FROM `users` WHERE `identifier` = ? LIMIT 1', {
    identifier
})

print(firstName)
```

**Aliases**

- `MySQL.Sync.fetchScalar`
- `exports.ghmattimysql.scalar`
- `exports.oxmysql.scalar_async`

## Callback

```lua
MySQL.scalar('SELECT `firstname` FROM `users` WHERE `identifier` = ? LIMIT 1', {
    identifier
}, function(firstName)
    print(firstName)
end)
```

**Aliases**

- `MySQL.Async.fetchScalar`
- `exports.ghmattimysql.scalar`
- `exports.oxmysql.scalar`