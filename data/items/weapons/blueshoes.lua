local item, super = Class(Item, "blueshoes")

function item:init()
    super.init(self)

    -- Display name
    self.name = "BlueShoes"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/shoe"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Shoes from a prestigious dancer.\nRalsei's PACIFY costs 0% TP."

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
        attack = 2,
        defense = 4,
        magic = 6
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Pacify0TP"
    self.bonus_icon = "ui/menu/icon/sleep"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        ralsei = true
    }

    -- Character reactions
    self.reactions = {
        susie = "Hell no, I'd wreck these.",
        ralsei = "Helps me step to attack!",
        noelle = "(You KNOW I can't wear normal shoes...)"
    }
end

return item
