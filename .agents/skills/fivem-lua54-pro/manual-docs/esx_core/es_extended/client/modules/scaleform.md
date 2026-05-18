# Scaleform
Scaleforms is the Rockstar Games' proprietary UI solution for GTA V. It is a Flash-based UI system that allows developers to create UI elements using ActionScript 3.0. Scaleforms are used in GTA V to create the game's menus, HUD, and other UI elements.
We provide some basic and popular scaleforms in ESX, such as the Freemode Message popup or the "Breaking News" overlay from the GTA: Online races.

## Functions

### ShowFreemodeMessage
Show the Freemode Message scaleform.

// TODO: Add image

**Arguments**
- title: `string`
  - The title of the message.
- msg: `string`
  - The message to display.
- sec: `number`
  - The duration of the message in seconds.

**Example**
```lua
ESX.Scaleform.ShowFreemodeMessage('Kill Leader', 'You are the new Kill Leader!', 3)
```

### ShowBreakingNews
Show the Breaking News scaleform.

// TODO: Add image

**Arguments**
- title: `string`
  - The title of the news.
- msg: `string`
  - The message to display.
- bottom: `string`
  - The bottom text.
- sec: `number`
  - The duration of the message in seconds.

**Example**
```lua
ESX.Scaleform.ShowBreakingNews('Breaking News', 'The new update is now live!', 'discord.esx-framework.org', 5)
```

### ShowPopupWarning
Show the Popup Warning scaleform.

// TODO: Add image

**Arguments**
- title: `string`
  - The title of the warning.
- msg: `string`
  - The message to display.
- sec: `number`
  - The duration of the message in seconds.

**Example**
```lua
ESX.Scaleform.ShowPopupWarning('AFK Warning', 'You are about to be kicked!', 5)
```

### ShowTrafficMovie
Show the Traffic Movie scaleform.

// TODO: Add gif?

**Arguments**
- sec: `number`
  - The duration of the movie in seconds.

**Example**
```lua
ESX.Scaleform.ShowTrafficMovie(5)
```

### Utils

#### RequestScaleformMovie
Request a scaleform movie.

**Arguments**

- movie: `string`
  - The name of the movie.

**Returns**
- `number`
  - The handle of the movie.

**Example**
```lua
function ESX.Scaleform.ShowTrafficMovie(sec)
    local scaleform = ESX.Scaleform.Utils.RequestScaleformMovie("TRAFFIC_CAM")

    ESX.Scaleform.Utils.RunMethod(scaleform, "PLAY_CAM_MOVIE")

    while sec > 0 do
        Wait(0)
        sec = sec - 0.01

        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    end

    SetScaleformMovieAsNoLongerNeeded(scaleform)
end
```

#### RunMethod

Run a method on a scaleform movie.

**Arguments**

- scaleform: `number` | `string`
  - The handle (or name) of the scaleform movie.
- method: `string`
    - The name of the method to run.
- returnValue: `boolean`
    - Whether the method returns a value.
- ...: `number` | `string` | `boolean`
    - The arguments to pass to the method.

**Returns**
- `scaleform`: `number`
    - The handle of the scaleform movie.
- returnValue: `any`
    - The return value of the method if `returnValue` is true.

**Example**

```lua
function ESX.Scaleform.ShowBreakingNews(title, msg, bottom, sec)
    local scaleform = ESX.Scaleform.Utils.RunMethod("BREAKING_NEWS", "SET_TEXT", false, msg, bottom)
    ESX.Scaleform.Utils.RunMethod(scaleform, "SET_SCROLL_TEXT", false, 0, 0, title)
    ESX.Scaleform.Utils.RunMethod(scaleform, "DISPLAY_SCROLL_TEXT", false, 0, 0)

    while sec > 0 do
        Wait(0)
        sec = sec - 0.01

        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    end

    SetScaleformMovieAsNoLongerNeeded(scaleform)
end
```
