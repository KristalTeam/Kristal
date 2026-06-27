local item, super = Class(HealItem, "treecake")

function item:init()
    super.init(self)

    -- Display name
    self.name = "TreeCake"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\nteam\n160HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A cake of bread laden with joyful memories.\nRecovers 160 HP to all."

    -- Amount healed (HealItem variable)
    self.heal_amount = 160

    -- Default shop price (sell price is halved)
    self.price = 200
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
        -- Susie with flag 1514 set: "Mmm, Ralsei's cake."
        susie = "Mmm, dark candy.",
        ralsei = "Mmm, cotton candy.",
        noelle = "Mmm, water bubbler. I mean, fruitcake."
    }
end

return item
