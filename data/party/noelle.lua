return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "noelle",
    -- Display name
    name = "Noelle",

    -- Actor ID (handles sprites)
    actor = "noelle",

    -- Title / class (saved to the save file)
    title = "LV1 Snowcaster\nMight be able to\nuse some cool moves.",

    -- Character color (for action box outline and hp bar)
    color = {1, 1, 0},
    -- Damage color (for the number when attacking enemies)
    dmg_color = {1, 1, 0.3},
    -- Fightbar color (the moving bar used in attack mode)
    fightbar_color = {1, 1, 153/255},

    -- Head icon in the equip / power menu
    menu_icon = "party/noelle/head",
    -- Path to head icons used in battle
    head_icons = "party/noelle/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/noelle/name",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- Spells by id
    spells = {"heal_prayer", "sleep_mist", "ice_shock"},

    -- Current health (saved to the save file)
    health = 90,

    -- Base stats (saved to the save file)
    stats = {
        health = 90,
        attack = 3,
        defense = 1,
        magic = 11
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/ring",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "snow_ring",
        armor = {"silver_watch"}
    },

    -- Battle position offset (optional)
    battle_offset = {0, 0},
}