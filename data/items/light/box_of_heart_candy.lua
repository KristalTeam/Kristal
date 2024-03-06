local item, super = Class(Item, "light/box_of_heart_candy")

function item:init(inventory)
    super.init(self)

    -- Display name
    self.name = "Box of Heart Candy"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A box of heart shaped candies. It's not yours."

    -- Light world check text
    self.check = "It's not\nyours.[wait:5] Will that stop you?."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    
end

function item:onWorldUse()
    Game.world:startCutscene(function(cutscene)
        if Game.party[1].lw_health <= 1 then
            Game:gameOver(Game.world.player.x, Game.world.player.y)
            return true
        else
            Game.party[1].lw_health = Game.party[1].lw_health - 1
        end
        cutscene:text("* (You unhesitatingly devoured\nthe box of heart shaped\ncandies.)")
        cutscene:text("* (Your guts are being\ndestroyed.)")
        cutscene:text("* (You accept this destruction as\npart of life...)")
    end)
    return true
end

function item:onToss()
    Game.world:startCutscene(function(cutscene)
        cutscene:text("* (The Box of Heart Candy was\nthrown away.)")
    end)
    return true
end

return item