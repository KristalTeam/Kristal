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
    
    -- The items that will be given to you on inventory conversion (defaults to {"lancer", "rouxls_kaard"} when empty)
    self.cards = {}
end

function item:getName()
    if #self.cards == 1 then
        return "Card"
    else
        return super.getName(self)
    end
end

function item:getCheck()
    if TableUtils.contains(self.cards, "lancer") and not TableUtils.contains(self.cards, "rouxls_kaard") then
        return "The Jack of Spades."
    elseif not TableUtils.contains(self.cards, "lancer") and TableUtils.contains(self.cards, "rouxls_kaard") then
        return "The Rules Card."
    else
        return super.getCheck(self)
    end
end

function item:onWorldUse()
    if #self.cards == 1 then
        Game.world:showText("* You held the card.[wait:5]\n* It felt flimsy between your\nfingers.")
    else
        Game.world:showText("* You held the cards.[wait:5]\n* They felt flimsy between your\nfingers.")
    end
    return false
end

function item:onToss()
    if #self.cards == 1 then
        Game.world:showText("* (You fumbled and caught it.[wait:5]\nYou can't throw it away!)")
    else
        Game.world:showText("* (You fumbled and caught them.[wait:5]\nYou can't throw these away!)")
    end
    return false
end

function item:convertToDark(inventory)
    return #self.cards > 0 and self.cards or {"lancer", "rouxls_kaard"}
end

return item
