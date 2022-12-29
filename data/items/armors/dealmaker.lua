local item, super = Class(Item, "dealmaker")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Dealmaker"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Fashionable pink and yellow glasses.\nGreatly increase $ gained, and...?"

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = false

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
        defense = 5,
        magic = 5,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "$ +30%"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Money, that's what I need.",
        ralsei = "Two pairs of glasses?",
        noelle = "(Seems... familiar?)",
    }
end

function item:applyMoneyBonus(gold)
    return gold * 1.3
end

return item