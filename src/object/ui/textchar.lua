local TextChar, super = Class(Object)

function TextChar:init(char, x, y, font, color)
    super:init(self, x, y)

    self.char = char
    self.color = color or {1, 1, 1}

    self.inherit_color = true

    self.font = font or "main"
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

function TextChar:getFont()
    return Assets.getFont(self.font)
end

function TextChar:updateTexture()
    local font = self:getFont()
    self.width = font:getWidth(self.char)
    self.height = font:getHeight()
end

function TextChar:draw()
    love.graphics.setFont(self:getFont())
    love.graphics.print(self.char)
    super:draw(self)
end

return TextChar