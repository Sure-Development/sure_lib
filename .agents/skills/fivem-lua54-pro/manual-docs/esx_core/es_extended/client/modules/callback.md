# Callback
This is a module that allows you to create callbacks in your scripts.

## Functions

### TriggerServerCallback
This function trigger a previously registered server callback

> See [RegisterServerCallback](esx_core/es_extended/server/functions#registerservercallback) for how to register a server callback.

**Arguments**
- name: `string`
  - The server callback's name.
- cb: `function`
  - The callback function passed from the server.
- ...
  - The arguments that should be passed to the server callback.

**Example**
```lua
ESX.TriggerServerCallback('myScript:getMeme', function(cb)
  print(cb) --output: "Meme data string"
end)
```

### AwaitServerCallback
This function trigger a previously registered server callback, but it will wait for the callback to return before continuing the script.

> See [RegisterServerCallback](esx_core/es_extended/server/functions#registerservercallback) for how to register a server callback.

**Arguments**
- name: `string`
- The server callback's name.

**Return value**
- The return value of the server callback.

**Example**
```lua
local returnValue = ESX.AwaitServerCallback('myScript:getMeme')
print(returnValue) --output: "Meme data string"
```


### RegisterClientCallback
This function registers a client callback

*See [TriggerServerCallback](/esx_core/es_extended/server/functions#triggerclientcallback)*

**Arguments**
- callbackName: `string`
  - The callback's name.
- cb: `function`
  - The callback function.

**Example**
```lua
ESX.RegisterClientCallback('myScript:getMeme', function(cb)
  cb('Meme data string')
end)
```
