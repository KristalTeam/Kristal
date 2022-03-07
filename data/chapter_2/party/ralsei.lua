local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "ralsei",
    -- Display name
    name = "Ralsei",

    -- Actor ID (handles sprites)
    actor = "ralsei",
    -- Light World Actor ID (handles overworld/battle sprites in light world maps) (optional)
    lw_actor = nil,

    -- Display level (saved to the save file)
    level = 2,
    -- Default title / class (saved to the save file)
    title = "Dark Prince\nDark-World being.\nHas friends now.",

    -- Determines which character the soul comes from (higher number = higher priority)
    soul_priority = -1,

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "R-Action",

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
    -- Head icon position offset (optional)
    head_icon_offset = nil,
    -- Menu icon position offset (optional)
    menu_icon_offset = nil,

    -- Message shown on gameover (optional)
    gameover_message = {
        "This is not\nyour fate...!",
        "Please,[wait:5]\ndon't give up!"
    },
}

function character:onLevelUp(level)
    self:increaseStat("health", 2, 140)
    if level % 10 == 0 then
        self:increaseStat("attack", 1)
        self:increaseStat("magic", 1)
    end
end

function character:drawPowerStat(index, x, y, menu)
    if index == 1 then
        local icon = Assets.getTexture("ui/menu/icon/lollipop")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Sweetness", x, y)
        love.graphics.print("97", x+130, y)
        return true
    elseif index == 2 then
        local icon = Assets.getTexture("ui/menu/icon/fluff")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Fluffiness", x, y, 0, 0.8, 1)

        love.graphics.draw(icon, x+130, y+6, 0, 2, 2)
        love.graphics.draw(icon, x+150, y+6, 0, 2, 2)
        return true
    elseif index == 3 then
        local icon = Assets.getTexture("ui/menu/icon/fire")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Guts:", x, y)
        return true
    end
end

return character