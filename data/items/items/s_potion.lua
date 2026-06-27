local item, super = Class(HealItem, "s_potion")

function item:init()
    super.init(self)

    -- Display name
    self.name = "S.POTION"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\nparty\nmember"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "An energy drink collaborating with a certain car brand.\nRecovers 200 HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 200

    -- Default shop price (sell price is halved)
    self.price = 500
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
        susie = "Still kinda burns.",
        ralsei = "Um, is it caffeinated?",
        noelle = "This... is expired!"
    }
end

return item
