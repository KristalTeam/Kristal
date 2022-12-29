local item, super = Class(Item, "cheerscarf")

function item:init()
    super.init(self)

    -- Display name
    self.name = "CheerScarf"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A scarf with colorful you-can-do-it\nimagery. Gains more TP from criticals." -- blatant lie

    -- Default shop price (sell price is halved)
    self.price = 250
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 1,
        magic  = 2,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Smiley"
    self.bonus_icon = "ui/menu/icon/smile"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        ralsei = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Smiley faces? Ecch.",
        ralsei = "You can do it!",
        noelle = "Now THIS is a tacky scarf! Faha!",
    }
end

return item