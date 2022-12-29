local item, super = Class(Item, "devilsknife")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Devilsknife"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/axe"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Skull-emblazoned scythe-ax.\nReduces Rudebuster's cost by 10"

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
        attack = 5,
        magic  = 4,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Buster TP DOWN"
    self.bonus_icon = "ui/menu/icon/down"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Let the games begin!",
        ralsei = "It's too, um, evil.",
        noelle = "...? It smiled at me?",
    }
end

return item