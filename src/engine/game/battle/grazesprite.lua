--- The sprite created around the soul whenever it grazes a bullet.
---
---@class GrazeSprite : Object
---@overload fun(x?: number, y?: number) : GrazeSprite
local GrazeSprite, super = Class(Object)

---@param x? number
---@param y? number
function GrazeSprite:init(x, y)
    self.texture = Assets.getTexture("player/graze")

    super.init(self, x, y, self.texture:getWidth(), self.texture:getHeight())

    self.graze_scale = 1

    self.timer = 0
    self.visible = false
end

function GrazeSprite:update()
    if self.timer > 0 then
        self.visible = true
        self.timer = Utils.approach(self.timer, 0, DT)
    else
        self.visible = false
    end
end

function GrazeSprite:draw()
    local r,g,b,a = self:getDrawColor()

    Draw.setColor(r/2, g/2, b/2, self.timer / 0.2)
    Draw.draw(self.texture)

    Draw.setColor(1, 1, 1, (self.timer / 0.2) - 0.2)
    Draw.draw(self.texture)

    if self.graze_scale ~= 1 then
        love.graphics.push()

        love.graphics.translate(self.width/2, self.height/2)
        love.graphics.scale(self.graze_scale, self.graze_scale)
        love.graphics.translate(-self.width/2, -self.height/2)

        Draw.setColor(r/2, g/2, b/2, self.timer / 0.2)
        Draw.draw(self.texture)

        Draw.setColor(1, 1, 1, (self.timer / 0.2) - 0.2)
        Draw.draw(self.texture)

        love.graphics.pop()
    end

    super.draw(self)
end

return GrazeSprite