local item, super = Class(Item, "princessrbn")

function item:init()
    super.init(self)

    -- Display name
    self.name = "PrincessRBN"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Elegant lace ribbon with gloves,\ndelicate enough to see through. +4 DEF +2 ATK"

    -- Default shop price (sell price is halved)
    self.price = 1234
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
        attack = 2,
        defense = 4,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Elegance"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = false,
    }

    -- Character reactions
    self.reactions = {
        susie = "Nah. Gloves don't fit.",
        ralsei = "Cute! (Gloves don't fit)",
        noelle = "Kris, you can wear the gloves!",
    }
end

return item