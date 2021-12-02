local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "dd_burger",
    -- Display name
    name = "DD-Burger",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n60HP 2x",
    -- Shop description
    shop = "Double\ndarkburger\n60HP 2x",
    -- Menu description
    description = "It's the Double-Dark-Burger.\nIt'll take two bites to finish!",

    -- Amount healed (HealItem variable)
    heal_amount = 60,

    -- Shop sell price
    price = 110,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "party",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = "darkburger",
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
    reactions = {
        susie = "C'mon, gimme the rest!",
        ralsei = "M-maybe give Susie the rest?",
        noelle = "Th... there's MORE!?"
    },
}

return item