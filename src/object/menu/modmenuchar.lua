local ModMenuChar = Class(TextChar)

function ModMenuChar:draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.draw(self.texture, 2, 2)

    love.graphics.setColor(self:getDrawColor())
    love.graphics.draw(self.texture)

    super:draw(self)
end

return ModMenuChar