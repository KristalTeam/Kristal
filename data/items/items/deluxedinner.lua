local item, super = Class(HealItem, "deluxedinner")

function item:init()
    super.init(self)

    -- Display name
    self.name = "DeluxeDinner"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n140HP"
    -- Shop description
    self.shop = "Classy\nmeal for\nbig shots\nHP+140"
    -- Menu description
    self.description = "A TV Dinner for high-ranking contestants.\nComes with detachable antennas. +140 HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 140

    -- Default shop price (sell price is halved)
    self.price = 600
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
		susie = "Look, I'm a roach.",
		ralsei = "I'm a comfy caterpillar!",
		noelle = "I'm, um, an alien?"
	}
end

return item