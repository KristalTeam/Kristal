local item, super = Class(Item, "glowshard")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Glowshard"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Sell\nat\nshops"
    -- Shop description
    self.shop = ""
    -- Menu description
    if Game.chapter == 1 then
        self.description = "A shimmering shard.\nIts use is unknown."
    else
        self.description = "A shimmering shard.\nIts value increases each Chapter."
    end

    -- Shop buy price
    if Game.chapter == 1 then
        self.buy_price = 200
    else
        self.buy_price = 200 + (Game.chapter * 100)
    end
    -- Shop sell price (usually half of buy price)
    self.sell_price = self.buy_price / 2

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = "noselect"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "battle"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 0,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {}
end

function item:onWorldUse(target)
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume (it will taste bad)
    return false
end

function item:getBattleText(user, target)
    if Game.battle.encounter.onGlowshardUse then
        return Game.battle.encounter:onGlowshardUse(user)
    end
    return {"* "..user.chara.name.." used the GLOWSHARD!", "* But nothing happened..."}
end

return item