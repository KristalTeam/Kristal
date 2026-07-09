local item, super = Class(LightEquipItem, "light/pencil2")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Pencil2"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "It's a No. 2 Pencil. ... that doesn't make it any stronger."

    -- Light world check text
    self.check = "2 AT\n* It's a No. 2 Pencil.[wait:5] ...[wait:5] that\ndoesn't make it any stronger."

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
    self.dark_item = "woodblade2"
end

return item
