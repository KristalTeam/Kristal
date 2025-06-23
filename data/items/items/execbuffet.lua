local item, super = Class(HealItem, "execbuffet")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ExecBuffet"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\nteam\n100HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A dinner for cushy TV executives.\nThe blue \"caviar\" is unforgettable."

    -- Amount healed (HealItem variable)
    self.heal_amount = 100

    -- Default shop price (sell price is halved)
    self.price = 600
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "party"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Character reactions (key = party member id)
    self.reactions = {
		susie = "Rich people eat THIS?",
		ralsei = "P... pinky up!",
		noelle = "Caviar AGAIN?"
	}
end

return item