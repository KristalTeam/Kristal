return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "ralsei",
    -- Display name
    name = "Ralsei",

    -- Actor ID (handles sprites)
    actor = "ralsei",

    -- Title / class (saved to the save file)
    title = "LV1 Dark Prince\nDark-World being.\nHas friends now.",

    -- Character color (for action box outline and hp bar)
    color = {0, 1, 0},
    -- Damage color (for the number when attacking enemies)
    dmg_color = {0.5, 1, 0.5},
    -- Fightbar color (the moving bar used in attack mode)
    fightbar_color = {181/255, 230/255, 29/255},
    -- X-Action color (for the color of X-Action menu items)
    xact_color = {0.5, 1, 0.5},

    xact_name = "R-Action",

    -- Head icon in the equip / power menu
    menu_icon = "party/ralsei/head",
    -- Path to head icons used in battle
    head_icons = "party/ralsei/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/ralsei/name",

    -- Effect shown above enemy after attacking it
    dmg_sprite = "effects/attack/slap_r",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- Spells by id
    spells = {"pacify", "heal_prayer"},

    -- Current health (saved to the save file)
    health = 100,

    -- Base stats (saved to the save file)
    stats = {
        health = 100,
        attack = 10,
        defense = 2,
        magic = 9
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/scarf",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "red_scarf",
        armor = {}
    },

    -- Battle position offset (optional)
    battle_offset = {2, 6},
}