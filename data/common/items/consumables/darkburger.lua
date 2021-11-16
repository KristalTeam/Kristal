local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "darkburger",
    -- Display name
    name = "Darkburger",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n70HP",
    -- Shop description
    shop = "Mysterious\nhamburger\nheals 70HP",
    -- Menu description
    description = "A mysterious black burger made of...\nHey, this is just burnt! +70HP",

    -- Amount healed (HealItem variable)
    heal_amount = 70,

    -- Shop sell price
    price = 70,

    -- Consumable target mode (party, enemy, or none/nil)
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
        susie = "Cooked to perfection!",
        ralsei = "A bit burnt...?",
        noelle = "I-is this real meat...?"
    }
}

return item