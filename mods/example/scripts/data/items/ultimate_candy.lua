-- Instead of Item, create a HealItem, a convenient class for consumable healing items
local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "ultimate_candy",
    -- Display name
    name = "UltimatCandy",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Best\nhealing",
    -- Shop description
    shop = "Perfection",
    -- Menu description
    description = "Sparkles with perfection.\nMust be shared with everyone. +??HP",

    -- Amount healed (HealItem variable)
    heal_amount = 1,

    -- Shop sell price
    price = 100,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "none",
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
        susie = "Hey! It's hollow inside!",
        ralsei = "I like the texture!",
        noelle = "That was underwhelming..."
    }
}

return item