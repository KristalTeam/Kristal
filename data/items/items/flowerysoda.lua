local item, super = Class(HealItem, "flowerysoda")

function item:init()
    super.init(self)

    -- Display name
    self.name = "FlowerySoda"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Raises\nTP 16%\n+50HP"
    -- Shop description
    self.shop = "Ralsei's\nobvious\nfavorite\n+50HP? +16TP"
    -- Menu description
    self.description = "Embarrassingly white lactose flavor.\nSaid to be Ralsei's favorite on the bottle."

    -- Amount healed (HealItem variable)
    self.heal_amount = 50
    -- Amount this item heals for specific characters
    self.heal_amounts = {
        ["ralsei"] = 200 -- Only applied in battle
    }
    -- Amount of TP this item gives
    self.tp_amount = 16

    -- Default shop price (sell price is halved)
    self.price = 222
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Character reactions (key = party member id)
    self.reactions = {
        susie = "Eww, Ralsei likes lactose?",
        ralsei = "I... I'm not thirsty.",
        noelle = "........ who the heck is Flowery?"
    }
end

function item:onWorldUse(target)
    -- Ralsei does not drink the FlowerySoda.
    if target.id == "ralsei" then
        return false
    end

    return super.onWorldUse(self, target)
end

-- Functions copied from TensionItem

function item:onBattleSelect(user, target)
    self.tension_given = Game:giveTension(self.tp_amount)

    Assets.playSound("cardrive", 0.8, 1.4)

    user:flash()
    user:sparkle(1, 0.625, 0.25)
end

function item:onBattleDeselect(user, target)
    Game:removeTension(self.tension_given or 0)
end

return item
