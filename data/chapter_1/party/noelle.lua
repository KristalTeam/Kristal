local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "noelle",
    -- Display name
    name = "Noelle",

    -- Actor ID (handles sprites)
    actor = "noelle",
    -- Light World Actor ID (handles overworld/battle sprites in light world maps) (optional)
    lw_actor = "noelle_lw",

    -- Display level (saved to the save file)
    level = 1,
    -- Default title / class (saved to the save file)
    title = "Snowcaster\nMight be able to\nuse some cool moves.",

    -- Determines which character the soul comes from (higher number = higher priority)
    soul_priority = 1,

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "N-Action",

    -- Spells by id
    spells = {"heal_prayer", "sleep_mist", "ice_shock"},

    -- Current health (saved to the save file)
    health = 60,

    -- Base stats (saved to the save file)
    stats = {
        health = 60,
        attack = 1,
        defense = 1,
        magic = 9
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/ring",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "snow_ring",
        armor = {"silver_watch"}
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
    -- Head icon position offset (optional)
    head_icon_offset = nil,
    -- Menu icon position offset (optional)
    menu_icon_offset = nil,

    -- Message shown on gameover (optional)
    gameover_message = nil,

    -- Character flags (saved to the save file)
    flags = {
        ["iceshocks_used"] = 0,
        ["boldness"] = -12
    },
}

function character:getTitle()
    if self:getFlag("iceshocks_used", 0) > 0 then
        return "LV"..self.level.." Frostmancer\nFreezes the enemy."
    else
        return "LV1 "..self.title
    end
end

function character:drawPowerStat(index, x, y, menu)
    if index == 1 then
        local icon = Assets.getTexture("ui/menu/icon/snow")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Coldness", x, y)
        local coldness = Utils.clamp(47 + (self:getFlag("iceshocks_used", 0) * 7), 47, 100)
        love.graphics.print(coldness, x+130, y)
        return true
    elseif index == 2 then
        local icon = Assets.getTexture("ui/menu/icon/exclamation")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Boldness", x, y, 0, 0.8, 1)
        love.graphics.print(self:getFlag("boldness", -12), x+130, y)
        return true
    elseif index == 3 then
        local icon = Assets.getTexture("ui/menu/icon/fire")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Guts:", x, y)
        return true
    end
end

return character