local item, super = Class(Item, "tensionbit")

function item:init()
    super:init(self)

    -- Display name
    self.name = "TensionBit"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Raises\nTP\n32%"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Raises TP by 32% in battle."

    -- Shop buy price
    self.buy_price = 100
    -- Shop sell price (usually half of buy price)
    self.sell_price = 50

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = nil
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = true

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

function item:onBattleSelect(user, target)
    Game.battle.tension_bar:giveTension(32)

    user:flash()

    local sound = Assets.newSound("snd_cardrive")
    sound:setPitch(1.4)
    sound:setVolume(0.8)
    sound:play()

    user:sparkle(1, 0.625, 0.25)
end

function item:onBattleDeselect(user, target)
    Game.battle.tension_bar:removeTension(32)
end

function item:onWorldUse(target)
    Game.world:startCutscene(function(cutscene)
        cutscene:text("* (You felt tense.)")
        cutscene:text("* (... try using it in battle.)")
    end)
    return false
end

return item