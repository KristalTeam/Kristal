---@class HeartBurst : Object
---@overload fun(...) : HeartBurst
local HeartBurst, super = Class(Object)

function HeartBurst:init(x, y, color)
    super.init(self, x, y)

    if color then
        self:setColor(color)
    else
        self:setColor(1, 0, 0)
    end

    self:setOrigin(0.5, 0.5)

    self.layer = BATTLE_LAYERS["battlers"] + 1

    self.burst = 0

    self.heart_outline_outer = Assets.getTexture("player/heart_outline_outer")
    self.heart_outline_inner = Assets.getTexture("player/heart_outline_inner")
    self.heart_outline_filled_inner = Assets.getTexture("player/heart_outline_filled_inner")
end

function HeartBurst:update()
    self.burst = self.burst + DTMULT

    --self:setScale(2 - self.stretch, self.stretch + self.kill)

    super.update(self)
end

function HeartBurst:drawHeartOutline(scale_x, scale_y, alpha)
    local r,g,b,a = self:getDrawColor()
    Draw.setColor(r, g, b, a * (alpha or 1))
    Draw.draw(self.heart_outline_outer, 9, 9, 0, scale_x or 1, scale_y or 1, self.heart_outline_outer:getWidth()/2, self.heart_outline_outer:getHeight()/2)
    Draw.setColor(1, 1, 1, a * (alpha or 1))
    Draw.draw(self.heart_outline_inner, 9, 9, 0, scale_x or 1, scale_y or 1, self.heart_outline_inner:getWidth()/2, self.heart_outline_inner:getHeight()/2)
end

function HeartBurst:draw()
    local r,g,b,a = self:getDrawColor()
    Draw.setColor(r, g, b, a * (0.8 - (self.burst / 6)))
    local xscale, yscale = 0.25 + self.burst, (0.25 + (self.burst / 2))
    Draw.draw(self.heart_outline_filled_inner, 9, 9, 0, xscale, yscale, self.heart_outline_filled_inner:getWidth()/2, self.heart_outline_filled_inner:getHeight()/2)

    xscale, yscale = (0.25 + (self.burst / 1.5)), (0.25 + (self.burst / 3))
    self:drawHeartOutline(xscale, yscale, (1 - (self.burst / 6)))

    xscale, yscale = (0.2 + (self.burst / 2.5)), (0.2 + (self.burst / 5))
    self:drawHeartOutline(xscale, yscale, (1.2 - (self.burst / 6)))

    super.draw(self)

    if self.burst > 10 then
        self:remove()
    end
end

return HeartBurst