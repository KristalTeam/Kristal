local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "choc_diamond",
    -- Display name
    name = "ChocDiamond",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Healing\nvaries",
    -- Shop description
    shop = "",
    -- Menu description
    description = "It's quite small, but some\npeople REALLY like it. +??HP",

    -- Amount healed (HealItem variable)
    heal_amount = 0,	
    -- Custom variable for this item, determines the healing value in the overworld for each character.
    heal_variants_overworld = {
        ["kris"] = 80, 
        ["susie"] = 20, 
        ["ralsei"] = 50, 
        ["noelle"] = 70
    },	
    -- Custom variable for this item, determines the healing value in the battle for each character.
    heal_variants_battle = {
        ["kris"] = 80, 
        ["susie"] = 20, 
        ["ralsei"] = 50, 
        ["noelle"] = 70
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
        susie = "THAT'S it?",
        ralsei = "Aww, thanks, Kris!",
        noelle = "Umm, it's ok, Kris, I'll share..."
    },
}

function item:onWorldUse(target)
    if item.heal_variants_overworld[target.id] ~= nil then
        if Game.party[1].id == "kris" and target.id == "noelle" then
            Game.world:heal(Game.party[1], item.heal_amount)
            item.heal_variants_overworld["noelle"] = 35
        end
        item.heal_amount = item.heal_variants_overworld[target.id]
    else
        item.heal_amount = item.heal_variants_overworld["kris"]
    end
    Game.world:heal(target, item.heal_amount)
    item.heal_variants_overworld["noelle"] = 70
    return true
end

function item:onBattleUse(user, target)
    if Game.chapter == 1 then
        item.heal_variants_battle = { ["kris"] = 80, ["susie"] = 30, ["ralsei"] = 30, ["noelle"] = 50 }
    else
        item.heal_variants_battle = { ["kris"] = 80, ["susie"] = 20, ["ralsei"] = 50, ["noelle"] = 70 }
    end
    if item.heal_variants_battle[target.chara.id] ~= nil then
        item.heal_amount = item.heal_variants_battle[target.chara.id]
    else
        item.heal_amount = item.heal_variants_battle["kris"]
    end
    target:heal(item.heal_amount)
end

return item