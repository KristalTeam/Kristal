local item, super = Class(Item, "light/glass")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Glass"

    -- Item type (item, key, weapon, armor)
    self.type = "key"
    -- Whether this item is for the light world
    self.light = true

    -- Item description text (unused by light items outside of debug menu)
    self.description = "A shard of glass."

    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
end

function item:onWorldUse()
    if Kristal.callEvent(KRISTAL_EVENT.onShadowCrystal, self, true) then
        return
    elseif not self:getFlag("used_lw_no_party") and #Game.party == 1 and #Game.temp_followers == 0 then
        self:setFlag("used_lw_no_party", true)

        Game.world:showText({
            "* You looked through the glass.",
            "* For some strange reason,[wait:5] for\njust a brief moment...",
            "* You thought you saw through\nyour hand."
        })
    elseif not self:getFlag("used_none") then
        self:setFlag("used_none", true)

        Game.world:showText({
            "* You looked through the glass.",
            "* ...[wait:5] but nothing happened."
        })
    else
        Game.world:showText("* It doesn't seem very useful.")
    end
    return false
end

function item:onCheck()
    Game.world:showText({
        "* There is a small shard of\nsomething in your pocket.",
        "* It feels like glass, but..."
    })
end

function item:onToss()
    Game.world:showText({
        "* (You didn't quite understand\nwhy...)",
        "* (But, the thought of discarding\nit felt very wrong.)"
    })
    return false
end

function item:convertToDark(inventory)
    local shadow_crystal = inventory:addItem("shadowcrystal")
    shadow_crystal.flags = self.flags
    return true
end

return item