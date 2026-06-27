local item, super = Class(HealItem, "flavigne")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Flavigne"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n130HP"
    -- Shop description
    self.shop = "Fragrant\npellet\n\n\nHeals 130HP"
    -- Menu description
    self.description = "A small white candy in various floral flavors.\nRumored to have been a bullet pattern. +130HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 130

    -- Default shop price (sell price is halved)
    self.price = 333
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
        susie = "Why don't we eat bullets more?",
        ralsei = "Mmm, friendly pellets.",
        noelle = "(Stop pretending it's an attack...)"
    }
end

return item
