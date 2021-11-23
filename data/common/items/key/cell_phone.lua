local item = Item{
    -- Item ID (optional, defaults to path)
    id = "cell_phone",
    -- Display name
    name = "Cell Phone",

    -- Item type (item, key, weapon, armor)
    type = "key",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "",
    -- Shop description
    shop = "",
    -- Menu description
    description = "It can be used to make calls.",

    -- Shop sell price
    price = 0,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "none",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "world",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = false,

    -- Equip bonuses (for weapons and armor)
    bonuses = {},
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions (key = party member id)
    reactions = {},
}

function item:onWorldUse()
    Game.world:startCutscene(function(cutscene)
        Assets.playSound("snd_phone", 0.7)
        cutscene:text("* (You tried to call on the Cell\nPhone.)", nil, nil, {advance = false})
        cutscene:wait(40/30)
        local was_playing = Game.world.music:isPlaying()
        if was_playing then
            Game.world.music:pause()
        end
        Assets.playSound("snd_smile")
        cutscene:wait(200/30)
        if was_playing then
            Game.world.music:resume()
        end
        cutscene:text("* It's nothing but garbage noise.")
    end)
end

return item