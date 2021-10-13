local ShadedChar = Class(TextChar)

function ShadedChar:draw()
    local shader = Kristal.Shaders["GradientV"]

    local last_shader = love.graphics.getShader()
    love.graphics.setShader(shader)

    local draw_color = {self:getDrawColor()}

    local white = draw_color[1] == 1 and draw_color[2] == 1 and draw_color[3] == 1

    shader:send("from", white and COLORS.dkgray or draw_color)
    shader:send("to", white and COLORS.navy or draw_color)
    love.graphics.setColor(1, 1, 1, white and 1 or 0.3)
    love.graphics.draw(self.texture, 1, 1)

    shader:send("from", COLORS.white)
    shader:send("to", white and COLORS.white or draw_color)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.texture)

    love.graphics.setShader(last_shader)

    self:drawChildren()
end

return ShadedChar