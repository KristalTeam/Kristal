local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "light_candy",
    -- Display name
    name = "LightCandy",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n120HP",
    -- Shop description
    shop = nil,
    -- Menu description
    description = "White candy with a chalky texture.\nIt'll recover 120HP.",

    -- Amount healed (HealItem variable)
    heal_amount = 120,

    -- Shop sell price
    price = 100,

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
        susie = "Hey, this rules!",
        ralsei = "Nice and chalky.",
        noelle = "(I-isn’t this the chalk I gave her?)"
    }
}

return item