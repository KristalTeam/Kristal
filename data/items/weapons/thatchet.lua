local item, super = Class(Item, "thatchet")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Thatchet"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/axe"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "An axe made of brambles. It's rumored its\nwickedness infects anything it touches."

    -- Default shop price (sell price is halved)
    self.price = 1000
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
        attack = 10
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Wicked"
    self.bonus_icon = "ui/menu/icon/demon"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = true
    }

    -- Character reactions
    self.reactions = {
        susie = "Literally wicked.",
        ralsei = "Yay, I'm infected!",
        noelle = "Well... roses have thorns, too.",
    }
end

return item
