local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "revivebrite",
    -- Display name
    name = "ReviveBrite",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Revives\nteam\n100%",
    -- Shop description
    shop = "",
    -- Menu description
    description = "A breakable mint that revives all\nfallen party members to 100% HP.",

    -- Amount healed (HealItem variable)
    heal_amount = 50,

    -- Shop sell price
    price = 2000,

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
        susie = "Don't throw mints at me!",
        ralsei = "It's minty!",
        noelle = "What are you throwing?"
    },
}

function item:onWorldUse(target)
    for i=1, #Game.party do
        Game.world:heal(Game.party[i], item.heal_amount)
    end
    Assets.stopAndPlaySound("snd_power")
    return true
end

function item:onBattleUse(user, target)
    for i=1, #Game.battle.party do
        local target = Game.battle.party[i]
        if target.chara.health <= 0 then           
            target:heal(math.abs(target.chara.health) + target.chara:getStat("health"))
        else
            target:heal(item.heal_amount)
        end
    end
end

return item