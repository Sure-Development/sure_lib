# RawExecute

rawExecute can be used to execute frequently called queries faster and accepts multiple sets of parameters to be used with a single query.

- Date will not return the datestring commonly used in FiveM
- TINYINT 1 and BIT will not return a boolean
- You can only use ? value placeholders, ?? column placeholders and named placeholders will throw an error

Unlike [prepare](./prepare.md), the SELECT statement will always return an array of rows.
When using SELECT, the return value will match `query`, `single`, or `scalar` depending on the number of columns and rows selected.

## Promise

```lua
local response = MySQL.rawExecute.await('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {
    identifier
})


print(json.encode(response, { indent = true, sort_keys = true }))
```

**Aliases**

- `exports.oxmysql.rawExecute_async`

## Callback

```lua
MySQL.rawExecute('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {
    identifier
}, function(response)
    print(json.encode(response, { indent = true, sort_keys = true }))
end)
```

**Aliases**

- `exports.oxmysql.rawExecute`
