-- Create a healing item and specify its ID (id is optional, defaults to file path)
local item, super = Class(HealItem, "test_food")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Test Food"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n100HP"
    -- Shop description
    self.shop = "Example\nfood\nheals 100HP"
    -- Menu description
    self.description = "Example food. +100HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 100

    -- Default shop price (sell price is halved)
    self.price = 0
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
    self.reactions = {}
end

-- Function overrides go here

return item