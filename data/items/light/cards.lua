local item, super = Class(Item, "light/cards")

function item:init(inventory)
    super.init(self)

    -- Display name
    self.name = "Cards"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "The Jack of Spades, and the Rules Card."

    -- Light world check text
    self.check = "The Jack of Spades,[wait:5]\nand the Rules Card."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    
end

function item:onWorldUse()
    Game.world:showText("* You held the cards.[wait:5]\n* They felt flimsy between your\nfingers.")
    return false
end

function item:onToss()
    Game.world:showText("* (You fumbled and caught them.[wait:5]\nYou can't throw these away!)")
    return false
end

return item