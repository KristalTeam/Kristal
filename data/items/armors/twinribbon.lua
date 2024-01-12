local item, super = Class(Item, "twinribbon")

function item:init()
    super.init(self)

    -- Display name
    self.name = "TwinRibbon"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Two ribbons. You'll have to put\nyour hair into pigtails."

    -- Default shop price (sell price is halved)
    self.price = 400
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

        graze_size = 0.2,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "GrazeArea"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = false
    }

    -- Character reactions
    self.reactions = {
        susie = "... it gets worse and worse.",
        ralsei = "Try around my horns!",
        noelle = "... nostalgic, huh.",
    }
end

return item