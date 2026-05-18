# Weapon
All configs related to weapons as an item.

### DefaultWeaponTints
The specifies the label for the default wepaon tints for non mk2 weapons.

### MK2WeaponTints
This specifies the label for the mk2 weapon tints.

### Weapons
This specifies the weapons available, the label and components. This follows a specific format:

**Values**
- name: `string`
  - The weapon name.
- label: `string`
    - The weapon label/The Translation of the weapon.
- ammo?: `table`
    - The ammo table. Only if the weapon uses ammo like a gun.
    - label: `string`
        - The ammo label.
    - hash: `string`
        - The ammo hash.
- tints?: `table`
    - The tints table. Only if the weapon has tints.
- components: `table`
    - The components table. This is an array of components that can be added to the weapon.
    - name: `string`
        - The name of the component.
    - label: `string`
        - The label of the component.
    - hash: `string`
        - The hash of the component.



**Melee Example**
```lua
{
    name = 'WEAPON_KNIFE',
    label = "Knife",
    components = {}
}
```

**Gun Example**
```lua
{
    name = 'WEAPON_APPISTOL',
    label = "AP Pistol",
    ammo = {
        label = 'round(s)',
        hash = `AMMO_PISTOL`
    },
    tints = Config.DefaultWeaponTints,
    components = {
        { name = 'clip_default',  label = 'default Magazine',     hash = `COMPONENT_APPISTOL_CLIP_01` },
		{ name = 'clip_extended', label = 'extended Magazine',    hash = `COMPONENT_APPISTOL_CLIP_02` },
		{ name = 'flashlight',    label = 'flashlight',           hash = `COMPONENT_AT_PI_FLSH` },
		{ name = 'suppressor',    label = 'suppressor',           hash = `COMPONENT_AT_PI_SUPP` },
		{ name = 'luxary_finish', label = 'luxary Weapon Finish', hash = `COMPONENT_APPISTOL_VARMOD_LUXE` }
    }
}
```
