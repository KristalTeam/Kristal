local item, super = Class(HealItem, "orangejuice")

function item:init()
    super.init(self)

    -- Display name
    self.name = "OrangeJuice"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n80HP"
    -- Shop description
    self.shop = "Juice\nmade by\nOrange\n\nHeals 80HP"
    -- Menu description
    self.description = "Green juice made by a girl named \"Orange.\"\nA smoothie of aloe and citrine. +80HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 80

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
        susie = "Dude, this isn't orange.",
        ralsei = "The name and color don't match.",
        noelle = "You mean CITRUS? CITRUS, right? CITRUS?"
    }
end

return item
