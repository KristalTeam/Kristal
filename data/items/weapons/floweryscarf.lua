local item, super = Class(Item, "floweryscarf")

function item:init()
    super.init(self)

    -- Display name
    self.name = "FloweryScarf"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A scarf which says \"I <3 Flowery\" on it.\nIt's the perfect size for Ralsei."

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
        attack = 70,
        defense = 70,
        magic = 70
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "TheBest"
    self.bonus_icon = "ui/menu/icon/flowery"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Nah, that's for Ralsei.",
        ralsei = "I, um... it, it doesn't fit!",
        noelle = "Who the heck is Flowery?"
    }
end

return item
