local item, super = Class(HealItem, "shikacola")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Shikacola"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\nteam\n80HP"
    -- Shop description
    self.shop = "Natural\nungulate\ntaste\n+80HP to all"
    -- Menu description
    self.description = "A natural drink infused with nutmeg and\ndeer hair. Heals all party members. +80HPall"

    -- Amount healed (HealItem variable)
    self.heal_amount = 80
    -- Amount this item heals for specific characters in the overworld
    self.world_heal_amounts = {
        ["noelle"] = 5
    }

    -- Default shop price (sell price is halved)
    self.price = 222
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
        susie = "Noelle... should try this.",
        ralsei = "Let's save some for her?",
        noelle = "WHY WOULD I LIKE THIS??? IT HAS SOMEONE'S HAIR IN IT???"
    }
end

return item
