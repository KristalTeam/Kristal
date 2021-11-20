local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "susie",
    -- Display name
    name = "Susie",

    -- Actor ID (handles sprites)
    actor = "susie",
    -- Light World Actor ID (handles overworld/battle sprites in light world maps) (optional)
    lw_actor = "susie_lw",

    -- Display level (saved to the save file)
    level = 2,
    -- Default title / class (saved to the save file)
    title = "Dark Knight\nDoes damage using\ndark energy.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "S-Action",

    -- Spells by id (saved to the save file)
    spells = {"rude_buster", "ultimate_heal"},

    -- Current health (saved to the save file)
    health = 140,

    -- Base stats (saved to the save file)
    stats = {
        health = 140,
        attack = 16,
        defense = 2,
        magic = 1
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/axe",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "mane_ax",
        armor = {"amber_card", "amber_card"}
    },

    -- Character color (for action box outline and hp bar)
    color = {1, 0, 1},
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    dmg_color = {0.8, 0.6, 0.8},
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    attack_bar_color = {234/255, 121/255, 200/255},
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    attack_box_color = {0.5, 0, 0.5},
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    xact_color = {1, 0.5, 1},

    -- Head icon in the equip / power menu
    menu_icon = "party/susie/head",
    -- Path to head icons used in battle
    head_icons = "party/susie/icon",
    -- Name sprite (TODO: optional)
    name_sprite = "party/susie/name",

    -- Effect shown above enemy after attacking it
    attack_sprite = "effects/attack/mash",
    -- Sound played when this character attacks
    attack_sound = "snd_laz_c",
    -- Pitch of the attack sound
    attack_pitch = 0.9,

    -- Battle position offset (optional)
    battle_offset = {3, 1},
    -- Head icon position offset (optional)
    head_icon_offset = nil,
    -- Menu icon position offset (optional)
    menu_icon_offset = nil,

    -- Message shown on gameover (optional)
    gameover_message = {
        "Come on[wait:5],\nthat all you got!?",
        "Kris[wait:5],\nget up...!"
    },
}

function character:onAttackHit(enemy, damage)
    if damage > 0 then
        Assets.playSound("snd_impact", 0.8)
        Game.battle.shake = 4
    end
end

function character:onLevelUp(level)
    self:increaseStat("health", 2, 190)
    if level % 2 == 0 then
        self:increaseStat("health", 1, 190)
    end
    if level % 10 == 0 then
        self:increaseStat("attack", 1)
        self:increaseStat("magic", 1)
    end
end

function character:drawPowerStat(index, x, y, menu)
    if index == 1 then
        local icon = Assets.getTexture("ui/menu/icon/demon")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Rudeness", x, y)
        love.graphics.print("89", x+130, y)
        return true
    elseif index == 2 then
        local icon = Assets.getTexture("ui/menu/icon/demon")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Purple", x, y, 0, 0.8, 1)
        love.graphics.print("Yes", x+130, y)
        return true
    elseif index == 3 then
        local icon = Assets.getTexture("ui/menu/icon/fire")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Guts:", x, y)

        love.graphics.draw(icon, x+90, y+6, 0, 2, 2)
        love.graphics.draw(icon, x+110, y+6, 0, 2, 2)
        return true
    end
end

return character