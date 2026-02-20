local item, super = Class(Item, "toxicaxe")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ToxicAxe"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/axe"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Smelly\nweapon"
    -- Menu description
    self.description = "An axe used to clear wastelands\nin a fetid swamp. Not poison, but gross."

    -- Default shop price (sell price is halved)
    self.price = Game.chapter <= 3 and 600 or 700
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
        attack = 6,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Eat dirt, losers.",
        ralsei = "Could I wash it off first?",
        noelle = "N-no way! Susie wouldn't use that!",
    }
end

return item