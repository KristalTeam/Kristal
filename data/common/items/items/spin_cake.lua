local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "spin_cake",
    -- Display name
    name = "SpinCake",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\nteam\n~1HP",
    -- Shop description
    shop = "",
    -- Menu description
    description = "A pastry in the shape of a top.\nHeals ~1 HP to the team.",

    -- Amount healed (HealItem variable)
    heal_amount = 80,

    -- Shop sell price
    price = 3,

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
		attack = 0,
	},
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions (key = party member id)
    reactions = {
		susie = "I'm dizzy.",
        ralsei = "Mmm, thank you!",
        noelle = "My eyes are spinning..."
	},
}

if Game.chapter == 1 then
	item.heal_amount = 80
else
	item.heal_amount = 140
end
item.description = string.gsub(item.description, "(~1)", tostring(item.heal_amount))
item.effect = string.gsub(item.effect, "(~1)", tostring(item.heal_amount))

function item:onWorldUse(target)
	for i=1, #Game.party do
		Game.world:heal(Game.party[i], item.heal_amount)
	end
    return true
end

function item:onBattleUse(user, target)
	for i=1, #Game.battle.party do
		Game.world:heal(Game.battle.party[i], item.heal_amount)
	end
end

return item