local item = Item{
    -- Item ID (optional, defaults to path)
    id = "amber_card",
    -- Display name
    name = "Amber Card",

    -- Item type (item, key, weapon, armor)
    type = "armor",
    -- Item icon (for equipment)
    icon = "ui/menu/icon/armor",

    -- Battle description
    effect = "",
    -- Shop description
    shop = "Defensive\ncharm",
    -- Menu description
    description = "A thin square charm that sticks\nto you, increasing defense.",

    -- Shop sell price
    price = 100,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = nil,
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = false,

    -- Equip bonuses (for weapons and armor)
    bonuses = {
        defense = 1,
    },
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions
    reactions = {
        susie = "... better than nothing.",
        ralsei = "It's sticky, huh, Kris...",
        noelle = "It's like a name-tag!",
    },
}

return item