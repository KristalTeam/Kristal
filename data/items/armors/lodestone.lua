local item, super = Class(Item, "lodestone")

function item:init()
    super.init(self)

    -- Display name
    self.name = "LodeStone"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Gain more TP\nfrom bullets"
    -- Menu description
    self.description = "A lodestone token shaped like a snail's shell.\nEnemy bullets give a bit more TP."

    -- Default shop price (sell price is halved)
    self.price = 220
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
        defense = 2,

        graze_tp = 0.05,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "TPGain"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Escargot? ... escargross.",
        ralsei = "I have no opinions on snails!",
        noelle = "Did your mom eat the non-shell part?",
    }
end

return item