local item, super = Class(Item, "light/honey_toast")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Honey Toast"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A food that a parent could eat."

    -- Light world check text
    self.check = "A food that a parent could eat."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
end

function item:onWorldUse()
    Game.world:showText("* (You held it up in the air.)")
    return false
end

return item
