local item, super = Class(LightEquipItem, "light/blackshard")

function item:init()
    super.init(self)

    -- Display name
    self.name = "BlackShard"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A small chip of extremely hard glass.\nOddly, it's nearly opaque."

    -- Light world check text
    self.check = "A small chip of extremely hard glass.\n* Oddly,[wait:5] it's nearly opaque."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 16,
        defense = 0
    }

    -- Default dark item conversion for this item
    self.dark_item = "blackshard"
end

return item