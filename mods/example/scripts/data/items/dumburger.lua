local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "dumburger",
    -- Display name
    name = "Dumburger",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Really\nstupid",
    -- Shop description
    shop = "Radiates\nstupidity\nheals 1000HP",
    -- Menu description
    description = "Completely worthless",

    -- Amount healed (HealItem variable)
    heal_amount = 1000,

    -- Shop sell price
    price = 0,

    -- Consumable target mode (party, enemy, or none/nil)
    target = "enemy",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "battle",
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