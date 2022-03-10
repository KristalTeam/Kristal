local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "hearts_donut",
    -- Display name
    name = "HeartsDonut",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Healing\nvaries",
    -- Shop description
    shop = "",
    -- Menu description
    description = "Hearts, don't it!? It's filled with\ndivisive, clotty red jam. +??HP",

    -- Amount healed (HealItem variable)
    heal_amount = 0,
	
	-- Custom variable for this item, determines the healing value in the overworld for each character.
	heal_variants_overworld = {
		["kris"] = 20, 
		["susie"] = 80, 
		["ralsei"] = 50, 
		["noelle"] = 30
	},
	-- Custom variable for this item, determines the healing value in the battle for each character.
	heal_variants_battle = {
		["kris"] = 20, 
		["susie"] = 80, 
		["ralsei"] = 50, 
		["noelle"] = 30
	},

    -- Shop sell price
    price = 20,

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
		susie = "Mmm, blood!",
        ralsei = "Aah, sticky...",
        noelle = "Mmm... what!? It's blood!?"
	},
}

function item:onWorldUse(target)
	if item.heal_variants_overworld[target.id] ~= nil then
		item.heal_amount = item.heal_variants_overworld[target.id]
	else
		item.heal_amount = item.heal_variants_overworld["kris"]
	end
    Game.world:heal(target, item.heal_amount)
    return true
end

function item:onBattleUse(user, target)
	if Game.chapter == 1 then
		item.heal_variants_battle = { ["kris"] = 10, ["susie"] = 90, ["ralsei"] = 60, ["noelle"] = 40 }
	else
		item.heal_variants_battle = { ["kris"] = 20, ["susie"] = 80, ["ralsei"] = 50, ["noelle"] = 30 }
	end
	if item.heal_variants_battle[target.chara.id] ~= nil then
		item.heal_amount = item.heal_variants_battle[target.chara.id]
	else
		item.heal_amount = item.heal_variants_battle["kris"]
	end
    target:heal(item.heal_amount)
end

return item