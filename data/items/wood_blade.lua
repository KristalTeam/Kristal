return {
    -- Item ID (optional, defaults to path)
    id = "wood_blade",
    -- Display name
    name = "Wood Blade",

    -- Item type (item, key, weapon, armor)
    type = "weapon",
    -- Item icon (for equipment)
    icon = "ui/menu/icon/sword",

    -- Battle description
    effect = "",
    -- Shop description
    shop = "Practice\nblade",
    -- Menu description
    description = "A wooden practice blade with a carbon-\nreinforced core.",

    -- Shop sell price
    price = 60,

    -- Equip bonuses (for weapons and armor)
    bonuses = {
        attack = 0,
    },
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {
        kris = true,
    },

    -- Character reactions
    reactions = {
        susie = "What's this!? A CHOPSTICK?",
        ralsei = "That's yours, Kris...",
        noelle = "(It has bite marks...)",
    },
}