local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "test_food",
    -- Display name
    name = "Test Food",

    -- Item type (item, key, weapon, armor)
    type = "item",

    -- Battle description
    effect = "Heals\n100HP",
    -- Shop description
    shop = "Example\nfood\nheals 100HP",
    -- Menu description
    description = "Example food. +100HP",

    -- Amount healed (HealItem variable)
    heal_amount = 100,

    -- Shop sell price
    price = 0,

    -- Consumable target mode (party, enemy, or none/nil)
    target = "party",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,

    -- Character reactions (key = party member id)
    reactions = {},
}

-- Function overrides go here

return item