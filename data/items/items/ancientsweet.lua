-- Create a healing item and specify its ID (id is optional, defaults to file path)
local item, super = Class(HealItem, "ancientsweet")

function item:init()
    super.init(self)

    -- Display name
    self.name = "AncientSweet"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Kris only\n+400"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A chocolatey cone etched with arcane\nglyphs. Only Kris can eat it. +400 HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 400
    -- Amount healed for anyone other than Kris
    self.heal_amount_other = 40

    -- Default shop price (sell price is halved)
    self.price = 1000
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
        susie = "Ugh! How old is this?!",
        ralsei = "Aww Kris, y-your favorite...",
        noelle = "I'd... I'd rather eat meat..."
    }
end

function item:getHealAmount(id)
    if id == "kris" then
        return self.heal_amount
    else
        return self.heal_amount_other
    end
end

return item