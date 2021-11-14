local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "noelle",
    -- Display name
    name = "Noelle",

    -- Actor ID (handles sprites)
    actor = "noelle",

    -- Title / class (saved to the save file)
    title = "LV1 Snowcaster\nMight be able to\nuse some cool moves.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "N-Action",

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
        armor = {"silver_watch", "royal_pin"}
    },

    -- Character color (for action box outline and hp bar)
    color = {1, 1, 0},
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    dmg_color = {1, 1, 0.3},
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    attack_bar_color = {1, 1, 153/255},
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    attack_box_color = {1, 1, 0},
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    xact_color = {1, 1, 0.5},

    -- Head icon in the equip / power menu
    menu_icon = "party/noelle/head",
    -- Path to head icons used in battle
    head_icons = "party/noelle/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/noelle/name",

    -- Effect shown above enemy after attacking it
    attack_sprite = "effects/attack/slap_n",
    -- Sound played when this character attacks
    attack_sound = "snd_laz_c",
    -- Pitch of the attack sound
    attack_pitch = 1.5,

    -- Battle position offset (optional)
    battle_offset = {0, 0},

    -- Message shown on gameover (optional)
    gameover_message = nil,
}

function character:onLevelUp(level)
    self:increaseStat("health", 4, 166)
    if level % 4 == 0 then
        self:increaseStat("attack", 1)
        self:increaseStat("magic", 1)
    end
end

return character