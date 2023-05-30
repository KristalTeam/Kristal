---@class ScissorFX : FXBase
---@overload fun(...) : ScissorFX
local ScissorFX, super = Class(FXBase)

function ScissorFX:init(x, y, w, h, priority)
    super.init(self, priority or 0)
    self.x, self.y, self.width, self.height = x, y, w, h
end

function ScissorFX:draw(texture)
    Draw.pushScissor()
    local ox, oy = self:getObjectBounds()
    Draw.scissor(self.x + ox, self.y + oy, self.width, self.height)
    Draw.draw(texture)
    Draw.popScissor()
end

return ScissorFX