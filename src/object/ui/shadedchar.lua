local ShadedChar, super = Class(TextChar)

-- Restrict characters to making 1 canvas per frame,
-- to avoid lag when skipping a long string of text
ShadedChar.MADE_CANVAS = false

function ShadedChar:init(char, x, y, font, color)
    super:init(self, char, x, y, font, color)

    self.cache = true
    self.cached_canvas = nil
end

function ShadedChar:update(dt)
    ShadedChar.MADE_CANVAS = false

    super:update(self, dt)
end

function ShadedChar:draw()
    love.graphics.setFont(self:getFont())

    local cache_wait = false
    local caching = false
    if self.cache then
        if not self.cached_canvas then
            if not ShadedChar.MADE_CANVAS then
                self.cached_canvas = love.graphics.newCanvas(self.width + 1, self.height + 1)
                Draw.pushCanvas(self.cached_canvas)
                caching = true
                ShadedChar.MADE_CANVAS = true
            else
                cache_wait = true
            end
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.cached_canvas)
        end
    end
    if not self.cache or caching or cache_wait then
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
        love.graphics.draw(canvas, 1, 1)

        shader:send("from", COLORS.white)
        shader:send("to", white and COLORS.white or draw_color)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(canvas)

        love.graphics.setShader(last_shader)
    end
    if caching then
        Draw.popCanvas()

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.cached_canvas)
    end

    super:draw(self)
end

return ShadedChar