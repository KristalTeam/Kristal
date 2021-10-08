local DialogChar = newClass(Object)

function DialogChar:init(char, x, y, color)
    super:init(self, x, y)

    self.char = char
    self.color = color

    self.font = "main"
    self:updateTexture()
end

function DialogChar:setChar(char)
    self.char = char
    self:updateTexture()
end

function DialogChar:setFont(font)
    self.font = font
    self:updateTexture()
end

function DialogChar:updateTexture()
    self.texture = kristal.assets.getTexture("font/"..self.font.."/"..CHAR_TEXTURES[self.char])
end

function DialogChar:getWidth()
    return self.texture:getWidth()
end

function DialogChar:getHeight()
    return self.texture:getHeight()
end

function DialogChar:draw()
    local shader = kristal.shaders.GRADIENT_V

    local last_shader = love.graphics.getShader()
    love.graphics.setShader(shader)

    shader:send("from", utils.copy(self.color or COLORS.dkgray))
    shader:send("to", utils.copy(self.color or COLORS.navy))
    love.graphics.setColor(1, 1, 1, self.color and 0.3 or 1)
    love.graphics.draw(self.texture, 1, 1)

    shader:send("from", utils.copy(COLORS.white))
    shader:send("to", utils.copy(self.color or COLORS.white))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.texture)

    love.graphics.setShader(last_shader)

    super:draw(self)
end

return DialogChar