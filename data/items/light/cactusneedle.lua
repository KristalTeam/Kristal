local item, super = Class(LightEquipItem, "light/cactusneedle")

function item:init()
    super.init(self)

    -- Display name
    self.name = "CactusNeedle"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "Ouch! ... It's somewhat sentimental in a way."

    -- Light world check text
    self.check = "2 AT\n* Ouch! ... It's somewhat sentimental in a way."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 2,
        defense = 0
    }

    -- Default dark item conversion for this item
    self.dark_item = "saber10"
end

return item