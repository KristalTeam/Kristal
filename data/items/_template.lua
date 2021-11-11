local item = Item{
    -- Item ID (optional, defaults to path)
    id = nil,
    -- Display name
    name = "Test Item",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "",
    -- Shop description
    shop = "",
    -- Menu description
    description = "Example item.",

    -- Shop sell price
    price = 0,

    -- Consumable target mode (party, enemy, or none/nil)
    target = nil,
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,

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

return item