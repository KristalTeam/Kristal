local ShadedChar, super = Class(TextChar)

function ShadedChar:init(char, x, y, font, color)
    super:init(self, char, x, y, font, color)

    self.cache = true
    self.cached_canvas = nil
end

function ShadedChar:draw()
    love.graphics.setFont(self:getFont())

    local caching = false
    if self.cache then
        if not self.cached_canvas then
            self.cached_canvas = love.graphics.newCanvas(self.width + 1, self.height + 1)
            Draw.pushCanvas(self.cached_canvas)
            caching = true
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.cached_canvas)
        end
    end
    if not self.cache or caching then
        local canvas = Draw.pushCanvas(self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.char)
        Draw.popCanvas()

        local shader = Kristal.Shaders["GradientV"]

        local last_shader = love.graphics.getShader()
        love.graphics.setShader(shader)

        local draw_color = {self:getDrawColor()}

        local white = draw_color[1] == 1 and draw_color[2] == 1 and draw_color[3] == 1

        shader:send("from", white and COLORS.dkgray or draw_color)
        shader:send("to", white and COLORS.navy or draw_color)
        love.graphics.setColor(1, 1, 1, white and 1 or 0.3)
        love.graphics.draw(canvas, 1 ,1)

        shader:send("from", COLORS.white)
        shader:send("to", white and COLORS.white or draw_color)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(canvas)

        love.graphics.setShader(last_shader)
    end
    if caching then
        Draw.popCanvas()
    end

    self:drawChildren()
end

return ShadedChar