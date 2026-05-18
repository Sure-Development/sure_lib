# Insert

Inserts a new entry into the database and returns the insert id for the row, if valid.

## Promise

```lua
local id = MySQL.insert.await('INSERT INTO `users` (identifier, firstname, lastname) VALUES (?, ?, ?)', {
    identifier, firstName, lastName
})

print(id)
```

**Aliases**

- `MySQL.Sync.insert`
- `exports.ghmattimysql.executeSync`
- `exports.oxmysql.insert_async`

## Callback

```lua
MySQL.insert('INSERT INTO `users` (identifier, firstname, lastname) VALUES (?, ?, ?)', {
    identifier, firstName, lastName
}, function(id)
    print(id)
end)
```

**Aliases**

- `MySQL.Async.insert`
- `exports.ghmattimysql.execute`
- `exports.oxmysql.insert`