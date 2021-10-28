return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "susie",
    -- Display name
    name = "Susie",

    -- Actor ID (handles sprites)
    actor = "susie",

    -- Title / class (saved to the save file)
    title = "LV1 Dark Knight\nDoes damage using\ndark energy.",

    -- Character color (for action box outline and hp bar)
    color = {1, 0, 1},
    -- Damage color (for the number when attacking enemies)
    dmg_color = {0.8, 0.6, 0.8},
    -- Fightbar color (the moving bar used in attack mode)
    fightbar_color = {234/255, 121/255, 200/255},

    -- Head icon in the equip / power menu
    menu_icon = "party/susie/head",
    -- Path to head icons used in battle
    head_icons = "party/susie/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/susie/name",

    -- Whether the party member can act / use spells
    has_act = true,
    has_spells = false,

    -- Spells by id
    spells = {"rude_buster", "ultimate_heal"},

    -- Current health (saved to the save file)
    health = 140,

    -- Base stats (saved to the save file)
    stats = {
        health = 140,
        attack = 14,
        defense = 2,
        magic = 1
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/axe",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "mane_ax",
        armor = {}
    },

    -- Battle position offset (optional)
    battle_offset = {3, 1},
}