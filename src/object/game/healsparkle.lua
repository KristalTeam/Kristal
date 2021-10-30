local HealSparkle, super = Class(Sprite)

function HealSparkle:init(x, y)
    super:init(self, "effects/sparestar/sparestar", x, y)

    self:play(0.25, true)

    self:setColor(0, 1, 0)
    self:setOrigin(0.5, 0.5)
    self:setScale(2)

    self.rotation = love.math.random() * math.rad(360)

    self.speed_x = 2 - (love.math.random() * 2)
    self.speed_y = -3 - (love.math.random() * 2)
    self.friction = 0.2

    self.alpha = 2
    self.fade_speed = 0.1
    self.spin = -10
end

function HealSparkle:update(dt)
    self.alpha = Utils.approach(self.alpha, 0, self.fade_speed * DTMULT)
    self.rotation = self.rotation + (math.rad(self.spin) * DTMULT)

    if self.alpha == 0 then
        self:remove()
    end

    super:update(self, dt)
end

return HealSparkle