local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = nil,
    -- Display name
    name = "Player",

    -- Actor ID (handles overworld/battle sprites)
    actor = "kris",

    -- Display level (saved to the save file)
    level = 1,
    -- Default title / class (saved to the save file)
    title = "Player",

    -- Whether the party member can act / use spells
    has_act = true,
    has_spells = false,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "?-Action",

    -- Spells by id
    spells = {},

    -- Current health (saved to the save file)
    health = 100,

    -- Base stats (saved to the save file)
    stats = {
        health = 100,
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

    -- Character color (for action box outline and hp bar)
    color = {1, 1, 1},
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    dmg_color = nil,
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    attack_bar_color = nil,
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    attack_box_color = nil,
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    xact_color = nil,

    -- Head icon in the equip / power menu
    menu_icon = "party/kris/head",
    -- Path to head icons used in battle
    head_icons = "party/kris/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/kris/name",

    -- Effect shown above enemy after attacking it
    attack_sprite = "effects/attack/cut",
    -- Sound played when this character attacks
    attack_sound = "snd_laz_c",
    -- Pitch of the attack sound
    attack_pitch = 1,

    -- Battle position offset (optional)
    battle_offset = nil,
}

-- Function overrides go here

return character