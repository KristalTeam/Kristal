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
        ["noelle"] = 70,
        ["default"] = 50
    },	
    -- Custom variable for this item, determines the healing value in the battle for each character.
    heal_variants_battle = {
        ["kris"] = 80, 
        ["susie"] = 20, 
        ["ralsei"] = 50, 
        ["noelle"] = 70,
        ["default"] = 50
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
        ralsei = "Aww, thanks, "..Game.party[1].name.."!",
        noelle = "Umm, it's ok, Kris, I'll share..."
    },
}

function item:onWorldUse(target)
    -- Checks if Kris is present in the party.
    local kris_present = false
    local kris_id = 0
    for i=1, #Game.party do
        if Game.party[i].id == "kris" then
            kris_present = true
            kris_id = i
        end
    end
    if item.heal_variants_overworld[target.id] ~= nil then
        -- If Noelle is the one eating the ChocoDiamond and Kris is present, she will share it with them.
        if target.id == "noelle" then
            if kris_present then
                Game.world:heal(Game.party[kris_id], item.heal_amount)
                item.heal_variants_overworld["noelle"] = 35
                item.reactions.noelle = "Umm, it's ok, Kris, I'll share..."
            else -- Otherwise resets Noelle-related values
                item.heal_variants_overworld["noelle"] = 70
                item.reactions.noelle = "Delicious chocolate!"
            end
        end
        item.heal_amount = item.heal_variants_overworld[target.id]
    else
        item.heal_amount = item.heal_variants_overworld["default"]
    end
    Game.world:heal(target, item.heal_amount)
    Assets.stopAndPlaySound("snd_power")
    return true
end

function item:onBattleUse(user, target)
    if item.heal_variants_battle[target.chara.id] ~= nil then
        item.heal_amount = item.heal_variants_battle[target.chara.id]
    else
        item.heal_amount = item.heal_variants_battle["default"]
    end
    target:heal(item.heal_amount)
end

return item