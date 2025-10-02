local item, super = Class(Item, "gingerguard")

function item:init()
    super.init(self)

    -- Display name
    self.name = "GingerGuard"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/cookie_cutter"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Fragrant\narmor"
    -- Menu description
    self.description = "A steel bangle tempered by extreme flame.\nIts shape is humanoid in nature."

    -- Default shop price (sell price is halved)
    self.price = 862
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
        defense = 3,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Look! I punched through a guy!",
        ralsei = "A bigger one could make Kris!",
        noelle = "This smells amazing! Um, sorry.",
    }
end

return item