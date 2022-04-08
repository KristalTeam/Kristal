local item, super = Class(Item, "silver_watch")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Silver Watch"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Holiday\nthemed"
    -- Menu description
    self.description = "Grazing bullets affects\nthe turn length by 10% more"

    -- Shop sell price
    self.price = 100

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = nil
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        defense = 2
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "GrazeTime"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "It's clobbering time.",
        ralsei = "I'm late, I'm late!",
        noelle = "(Th-this was mine...)",
    }
end

return item