local item, super = Class(Item, "greenapron")

function item:init()
    super.init(self)

    -- Display name
    self.name = "GreenApron"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/apron"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "The apron of a kind chef. The wearer\nrecovers 16% of their max HP after defending."

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
        defense = 7
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "DefendHeal"
    self.bonus_icon = "ui/menu/icon/magic"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Arright, back to cooking fire.",
        ralsei = "Horse devors, anyone?",
        noelle = "Kris, can you, um, tie the back for me...?",
    }
end

-- Effect handled in Battle:startProcessing and Battle:doGreenApronHeal

return item
