local item, super = Class(Item, "jingleblade")

function item:init()
    super.init(self)

    -- Display name
    self.name = "JingleBlade"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A lance-like sword with red-and-white stripes.\nPerfect for jousting."

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
        attack = 7,
        defense = 1,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Festive"
    self.bonus_icon = "ui/menu/icon/smile"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true,
        noelle = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Sleigh the bad guys.",
        ralsei = "Mmm! Minty and festive!",
        noelle = "What is this, a barber pole?",
    }
end

function item:convertToLightEquip(chara)
    return "light/holiday_pencil"
end

return item