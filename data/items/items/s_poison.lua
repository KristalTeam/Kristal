local item, super = Class(Item, "s_poison")

function item:init()
    super.init(self)

    -- Display name
    self.name = "S.POISON"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Hurts\nparty\nmember"
    -- Shop description
    self.shop = "ITEM\nITEM\nAFFECTS HP\nA LOT!\nTHE SMOOTH\nTASTE OF"
    -- Menu description
    self.description = "A strange concoction made of\ncolorful squares. Will poison you."

    -- Default shop price (sell price is halved)
    self.price = 110
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Ugh! ...tastes good?",
        ralsei = "Ow... er, thanks, Kris!",
        noelle = "(I'll... just pretend to drink it...)"
    }

    -- Amount the poison damages in the world
    self.world_poison_amount = 20

    -- Amount the poison heals in battle
    self.battle_heal_amount = 40
    -- Amount the poison damages in battle
    self.battle_poison_amount = 60
end

function item:getShopDescription()
    -- Don't automatically add item type
    return self.shop
end

function item:getBattleText(user, target)
    return "* "..user.chara:getName().." administered "..self:getUseName().."!"
end

function item:onWorldUse(target)
    if target.id == "noelle" then
        return true
    end
    target:setHealth(math.max(1, target:getHealth() - self.world_poison_amount))
    Assets.playSound("hurt")
    return true
end

function item:onBattleUse(user, target)
    target:heal(self.battle_heal_amount, {1, 0, 1})
    Assets.playSound("hurt")

    if target.poison_effect_timer then
        Game.battle.timer:cancel(target.poison_effect_timer)
    end

    local poison_left = self.battle_poison_amount
    target.poison_effect_timer = Game.battle.timer:every(10/30, function()
        if poison_left == 0 then
            return false
        end
        if target.chara:getHealth() > 1 then
            target.chara:setHealth(target.chara:getHealth() - 1)
            poison_left = poison_left - 1
        else
            poison_left = 0
            return false
        end
    end)
end

return item