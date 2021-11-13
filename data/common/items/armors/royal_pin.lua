local item = Item{
    -- Item ID (optional, defaults to path)
    id = "royal_pin",
    -- Display name
    name = "RoyalPin",

    -- Item type (item, key, weapon, armor)
    type = "armor",
    -- Item icon (for equipment)
    icon = "ui/menu/icon/armor",

    -- Battle description
    effect = "",
    -- Shop description
    shop = "Elegant\nbrooch",
    -- Menu description
    description = "A brooch engraved with Queen's face.\nCareful of the sharp part.",

    -- Shop sell price
    price = 1000,

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
        defense = 3,
        magic = 1,
    },
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions
    reactions = {
        susie = "ROACH? Oh, brooch. Heh.",
        ralsei = "I'm a cute little corkboard!",
        noelle = "Queen... gave this to me.",
    },
}

return item