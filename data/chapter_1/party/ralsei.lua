return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "ralsei",
    -- Display name
    name = "Ralsei",

    -- Actor ID (handles sprites)
    actor = "ralsei",

    -- Title / class (saved to the save file)
    title = "LV1 Lonely Prince\nDark-World being.\nHas no subjects.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "R-Action",

    -- Spells by id
    spells = {"pacify", "heal_prayer"},

    -- Current health (saved to the save file)
    health = 70,

    -- Base stats (saved to the save file)
    stats = {
        health = 70,
        attack = 8,
        defense = 2,
        magic = 7
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/scarf",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "red_scarf",
        armor = {}
    },

    -- Character color (for action box outline and hp bar)
    color = {0, 1, 0},
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    dmg_color = {0.5, 1, 0.5},
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    attack_bar_color = {181/255, 230/255, 29/255},
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    attack_box_color = {0, 0.5, 0},
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    xact_color = {0.5, 1, 0.5},

    -- Head icon in the equip / power menu
    menu_icon = "party/ralsei/head_hat",
    -- Path to head icons used in battle
    head_icons = "party/ralsei/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/ralsei/name",

    -- Effect shown above enemy after attacking it
    attack_sprite = "effects/attack/slap_r",
    -- Sound played when this character attacks
    attack_sound = "snd_laz_c",
    -- Pitch of the attack sound
    attack_pitch = 1.15,

    -- Battle position offset (optional)
    battle_offset = {2, 6},
}