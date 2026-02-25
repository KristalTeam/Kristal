local item, super = Class(Item, "flexscarf")

function item:init()
    super.init(self)

    -- Display name
    self.name = "FlexScarf"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Weaklings\ncan flex too"
    -- Menu description
    self.description = "A scarf that is warm and fuzzy, but with\na metal core that lets it keep its shape."

    -- Default shop price (sell price is halved)
    self.price = Game.chapter <= 3 and 620 or 720
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
        magic = 1,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        ralsei = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Looks like a giant caterpillar.  ", -- The whitespace is intentional?
        ralsei = "So pliable, like me!",
        noelle = "Twist it and... it's a wreath!",
    }
end

return item