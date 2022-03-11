local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "java_cookie",
    -- Display name
    name = "JavaCookie",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Healing\nvaries",
    -- Shop description
    shop = "",
    -- Menu description
    description = "A coffee-and-chocolate flavored cookie.\nWords spark out when you bite it.",

    -- Amount healed (HealItem variable)
    heal_amount = 0,	
    -- Custom variable for this item, determines the healing value for each character.
    heal_variants = {
        ["kris"] = 100, 
        ["susie"] = 90, 
        ["ralsei"] = 90, 
        ["noelle"] = 90,
		["default"] = 90
    },

    -- Shop sell price
    price = 80,

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
        susie = "It says GUTS!",
        ralsei = "It says Fluffy...",
        noelle = "I... I can't read these symbols..."
    },
}

function item:onWorldUse(target)
    if item.heal_variants[target.id] ~= nil then
        item.heal_amount = item.heal_variants[target.id]
    else
        item.heal_amount = item.heal_variants["default"]
    end
    Game.world:heal(target, item.heal_amount)
    return true
end

function item:onBattleUse(user, target)
    if item.heal_variants[target.chara.id] ~= nil then
        item.heal_amount = item.heal_variants[target.chara.id]
    else
        item.heal_amount = item.heal_variants["default"]
    end
    target:heal(item.heal_amount)
end

return item