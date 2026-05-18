# Update

Returns the number of rows affected by the query.

## Promise

```lua
local affectedRows = MySQL.update.await('UPDATE users SET firstname = ? WHERE identifier = ?', {
    newName, identifier
})

print(affectedRows)
```

**Aliases**

- `MySQL.Sync.execute`
- `exports.ghmattimysql.executeSync`
- `exports.oxmysql.update_async`

## Callback

```lua
MySQL.update('UPDATE users SET firstname = ? WHERE identifier = ?', {
    newName, identifier
}, function(affectedRows)
    print(affectedRows)
end)
```

**Aliases**

- `MySQL.Async.execute`
- `exports.ghmattimysql.execute`
- `exports.oxmysql.update`