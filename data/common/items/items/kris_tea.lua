local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "kris_tea",
    -- Display name
    name = "Kris Tea",
    -- Custom variable for this item to determine the owner of the tea.
    owner = "kris",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Healing\nvaries",
    -- Shop description
    shop = "",
    -- Menu description
    description = "It's own-flavored tea.\nThe flavor just says \"Kris.\"",

    -- Amount healed (HealItem variable)
    heal_amount = 0,
    -- Custom variable for this item, determines the healing value for each character.
    heal_variants = {
        ["kris"] = 10, 
        ["susie"] = 120, 
        ["ralsei"] = 120, 
        ["noelle"] = 70,
        ["thrash"] = 100
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
        kris = {
            susie = "(No reaction?)",
            noelle = "(... no reaction?)",		
        },
        susie = {
            susie = "Hell yeah, apple juice!!",
            ralsei = "Don't drink so fast!!",	
        },	
        ralsei = {
            susie = "Huh? Really?",
            ralsei = "Tastes like blueberries!",	
        },
        noelle = "Tastes like cinnamon! (What is this aftertaste...?)"
    },
}

function item:onWorldUse(target)
    if item.heal_variants[target.id] ~= nil then
        item.heal_amount = item.heal_variants[target.id]
    else
        item.heal_amount = item.heal_variants["thrash"]
    end
    Game.world:heal(target, item.heal_amount)
    return true
end

function item:onBattleUse(user, target)
    if item.heal_variants[target.chara.id] ~= nil then
        if target.chara.id == item.owner then
            item.heal_variants[item.owner] = 40
        end	
        item.heal_amount = item.heal_variants[target.chara.id]
    else
        item.heal_amount = item.heal_variants["thrash"]
    end
    target:heal(item.heal_amount)
    item.heal_variants[item.owner] = 10
end

return item