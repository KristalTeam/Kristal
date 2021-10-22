return {
    -- Item ID (optional, defaults to path)
    id = "snow_ring",
    -- Display name
    name = "SnowRing",

    -- Item type (item, key, weapon, armor)
    type = "weapon",
    -- Item icon (for equipment)
    icon = "ui/menu/icon/ring",

    -- Battle description
    effect = "",
    -- Shop description
    shop = "Cool\nring",
    -- Menu description
    description = "A ring with the emblem of the\nsnowflake",

    -- Shop sell price
    price = 100,

    -- Equip bonuses (for weapons and armor)
    bonuses = {
        attack = 0,
    },
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {
        noelle = true,
    },

    -- Character reactions
    reactions = {
        susie = "Smells like Noelle",
        ralsei = "Are you... proposing?",
        noelle = "(Thank goodness...)",
    },
}