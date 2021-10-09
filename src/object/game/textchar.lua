local TextChar = newClass(Object)

function TextChar:init(char, x, y, color)
    super:init(self, x, y)

    self.char = char
    self.color = color

    self.font = "main"
    self:updateTexture()
end

function TextChar:setChar(char)
    self.char = char
    self:updateTexture()
end

function TextChar:setFont(font)
    self.font = font
    self:updateTexture()
end

function TextChar:updateTexture()
    self.texture = kristal.assets.getTexture("font/"..self.font.."/"..CHAR_TEXTURES[self.char])
    self.width = self.texture:getWidth()
    self.height = self.texture:getHeight()
end

function TextChar:draw()
    local shader = kristal.shaders.GRADIENT_V

    local last_shader = love.graphics.getShader()
    love.graphics.setShader(shader)

    local white = self.color[1] == 1 and self.color[2] == 1 and self.color[3] == 1

    shader:send("from", white and COLORS.dkgray or self.color)
    shader:send("to", white and COLORS.navy or self.color)
    love.graphics.setColor(1, 1, 1, white and 1 or 0.3)
    love.graphics.draw(self.texture, 1, 1)

    shader:send("from", COLORS.white)
    shader:send("to", white and COLORS.white or self.color)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.texture)

    love.graphics.setShader(last_shader)

    super:draw(self)
end

return TextChar