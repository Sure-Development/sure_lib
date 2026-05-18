# esx_menu_default
A list type menu used by `es_extended`
**Only available on clientside**

### ESX.UI.Menu.Open
Open a menu that can be used with arrow keys

```lua
ESX.UI.Menu.Open(type, namespace, name, data, onSelect, cancel )
```

**Arguments**
- type: `string`
  - the menu to open `default` in this case
- namespace: `string`
  - The namespace of the menu, usually ```GetResourceName()```is used
- name: `string`
  - The name of the menu
- data: `table`
  - The table with the elements to show in the menu
- onSelect: `function`
  - Function that gets ran when an element is selected.
- cancel: `function`
  - Function that gets ran when the menu gets closed 

**Data table**
- title: `title` of the menu
- align: `position` (top-left | top-right | bottom-left | bottom-right | center)
- elements: `selectable` elements table
- locales?: `locales` table

**Elements**
- label: `string`
  - label name to show, supports HTML
- name: `string`
  - name of the element
- value: `number` | `string`
  - value of the element/slider
- type: `slider` | `button` - default is button
  - Type of the element
- min: `number`
  - minimum slider value
- max: `number`
  - Maximum slider value
- disableRightArrow?: boolean
  - Disables right arrow icon for buttons
- unselectable?: boolean
  - Makes the menu element not selectable
- usable?: boolean
  - Makes the menu element not usable
- options?: string[]
  - Allows to use options instead of numbers in slider
- icon?: string
  - Icon next to the text

### onSelect

Function triggered when an element is selected, returns `data` and `menu`, `data.current` is used to get the current selected element

**Example**
```lua
function(data, menu)
  --- for a simple element
  if data.current.name == "element1" then
    print("Element 1 Selected")
    menu.close()
  end

  -- for slider elements

  if data.current.name == "bread" then
    print(data.current.value)
  end
end
```
### cancel

This function is triggered when the menu gets closed, returns `data` and `menu`

**Example**
```lua
function(data, menu)
  print("Closing Menu - " .. menu.title)
  menu.close() -- close menu
end
```

### Menu Example
```lua
    local Elements = {
        {label = "I`m An Element", name = "element1"},
        {label = "Bread - £200", name = "bread", value = 1, type = 'slider', min = 1,max = 100},
        {label = '<span style="color:green;">HEY! IM GREEN!/span>', name = "geen_element"}
      }

      ESX.UI.Menu.Open("default", GetCurrentResourceName(), "Example_Menu", {
        title = "Example Menu", -- The Name of Menu to show to users,
        align = "top-left" | "top-right" | "bottom-left" | "bottom-right" | "center" | "left-center" | "right-center"
        elements = Elements, -- define elements as the pre-created table
      }, function(data,menu) -- OnSelect Function
        --- for a simple element
        if data.current.name == "element1" then
          print("Element 1 Selected")
          menu.close()
        end

        -- for slider elements

        if data.current.name == "bread" then
          print(data.current.value)

          if data.current.value == 69 then
            print("Nice!")
            menu.close()
          end
        end
      end, function(data, menu) -- Cancel Function
        print("Closing Menu")
        menu.close() -- close menu
      end)
```

**Example with ESX_INVENTORY**
<img src="https://media.discordapp.net/attachments/1370464258382368918/1411718707842912296/482157467-7f03706b-1794-40ac-9cf5-bba13dadd9c4.png?ex=68b5ad00&is=68b45b80&hm=c96f3dd053b35a1eff0b4d79b6d0ece10ab5d418a156330bd369b1e94094af8e&=&format=webp&quality=lossless&width=1529&height=860"></img>
