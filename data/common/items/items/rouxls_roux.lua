local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "rouxls_roux",
    -- Display name
    name = "RouxlsRoux",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n50HP",
    -- Shop description
    shop = "ITEM\nFragrant\nsauce\nheals 50HP",
    -- Menu description
    description = "A dark roux with a delicate aroma.\nAlso... has worms in it. +50HP",

    -- Amount healed (HealItem variable)
    heal_amount = 50,

    -- Shop sell price
    price = 25,

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
        susie = "Cool, it's wriggling.",
        ralsei = "Yum, is this spaghetti?",
        noelle = "Tastes like... jumprope?"
    },
}

return item