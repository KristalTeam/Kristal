local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "dark_candy",
    -- Display name
    name = "Dark Candy",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n40HP",
    -- Shop description
    shop = nil,
    -- Menu description
    description = "Heals 40 HP. A red-and-black star\nthat tastes like marshmallows.",

    -- Amount healed (HealItem variable)
    heal_amount = 40,

    -- Shop sell price
    price = 13,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "party",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
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
    reactions = {
        susie = "Yeahh!! That’s good!",
        ralsei = {
            ralsei = "A bit burnt...?",
            susie = "Hey, feed ME!!!"
        },
        noelle = "Oh, it's... sticky?"
    }
}

return item