local item, super = Class(HealItem, "greentea")

function item:init()
    super.init(self)

    -- Display name
    self.name = "GreenTea"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n180HP"
    -- Shop description
    self.shop = "Tea made\nby Green\n\n\nHeals 180HP"
    -- Menu description
    self.description = "A sweet orange tea with a strong flavor of\ncardadad. Made by \"Green.\" +180HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 180

    -- Default shop price (sell price is halved)
    self.price = 777
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
        susie = "Man, Green did awesome.",
        ralsei = "Wow, Green did wonderfully!",
        noelle = "You mean cardamom?"
    }
end

return item
