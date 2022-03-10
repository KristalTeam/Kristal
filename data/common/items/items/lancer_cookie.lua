local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "lancer_cookie",
    -- Display name
    name = "LancerCookie",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n50HP",
    -- Shop description
    shop = "",
    -- Menu description
    description = "A cookie shaped like Lancer's face.\nMaybe not a cookie. Heals ~1 HP?",

    -- Amount healed (HealItem variable)
    heal_amount = 50,

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
		susie = "Mmm... face",
        ralsei = "(uncomfortable)",
        noelle = "Umm, what is this? It's cute..."
	},
}

if Game.chapter == 1 then
	item.description = string.gsub(item.description, "(~1)", "5")
else
	item.description = string.gsub(item.description, "(~1)", "1")
end

function item:onWorldUse(target)
	if Game.chapter == 1 then
		item.heal_amount = 4
	else
		item.heal_amount = 1
	end
    Game.world:heal(target, item.heal_amount)
    return true
end

function item:onBattleUse(user, target)
	item.heal_amount = 50
    target:heal(item.heal_amount)
end

return item