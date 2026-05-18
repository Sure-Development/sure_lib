# Query

When selecting data, returns all matching rows and columns; otherwise, returns data like insertId, affectedRows, etc.

## Promise

```lua
local response = MySQL.query.await('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {
    identifier
})

if response then
    for i = 1, #response do
        local row = response[i]
        print(row.firstname, row.lastname)
    end
end
```

**Aliases**

- `MySQL.Sync.fetchAll`
- `exports.ghmattimysql.execute`
- `exports.oxmysql.query_async`

## Callback

```lua
MySQL.query('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {
    identifier
}, function(response)
    if response then
        for i = 1, #response do
            local row = response[i]
            print(row.firstname, row.lastname)
        end
    end
end)
```

**Aliases**

- `MySQL.Async.fetchAll`
- `exports.ghmattimysql.execute`
- `exports.oxmysql.query`