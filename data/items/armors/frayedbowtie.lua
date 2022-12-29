local item, super = Class(Item, "frayedbowtie")

function item:init()
    super.init(self)

    -- Display name
    self.name = "FrayedBowtie"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "EXCLUSIVE\nOFFICIAL\nSPAMTON"
    -- Menu description
    self.description = "An old bowtie. It seems to have\nlost much of its defensive value."

    -- Default shop price (sell price is halved)
    self.price = 100
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
        defense = 1,
        magic = 1,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = false,
    }

    -- Character reactions
    self.reactions = {
        susie = "Look. I have standards.",
        ralsei = "It's still wearable!",
        noelle = "(Reminds me of Asgore...)",
    }
end

function item:getShopDescription()
    -- Don't automatically add item type
    return self.shop
end

return item