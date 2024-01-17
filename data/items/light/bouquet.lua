local item, super = Class(Item, "light/bouquet")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Bouquet"

    -- Item type (item, key, weapon, armor)
    self.type = "key"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A bouquet of beautiful flowers in many colors."

    -- Light world check text
    self.check = "A bouquet of beautiful flowers in many colors."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
end

function item:onWorldUse()
    Game.world:showText("* You held out the flowers.[wait:5]\n* A floral scent fills the air.[wait:5]\n* Nothing happened.")
    return false
end

return item