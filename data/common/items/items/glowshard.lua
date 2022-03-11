local item = Item{
    -- Item ID (optional, defaults to path)
    id = "glowshard",
    -- Display name
    name = "Glowshard",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Sell\nat\nshops",
    -- Shop description
    shop = nil,
    -- Menu description
    description = "A shimmering shard.\nIts value increases each Chapter.",

    -- Shop sell price
    price = 100 + (Game.chapter * 50),

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "noselect",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "battle",
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
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume
    return false
end

function item:getBattleText(user, target)
    if Game.battle.encounter.onGlowshardUse then
        return Game.battle.encounter:onGlowshardUse(user)
    end
    return {"* "..user.chara.name.." used the GLOWSHARD!", "* But nothing happened..."}
end

return item