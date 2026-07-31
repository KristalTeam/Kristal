local item, super = Class(Item, "light/seeds")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Seeds"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "The seed of the golden flower."

    -- Light world check text
    self.check = "The seed of the golden flower."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
end

return item
