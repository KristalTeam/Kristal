local item, super = Class(LightEquipItem, "light/petal")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Petal"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A cyan colored petal. It's not a weapon, but it's nice."

    -- Light world check text
    self.check = "0 AT\n* A cyan colored petal.[wait:5] It's not\na weapon,[wait:5] but it's nice."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 0,
        defense = 0
    }

    -- Default dark item conversion for this item
    self.dark_item = "aquaknife"
end

return item
