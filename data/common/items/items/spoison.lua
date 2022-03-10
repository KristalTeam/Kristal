local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "spoison",
    -- Display name
    name = "S.POISON",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Hurts\nparty\nmember",
    -- Shop description
    shop = "ITEM\nITEM\nAFFECTS HP\nA LOT!\nTHE SMOOTH\nTASTE OF",
    -- Menu description
    description = "A strange concoction made of\ncolorful squares. Will poison you.",

    -- Amount healed (HealItem variable)
    heal_amount = 40,
    -- Custom variable for this item, determines the healing value for each character.
    heal_variants = {
        ["kris"] = -20, 
        ["susie"] = -20, 
        ["ralsei"] = -20, 
        ["noelle"] = 0
    },

    -- Shop sell price
    price = 55,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "party",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = false,

    -- Equip bonuses (for weapons and armor)
    bonuses = {},
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions (key = party member id)
    reactions = {
        susie = "Ugh! ...tastes good?",
        ralsei = "Ow... er, thanks, Kris!",
        noelle = "(I'll... just pretend to drink it...)"
    },
}

function item:onWorldUse(target)
    if item.heal_variants[target.id] ~= nil then
        item.heal_amount = item.heal_variants[target.id]
    else
        item.heal_amount = item.heal_variants["kris"]
    end
    if target.health > 20 then
        target.health = target.health + item.heal_amount
    else
        target.health = 1
    end
    if target.id ~= "noelle" then
        Assets.playSound("snd_hurt1")
    end
    return true
end

function item:onBattleUse(user, target)
    item.heal_amount = 40
    target:heal(item.heal_amount)	
    Game.battle.timer:every(0.25,
        function() 
            if target.chara.health > 1 then
                target.chara.health = target.chara.health - 1
            end
        end, 
    60)
end

function item:getBattleText(user, target)
    return "* "..user.chara.name.." administered the S.POISON!"
end

return item