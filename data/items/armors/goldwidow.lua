local item, super = Class(Item, "goldwidow")

function item:init()
    super.init(self)

    -- Display name
    self.name = "GoldWidow"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A spider made of gold. It gathers coins\ninto it, reducing $ gained."

    -- Default shop price (sell price is halved)
    self.price = 5000
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
        defense = 5,
        magic = 1,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "$ -10%"
    self.bonus_icon = "ui/menu/icon/down"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        noelle = false,
    }

    -- Character reactions
    self.reactions = {
        susie = "Spider on my head. K.",
        ralsei = "Itsy and/or bitsy!",
        noelle = "E-Ew! Kris, get that away!",
    }
end

function item:applyMoneyBonus(gold)
    return gold * 0.9
end

return item