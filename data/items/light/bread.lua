local item, super = Class(Item, "light/bread")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Bread"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A loaf of bread. Tends to leave crumbs wherever it goes."

    -- Light world check text
    self.check = "A loaf of bread.[wait:5] Tends to leave crumbs wherever it goes."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
end

return item
