local HeartBurst, super = Class(Object)

function HeartBurst:init(x, y)
    super:init(self, x, y)

    self:setOrigin(0.5, 0.5)

    self.layer = BATTLE_LAYERS["battlers"] + 1

    self.burst = 0

    self.heart_outline = Assets.getTexture("player/heart_outline")
    self.heart_outline_filled = Assets.getTexture("player/heart_outline_filled")
end

function HeartBurst:update(dt)
    self.burst = self.burst + DTMULT

    --self:setScale(2 - self.stretch, self.stretch + self.kill)

    super:update(self, dt)
end

function HeartBurst:draw()

    love.graphics.setColor(1, 1, 1, (0.8 - (self.burst / 6)))
    local xscale, yscale = 0.25 + self.burst, (0.25 + (self.burst / 2))
    love.graphics.draw(self.heart_outline_filled, 9, 9, 0, xscale, yscale, self.heart_outline_filled:getWidth()/2, self.heart_outline_filled:getHeight()/2)

    love.graphics.setColor(1, 1, 1, (1 - (self.burst / 6)))
    xscale, yscale = (0.25 + (self.burst / 1.5)), (0.25 + (self.burst / 3))
    love.graphics.draw(self.heart_outline, 9, 9, 0, xscale, yscale, self.heart_outline:getWidth()/2, self.heart_outline:getHeight()/2)

    love.graphics.setColor(1, 1, 1, (1.2 - (self.burst / 6)))
    xscale, yscale = (0.2 + (self.burst / 2.5)), (0.2 + (self.burst / 5))
    love.graphics.draw(self.heart_outline, 9, 9, 0, xscale, yscale, self.heart_outline:getWidth()/2, self.heart_outline:getHeight()/2)

    super:draw(self)

    if self.burst > 10 then
        self:remove()
    end
end

return HeartBurst