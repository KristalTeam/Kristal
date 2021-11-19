local character = PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "kris",
    -- Display name
    name = "Kris",

    -- Actor ID (handles overworld/battle sprites)
    actor = "kris",
    -- Light World Actor ID (handles overworld/battle sprites in light world maps) (optional)
    lw_actor = "kris_lw",

    -- Display level (saved to the save file)
    level = 1,
    -- Default title / class (saved to the save file)
    title = "Leader\nCommands the party\nwith various ACTs.",

    -- Whether the party member can act / use spells
    has_act = true,
    has_spells = false,

    -- X-Action name (displayed in this character's spell menu)
    xact_name = "K-Action",

    -- Spells by id
    spells = {},

    -- Current health (saved to the save file)
    health = 90,

    -- Base stats (saved to the save file)
    stats = {
        health = 90,
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
    color = {0, 1, 1},
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    dmg_color = {0.5, 1, 1},
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    attack_bar_color = {0, 162/255, 232/255},
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    attack_box_color = {0, 0, 1},
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    xact_color = {0.5, 1, 1},

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
    battle_offset = {2, 1},

    -- Message shown on gameover (optional)
    gameover_message = nil,
}

function character:onPowerSelect(menu)
    if Utils.random() <= 0.03 then
        menu.kris_dog = true
    else
        menu.kris_dog = false
    end
end

function character:drawPowerStat(index, x, y, menu)
    if index == 1 and menu.kris_dog then
        local frames = Assets.getFrames("misc/dog_sleep")
        local frame = math.floor(love.timer.getTime()) % #frames + 1
        love.graphics.print("Dog:", x, y)
        love.graphics.draw(frames[frame], x+120, y+5, 0, 2, 2)
        return true
    elseif index == 3 then
        local icon = Assets.getTexture("ui/menu/icon/fire")
        love.graphics.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Guts:", x, y)

        love.graphics.draw(icon, x+90, y+6, 0, 2, 2)
        return true
    end
end

return character