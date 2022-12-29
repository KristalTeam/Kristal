---@class FountainShadowController : Event
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