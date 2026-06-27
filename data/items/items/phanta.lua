local item, super = Class(HealItem, "phanta")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Phanta"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Raises\nTP 16%\n+100HP"
    -- Shop description
    self.shop = "Purple soda\nin hidden\nflavor\n+100HP? +16TP"
    -- Menu description
    self.description = "Grape-flavored phantasmagoria of a soda's dream.\n+Slight%TP, +100HP unless you like it more."

    -- Amount healed (HealItem variable)
    self.heal_amount = 100
    -- Amount this item heals for specific characters
    self.heal_amounts = {
        ["susie"] = 200
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
        susie = "Bought. With money. Hell yeah.",
        ralsei = "But, it's Susie's favorite...",
        noelle = "Look, Kris! Susie's venom! (drinks it) (drinks it)"
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
