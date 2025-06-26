local item, super = Class(Item, "shadowmantle")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ShadowMantle"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Shadows slip off like water.\nGreatly protects against Dark and Star attacks."

    -- Default shop price (sell price is halved)
    self.price = 0
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
        defense = Game.chapter,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Dark/Star"
    self.bonus_icon = "ui/menu/icon/armor"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        noelle = false,
    }

    -- Character reactions
    self.reactions = {
        susie = "Hell yeah, what's this?",
        ralsei = "Sh-should I wear this...?",
        noelle = "No... it's for someone... taller.",
    }

    -- TODO: Elemental resistance
    -- Resists element 5 by 0.66
end

return item