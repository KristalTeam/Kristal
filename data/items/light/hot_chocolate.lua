local item, super = Class(Item, "light/hot_chocolate")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Hot Chocolate"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "Topped with home-made marshmallows in the shape of bunnies."

    -- Light world check text
    self.check = "Topped with home-made marshmallows in the shape of bunnies."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
end

function item:onWorldUse()
    Assets.playSound("swallow")
    Game.world:showText("* You drank the hot chocolate.[wait:5]\n* It tasted wonderful.[wait:5]\n* Your throat tightened...")
    return true
end

return item