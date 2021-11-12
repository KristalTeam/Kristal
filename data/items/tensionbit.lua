local item = Item{
    -- Item ID (optional, defaults to path)
    id = "tensionbit",
    -- Display name
    name = "TensionBit",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Raises\nTP\n32%",
    -- Shop description
    shop = "Raises\nTP\n32%",
    -- Menu description
    description = "Raises TP by 32% in battle.",

    -- Shop sell price
    price = 100,

    -- Consumable target mode (party, enemy, or none/nil)
    target = nil,
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = true,

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

function item:onBattleSelect(user, target)
    Game.battle.tension_bar:giveTension(80)

    user:flash()

    local sound = Assets.newSound("snd_cardrive")
    sound:setPitch(1.4)
    sound:setVolume(0.8)
    sound:play()

    Game.battle.timer:every(1/30, function()
        for i = 1, 2 do
            local x = user.x + ((love.math.random() * user.width) - (user.width / 2)) * 2
            local y = user.y - (love.math.random() * user.height) * 2
            local sparkle = HealSparkle(x, y)
            sparkle:setColor(1, 0.625, 0.25)
            user.parent:addChild(sparkle)
        end
    end, 4)
end

function item:onBattleDeselect(user, target)
    Game.battle.tension_bar:removeTension(80)
end

function item:onWorldUse(target)
    Cutscene.start((function()
        Cutscene.text("* (You felt tense.)")
        Cutscene.text("* (... try using it in battle.)")
    end))
    return false
end

return item