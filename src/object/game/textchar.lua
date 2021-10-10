local TextChar = newClass(Object)

function TextChar:init(char, x, y, color)
    Object.init(self, x, y)

    self.char = char
    self.color = color
    
    self.inherit_color = true

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

function TextChar:getTextHeight(font)
    local font = font or "main"
    local texture = kristal.assets.getTexture("font/"..font.."/"..CHAR_TEXTURES[" "])
    return texture and texture:getHeight() or 0
end

function TextChar:getTextWidth(str, font)
    local font = font or "main"
    local w = 0
    local i = 1, #str do
        local texture = kristal.assets.getTexture("font/"..font.."/"..CHAR_TEXTURES[str:sub(i, i)])
        if texture then
            w = w + texture:getWidth()
        end
    end
    return w
end

function TextChar:updateTexture()
    self.texture = kristal.assets.getTexture("font/"..self.font.."/"..CHAR_TEXTURES[self.char])
    self.width = self.texture:getWidth()
    self.height = self.texture:getHeight()
end

function TextChar:draw()
    love.graphics.draw(self.texture)
    Object.draw(self)
end

return TextChar