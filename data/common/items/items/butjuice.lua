local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "butjuice",
    -- Display name
    name = "ButJuice",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n100HP",
    -- Shop description
    shop = "ITEM\nShort for\nButlerJuice\n+100HP",
    -- Menu description
    description = "It's short for ButlerJuice.\nIt changes color with temperature.",

    -- Amount healed (HealItem variable)
    heal_amount = 100,

    -- Shop sell price
    price = 100,

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
        susie = "Hell'd you call this?",
        ralsei = "I made this.",
        noelle = "B-Brainfreeze! ... kidding!"
    },
}

return item