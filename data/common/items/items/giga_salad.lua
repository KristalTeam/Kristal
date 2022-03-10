local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "giga_salad",
    -- Display name
    name = "GigaSalad",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n4HP",
    -- Shop description
    shop = "",
    -- Menu description
    description = "An enormous salad... but, it's just\nlettuce, so it's worthless. +4HP",

    -- Amount healed (HealItem variable)
    heal_amount = 0,
	
	-- Custom variable for this item, determines the healing value for each character.
	heal_variants = {
		["kris"] = 4, 
		["susie"] = 4, 
		["ralsei"] = 4, 
		["noelle"] = 90
	},

    -- Shop sell price
    price = 5,

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
		susie = "Why this!?",
        ralsei = "Let's be healthy!",
        noelle = "Something to graze on!"
	},
}

function item:onWorldUse(target)
	if item.heal_variants[target.id] ~= nil then
		item.heal_amount = item.heal_variants[target.id]
	else
		item.heal_amount = item.heal_variants["kris"]
	end
    Game.world:heal(target, item.heal_amount)
    return true
end

function item:onBattleUse(user, target)
	if item.heal_variants[target.chara.id] ~= nil then
		item.heal_amount = item.heal_variants[target.chara.id]
	else
		item.heal_amount = item.heal_variants["kris"]
	end
    target:heal(item.heal_amount)
end

return item