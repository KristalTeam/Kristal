local item, super = Class(HealItem, "flatsoda")

function item:init()
    super.init(self)

    -- Display name
    self.name = "FlatSoda"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n20HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Flat soda someone already took\na big sip from. Recovers 20HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 20

    -- Default shop price (sell price is halved)
    self.price = 2
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
        susie = "Fine, I'll finish it.",
        ralsei = "Aw, you saved me half?",
        noelle = "(Whatever, it's just Kris's...)"
    }
end

return item