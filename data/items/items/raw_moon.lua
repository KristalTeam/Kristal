local item, super = Class(HealItem, "raw_moon")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Raw Moon"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Raises\nTP 16%\n+100HP"
    -- Shop description
    self.shop = "Dubiously\npronounced\nsky soda\n+100HP? +16TP"
    -- Menu description
    self.description = "A bubbly liquid in a sweet floral blue.\n+Slight%TP, +100HP unless you like it more."

    -- Amount healed (HealItem variable)
    self.heal_amount = 100
    -- Amount this item heals for specific characters
    self.heal_amounts = {
        ["kris"] = 200
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
        susie = "Can't get the marble.",
        ralsei = "How do I recycle this?",
        noelle = "(Are they, pronouncing it wrong on purpose?)"
    }
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
