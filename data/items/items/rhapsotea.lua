local item, super = Class(HealItem, "rhapsotea")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Rhapsotea"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n115HP"
    -- Shop description
    self.shop = "Tea made\nof chants,\nheals 115HP"
    -- Menu description
    self.description = "A smooth, silvery drink. It sounds like\nwhispered singing as it's poured. +115 HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 115

    -- Default shop price (sell price is halved)
    self.price = 250
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
		susie = "Sounds kinda like Noelle.",
		ralsei = "... the hymn of the prophecy.",
		noelle = "(... Kris would never join choir...)"
	}
end

return item