local Rectangle, super = Class(Object)

function Rectangle:init(x, y, width, height)
    super:init(self, x, y)
    self.width = width
    self.height = height
    self.color = {1, 1, 1, 1}
end

function Rectangle:draw()
    love.graphics.setColor(self.color)

    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1)
    self:drawChildren()
end

return Rectangle