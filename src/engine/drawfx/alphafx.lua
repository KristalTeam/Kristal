---@class AlphaFX : FXBase
---@overload fun(...) : AlphaFX
local AlphaFX, super = Class(FXBase)

function AlphaFX:init(alpha, priority)
    super.init(self, priority or 100)

    self.alpha = alpha or 1
end

function AlphaFX:isActive()
    return super.isActive(self) and self.alpha ~= 1
end

function AlphaFX:draw(texture)
    Draw.setColor(1, 1, 1, self.alpha)
    Draw.drawCanvas(texture)
end

return AlphaFX