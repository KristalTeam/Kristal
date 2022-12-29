local item, super = Class(Item, "daintyscarf")

function item:init()
    super.init(self)

    -- Display name
    self.name = "DaintyScarf"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Homemade\nHealing up"
    -- Menu description
    self.description = "Delicate scarf that increases healing\npower but has no attack."

    -- Default shop price (sell price is halved)
    self.price = 200
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
        magic = 2,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Fluffiness UP"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        ralsei = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "IT'S MADE OF DOILIES!",
        ralsei = "I'll protect everyone!",
        noelle = "S-stop covering me with it!",
    }
end

return item