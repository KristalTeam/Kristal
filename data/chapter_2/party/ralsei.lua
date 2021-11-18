local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "ralsei",
    -- Display name
    name = "Ralsei",

    -- Actor ID (handles sprites)
    actor = "ralsei",
    -- Light World Actor ID (handles overworld/battle sprites in light world maps) (optional)
    lw_actor = nil,

    -- Title / class (saved to the save file)
    title = "LV1 Dark Prince\nDark-World being.\nHas friends now.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "R-Action",

    -- Spells by id
    spells = {"pacify", "heal_prayer", "dual_heal"},

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
        armor = {"amber_card", "white_ribbon"}
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
    menu_icon = "party/ralsei/head",
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

    -- Message shown on gameover (optional)
    gameover_message = {
        "This is not\nyour fate...!",
        "Please[wait:5],\ndon't give up!"
    },
}

function character:onLevelUp(level)
    self:increaseStat("health", 2, 140)
    if level % 10 == 0 then
        self:increaseStat("attack", 1)
        self:increaseStat("magic", 1)
    end
end

return character