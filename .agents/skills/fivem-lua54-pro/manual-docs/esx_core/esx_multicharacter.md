# esx_multicharacter
The default multicharacter system used by `es_extended`

<br />
<img src="https://r2.fivemanage.com/SVPyt7tsQi4njkYd2eKX6/Screenshot2025-01-04021723.png" />
<br />

## Configuration

- `Config.CanDelete`
  - type: boolean
  - default: `true`
  - description: Whether or not players can delete characters.
- `Config.Slots`
  - type: integer
  - default: `4`
  - description: The amount of slots a player has by default.
- `Config.Prefix`
  - type: string
  - default: `char`
  - description: The prefix used in the player identifier.
- `Config.Spawn`
    - type: table
    - default: `{ x = -284.2856, y = 562.4627, z = 172.9182, w = 19.9895 }`
    - description: The spawn locations for the character selection menu (supports multiple spawns).
- `Config.Relog`
    - type: boolean
    - default: `true`
    - description: Allows users to use `/relog`.

## Commands

### Relog
A command with which every player can go into the character selection menu by just running the /relog command.
This command is enabled by default but **can be disabled** in the esx_multicharacter config.

**Usage**
`/relog`

### Set Slots (Admin)
This command allows you to set the amount of slots a player has. This command is only available for **admins**.

**Usage**
`/setslots <identifier> <slots>`

### Remove Slots (Admin)
This command allows you to remove slots from a player. This command is only available for **admins**.

**Usage**
`/remslots <identifier> <slots>`

### Enable Character (Admin)
This command allows you to enable a previously disabled character for a player. This command is only available for **admins**.

**Usage**
`/enablechar <identifier> <CharSlot>`

### Disable Character (Admin)
This command allows you to disable a character for a player. This command is only available for **admins**.

**Usage**
`/disablechar <identifier> <CharSlot>`

### Force Relog (Admin)
This command allows you to force a relog upon yourself. This command is a **debug** command and only available for **admins**.

**Usage**
`/forcerelog`
