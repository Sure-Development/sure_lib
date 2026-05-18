# esx_menu_dialog
A menu used to get inputs from the player.
**Only available on clientside**

### ESX.UI.Menu.Open
Open a menu that can be used to input a value

```lua
ESX.UI.Menu.Open(type, namespace, name, data, confirm, cancel )
```

**Arguments**
- type: `string`
  - the menu to open `dialog` in this case
- namespace: `string`
  - The namespace of the menu, usually ```GetResourceName()```is used
- name: `string`
  - The name of the menu
- data: `table`
  - The table with the elements to show in the menu
- confirm: `function`
  - Function that gets ran when an element is selected.
- cancel: `function`
  - Function that gets ran when the menu gets closed 

**Data table**
- title: `title` of the menu


**confirm**

Function triggered when the confirm button is pressed, returns `data` and `menu`, `data.value` is used to get the current vlue inserted

**cancel**

This function is triggered when the cancel button is pressed or the menu is closed, returns `data` and `menu`


### Menu Example
```lua
  ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "Example_Menu", {
    title = "Example Menu", -- The Name of Menu to show to users,
  }, function(data,menu) -- confirm function  
      local value = data.value
      print(value)
      menu.close()
    end, 
    function(data, menu) -- Cancel Function
      print("Closing Menu")
      menu.close() -- close menu
  end)
```
**Result**
<img src = "https://private-user-images.githubusercontent.com/90266455/483988755-d6681576-502c-43ed-a243-2181254fc9b2.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTY4MjEwNTIsIm5iZiI6MTc1NjgyMDc1MiwicGF0aCI6Ii85MDI2NjQ1NS80ODM5ODg3NTUtZDY2ODE1NzYtNTAyYy00M2VkLWEyNDMtMjE4MTI1NGZjOWIyLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA5MDIlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwOTAyVDEzNDU1MlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTk4N2JkYTQwOTZkMzg0NDI2Y2MwNjYwMzkwNzUxMmQyZWZkOWY0YmMxYzYyMTdiY2RjZThlZmI2ODY5NzA3OTUmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.zpClCFy504O4ZrxUyRPYqn9gUhIK_d-GQGQhWquizGk"></img>
