local item, super = Class(Item, "scarfmark")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ScarfMark"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Pagekeeper\nscarf DF+1"
    -- Menu description
    self.description = "A thin scarf with a deep sheen. Holy writing has\nbeen pressed into it, imbuing it with magic."

    -- Default shop price (sell price is halved)
    self.price = 900
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
        defense = 1,
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
        susie = {
            susie = "Heheh...",
            ralsei = "Don't write that on it!!"
        },
        ralsei = "I'll keep my place.",
        noelle = "Look, ribbon dancing!",
    }
end

return item