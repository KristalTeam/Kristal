---@class Ellipse : Object
---@overload fun(...) : Ellipse
local Ellipse, super = Class(Object)

function Ellipse:init(x, y, rx, ry)
    super.init(self, x, y, rx*2, (ry or rx)*2)
    self:setOrigin(0.5, 0.5)
    self.color = {1, 1, 1}
end

function Ellipse:draw()
    love.graphics.ellipse("fill", self.width/2, self.height/2, self.width/2, self.height/2)

    love.graphics.setColor(1, 1, 1, 1)
    super.draw(self)
end

return Ellipse