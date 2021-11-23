local item = Item{
    -- Item ID (optional, defaults to path)
    id = "manual",
    -- Display name
    name = "Manual",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Read\nout of\nbattle",
    -- Shop description
    shop = nil,
    -- Menu description
    description = "Ralsei's handmade book full of\nvarious tips and tricks.",

    -- Shop sell price
    price = nil,

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

    -- Character reactions
    reactions = {},
}

function item:onWorldUse(target)
    Game.world:startCutscene(function(cutscene)
        cutscene:text("* (You tried to read the manual,\nbut it was so dense it made\nyour head spin...)")
    end)
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume (ralsei will feel bad)
    return false
end

function item:getBattleText(user, target)
    if Game.battle.encounter.onManualUse then
        return Game.battle.encounter:onManualUse(user)
    end
    return {"* "..user.chara.name.." read the MANUAL!", "* But nothing happened..."}
end

return item