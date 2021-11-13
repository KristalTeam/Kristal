local item = Item{
    -- Item ID (optional, defaults to path)
    id = "silver_watch",
    -- Display name
    name = "Silver Watch",

    -- Item type (item, key, weapon, armor)
    type = "armor",
    -- Item icon (for equipment)
    icon = "ui/menu/icon/armor",

    -- Battle description
    effect = "",
    -- Shop description
    shop = "Holiday\nthemed",
    -- Menu description
    description = "Grazing bullets affects\nthe turn length by 10% more",

    -- Shop sell price
    price = 100,

    -- Consumable target mode (party, enemy, or none/nil)
    target = nil,
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = false,

    -- Equip bonuses (for weapons and armor)
    bonuses = {
        defense = 2,
    },
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = "GrazeTime",
    bonus_icon = "ui/menu/icon/up",

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions
    reactions = {
        susie = "It's clobbering time.",
        ralsei = "I'm late, I'm late!",
        noelle = "(Th-this was mine...)",
    },
}

return item