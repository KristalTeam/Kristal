---@class ColorMaskFX : FXBase
---@overload fun(...) : ColorMaskFX
local ColorMaskFX, super = Class(FXBase)

function ColorMaskFX:init(color, amount, priority)
    super.init(self, priority or 0)

    self.color = color or {1, 1, 1}
    self.amount = amount or 1
end

function ColorMaskFX:setColor(r,g,b)
    self.color = {r, g, b}
end

function ColorMaskFX:getColor()
    return self.color[1], self.color[2], self.color[3]
end

function ColorMaskFX:isActive()
    return super.isActive(self) and self.amount > 0
end

function ColorMaskFX:draw(texture)
    local last_shader = love.graphics.getShader()
    local shader = Kristal.Shaders["AddColor"]
    love.graphics.setShader(shader)
    shader:send("inputcolor", {self:getColor()})
    shader:send("amount", self.amount)
    Draw.drawCanvas(texture)
    shader:send("amount", 1)
    love.graphics.setShader(last_shader)
end

return ColorMaskFX