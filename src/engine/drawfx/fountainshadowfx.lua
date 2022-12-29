---@class FountainShadowFX : ShadowFX
---@overload fun(...) : FountainShadowFX
local FountainShadowFX, super = Class(ShadowFX)

function FountainShadowFX:init(priority)
    super.init(self, 1, nil, 3, priority)

    self.shadow_offset = 2
end

function FountainShadowFX:getHighlight()
    local fountain = self.parent.stage and self.parent.stage:getObjects(DarkFountain)[1]
    if fountain then
        return fountain:getColor()
    else
        return 0, 0, 0, 0
    end
end

return FountainShadowFX