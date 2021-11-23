local item = Item{
    -- Item ID (optional, defaults to path)
    id = "revivemint",
    -- Display name
    name = "ReviveMint",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heal\nDowned\nAlly",
    -- Shop description
    shop = nil,
    -- Menu description
    description = "Heals a fallen ally to MAX HP.\nA minty green crystal.",

    -- Shop sell price
    price = 200,

    -- Consumable target mode (party, enemy, or none/nil)
    target = "party",
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
    reactions = {
        susie = {
            susie = "I'm ALIVE!!!",
            ralsei = "(You weren't dead)",
        },
        ralsei = {
            susie = "(Don't look it)",
            ralsei = "Ah, I'm refreshed!"
        },
        noelle = "Mints? I love mints!"
    },
}

function item:onWorldUse(target)
    Game.world:heal(target, 60)
    return true
end

function item:onBattleUse(user, target)
    if user.chara.health <= 0 then
        target:heal(math.abs(user.chara.health) + user.chara:getStat("health"))
    else
        target:heal(60)
    end
end

return item