local item, super = Class(Item, "o_glove")

function item:init()
    super.init(self)

    -- Display name
    self.name = "O.Glove"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/glove"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "The glove of a brave fighter.\nSusie's SCYTHEMARE will cost less TP. "

    -- Default shop price (sell price is halved)
    self.price = 2
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
        attack = 4,
        defense = 8
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "ScytheTP-"
    self.bonus_icon = "ui/menu/icon/down"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = false,
        ralsei = false
    }

    -- Character reactions
    self.reactions = {
        susie = "Helps me hold the axe.",
        ralsei = "Um... I need training, first.",
        noelle = "I'm used to gloves. I mean, um, oven mitts.",
    }
end

return item
