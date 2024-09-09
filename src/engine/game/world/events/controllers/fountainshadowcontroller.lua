--- Creates dark fountain shadows for all characters when present in a map (intended for use with [DarkFountain](lua://DarkFountain.init)). \
--- `FountainShadowController` is a `controller` - naming an object `fountainshadow` on a `controllers` layer in a map creates this object.
--- 
---@class FountainShadowController : Event
---
---@field stage Stage
---
---@overload fun(...) : FountainShadowController
local FountainShadowController, super = Class(Event, "fountainshadow")

function FountainShadowController:init(properties)
    super.init(self)
end

function FountainShadowController:update()
    super.update(self)

    if not self.stage then return end

    for _,chara in ipairs(self.stage:getObjects(Character)) do
        if not chara.no_shadow and not chara:getFX("shadow") then
            chara:addFX(FountainShadowFX(), "shadow")
        end
    end
end

return FountainShadowController