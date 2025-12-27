local item, super = Class(HealItem, "tvslop")

function item:init()
    super.init(self)

    -- Display name
    self.name = "TVSlop"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n80HP"
    -- Shop description
    self.shop = "Full of\nnutrient\nHP+80"
    -- Menu description
    self.description = "Some sort of bland cafeteria food.\nThe ice cream cone is soggy and saggy."

    -- Amount healed (HealItem variable)
    self.heal_amount = 80

    -- Default shop price (sell price is halved)
    self.price = Game.chapter <= 3 and 180 or 200
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
        susie = "Like my old school.",
        ralsei = "Is this legal?",
        noelle = "Here, I refreezed it!"
    }
end

return item