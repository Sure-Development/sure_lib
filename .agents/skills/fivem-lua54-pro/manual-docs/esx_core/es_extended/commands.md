# Commands

A list of commands provided by es_extended.

## All Users

### `/clear`

**Aliases:** `/cls`

This command clears the chat

### `/group`

Shows the permissions group you are in.

### `/job`

Shows the job you have

### `/info`

Shows your RP name, Job Name, Job Grade, and if you are on duty or not.

### `/playtime`

Shows your playtime for the current character in `Days`, `Hours`, `Minutes`.

## Admin Commands

### `/setcoords`

**Aliases:** `/tp`

**Arguments:**
    - `x` (number)
    - `y` (number)
    - `z` (number)

Teleports you to the specified coordinates.

**Example:** `/setcoords 0 0 0`

### `/setjob`

**Arguments:**
    - `playerId` (number)
    - `job` (string)
    - `grade` (number)

Sets the job of the specified player to the specified job and grade.

**Example:** `/setjob 1 police 0`

### `/car`

**Arguments:**
    - `model` (string)

Spawns a car with the specified model.

**Example:** `/car adder`

### `/dv`

**Aliases:** `/cardel`

**Arguments:**
    - `Radius` (number)

**Example:** `/dv 10`

Deletes all vehicles within the specified radius.

### `/fix`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/fix 1`

Fixes the vehicle of the specified player.

### `/setaccountmoney`

**Arguments:**
    - `PlayerId` (number)
    - `Account` (string)
    - `Amount` (number)

**Example:** `/setaccountmoney 1 bank 1000`

**Valid Accounts:** `bank`, `black_money`, `money` (**not `cash`**)

### `/giveaccountmoney`

**Arguments:**
    - `PlayerId` (number)
    - `Account` (string)
    - `Amount` (number)

**Example:** `/giveaccountmoney 1 bank 1000`

**Valid Accounts:** `bank`, `black_money`, `money` (**not `cash`**)

### `/removeaccountmoney`

**Arguments:**
    - `PlayerId` (number)
    - `Account` (string)
    - `Amount` (number)

**Example:** `/removeaccountmoney 1 bank 1000`

**Valid Accounts:** `bank`, `black_money`, `money` (**not `cash`**)

### `/giveitem`

**Arguments:**
    - `PlayerId` (number)
    - `Item` (string)
    - `Amount` (number)

**Example:** `/giveitem 1 bread 10`

Gives the specified player the specified item.

### `/giveweapon`

**Arguments:**
    - `PlayerId` (number)
    - `Weapon` (string)
    - `Ammo` (number)

**Example:** `/giveweapon 1 weapon_pistol 100`

Gives the specified player the specified weapon with the specified ammo.

### `/giveammo`

**Arguments:**
    - `PlayerId` (number)
    - `Weapon` (string)
    - `Ammo` (number)

**Example:** `/giveammo 1 weapon_pistol 100`

Gives the specified player the specified ammo to the specified weapon.

### `/giveweaponcomponent`

**Arguments:**
    - `PlayerId` (number)
    - `Weapon` (string)
    - `Component` (string)

**Example:** `/giveweaponcomponent 1 weapon_pistol component_at_rail`

Gives the specified player the specified weapon component.

### `/clearall`

**aliases:** `/clsall`

Clears the chat for all players.

### `/refreshjobs`

Refreshes the all known jobs.

### `/refreshitems`

Refreshes the all known items.

### `/clearinventory`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/clearinventory 1`

Clears the inventory of the specified player.

### `/clearloadout`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/clearloadout 1`

Clears the loadout of the specified player.

### `/setgroup`

**Arguments:**
    - `PlayerId` (number)
    - `Group` (string)

**Example:** `/setgroup 1 admin`

Sets the group of the specified player to the specified group.
> **NOTE**: `superadmin` is NOT a valid group. `admin` is the highest group by default.

### `/save`

**NOT RECOMMENDED TO USE**

**Arguments:**
    - `PlayerId` (number)

**Example:** `/save 1`

Saves the specified player.

### `/saveall`

**NOT RECOMMENDED TO USE**

**Example:** `/saveall`

Saves all players.


### `/coords`

prints both vector3 and vector4 coords of the player

### `/tpm`

Teleports you to the marker on the map

### `/goto`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/goto 1`

Teleports you to the specified player.

### `/bring`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/bring 1`

Teleports the specified player to you.

### `/kill`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/kill 1`

Kills the specified player.

### `/freeze`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/freeze 1`

Freezes the specified player, preventing them from moving.

### `/unfreeze`

**Arguments:**
    - `PlayerId` (number)

**Example:** `/unfreeze 1`

Unfreezes the specified player, allowing them to move again.

### `/noclip`

Allows you to fly around the map.

### `/players`

prints the `ID`, `RP Name`, `Group` and `Identifier` of all players

### `/setbucket`

**aliases:** `/setdim`

**Arguments:**
    - `PlayerId` (number)
    - `Dimension` (number)

**Example:** `/setbucket 1 2`

Sets the routing bucket of the specified player to the specified number.
> **NOTE**: default bucket is 0 and all players are in the same bucket by default.
