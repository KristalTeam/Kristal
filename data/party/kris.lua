return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "kris",
    -- Display name
    name = "Kris",

    -- Actor ID (handles overworld/battle sprites)
    actor = "kris",

    -- Title / class (saved to the save file)
    title = "LV1 Leader\nCommands the party\nwith various ACTs.",

    -- Character color (for action box outline and hp bar)
    color = {0, 1, 1},
    -- Damage color (for the number when attacking enemies)
    dmg_color = {0.5, 1, 1},
    -- Fightbar color (the moving bar used in attack mode)
    fightbar_color = {0, 162/255, 232/255},

    -- Head icon in the equip / power menu
    menu_icon = "party/kris/head",
    -- Path to head icons used in battle
    head_icons = "party/kris/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/kris/name",

    -- Whether the party member can act / use spells
    has_act = true,
    has_spells = false,

    -- Spells by id
    spells = {},

    -- Current health (saved to the save file)
    health = 120,

    -- Base stats (saved to the save file)
    stats = {
        health = 120,
        attack = 10,
        defense = 2,
        magic = 0
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/sword",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "wood_blade",
        armor = {}
    },
}