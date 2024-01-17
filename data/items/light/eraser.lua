local item, super = Class(LightEquipItem, "light/eraser")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Eraser"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "Pink, it bounces when thrown on the ground."

    -- Light world check text
    self.check = "Weapon 1 AT\n* Pink,[wait:5] it bounces when thrown on the ground."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 1,
        defense = 0
    }

    -- Default dark item conversion for this item
    self.dark_item = "bounceblade"
end

return item