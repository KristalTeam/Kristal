local item = Item{
    -- Item ID (optional, defaults to path)
    id = "dog_dollar",
    -- Display name
    name = "DogDollar",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Not\nso\nuseful",
    -- Shop description
    shop = nil,
    -- Menu description
    description = "A dollar with a certain dog on it.\nIts value decreases each Chapter.",

    -- Shop sell price
    price = math.ceil(100/Game.chapter),

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "noselect",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "battle",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = false,

    -- Equip bonuses (for weapons and armor)
    bonuses = {
        attack = 0,
    },
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions
    reactions = {},
}

function item:onWorldUse(target)
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume
    return false
end

function item:getBattleText(user, target)
    return "* "..user.chara.name.." admired DOGDOLLAR!"
end

return item