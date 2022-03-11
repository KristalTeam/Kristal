local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "fav_sandwich",
    -- Display name
    name = "Favwich",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\nALL\nHP",
    -- Shop description
    shop = "",
    -- Menu description
    description = "You'd think it tastes perfect.\nHeals 500HP.",

    -- Amount healed (HealItem variable)
    heal_amount = 500,

    -- Shop sell price
    price = 5,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "party",
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
    reactions = {
        susie = "It's SO good!",
        ralsei = "K-Kris!? I...",
        noelle = "(Huh? I didn't know Kris liked this flavor.)"
    },
}

return item