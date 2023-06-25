---@class Rectangle : Object
---@overload fun(...) : Rectangle
local Rectangle, super = Class(Object)

function Rectangle:init(x, y, width, height)
    super.init(self, x, y)
    self.width = width
    self.height = height
    self.color = {1, 1, 1}

    self.line = false
    self.line_width = 1
end

function Rectangle:draw()
    love.graphics.setLineWidth(self.line_width)
    love.graphics.rectangle(self.line and "line" or "fill", 0, 0, self.width, self.height)

    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return Rectangle