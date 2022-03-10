local item = Item{
    -- Item ID (optional, defaults to path)
    id = "egg",
    -- Display name
    name = "Egg",

    -- Item type (item, key, weapon, armor)
    type = "key",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "",
    -- Shop description
    shop = "",
    -- Menu description
    description = "Not too important, not too unimportant.",

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
        Assets.playSound("snd_egg")
            if Game.chapter == 1 then
            cutscene:text("* You used the egg.")
        else
            cutscene:text("* (You used the Egg.)")
        end
    end)
end

return item