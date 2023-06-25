---@class RecolorFX : FXBase
---@overload fun(...) : RecolorFX
local RecolorFX, super = Class(FXBase)

function RecolorFX:init(r,g,b,a, priority)
    super.init(self, priority or -1)

    self.color = {r or 1, g or 1, b or 1, a or 1}
end

function RecolorFX:setColor(r,g,b,a)
    self.color = {r, g, b, a or 1}
end
function RecolorFX:getColor()
    return self.color[1], self.color[2], self.color[3], self.color[4] or 1
end

function RecolorFX:isActive()
    local r,g,b,a = self:getColor()
    return super.isActive(self) and (r ~= 1 or g ~= 1 or b ~= 1 or a ~= 1)
end

function RecolorFX:draw(texture)
    Draw.setColor(self.color)
    Draw.drawCanvas(texture)
end

return RecolorFX