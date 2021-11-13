local item = Item{
    -- Item ID (optional, defaults to path)
    id = "white_ribbon",
    -- Display name
    name = "White Ribbon",

    -- Item type (item, key, weapon, armor)
    type = "armor",
    -- Item icon (for equipment)
    icon = "ui/menu/icon/armor",

    -- Battle description
    effect = "",
    -- Shop description
    shop = "Enhances\ncuteness",
    -- Menu description
    description = "A crinkly hair ribbon that slightly\nincreases your defense.",

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
    bonus_name = "Cuteness",
    bonus_icon = "ui/menu/icon/up",

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {
        susie = false,
    },

    -- Character reactions
    reactions = {
        susie = "I said NO! C'mon already!",
        ralsei = "It's nice being dressed up...",
        noelle = "... feels familiar.",
    },
}

return item