local Vironeedle, super = Class(Bullet)

function Vironeedle:init(x, y)
    super:init(self, x, y)

    self:setSprite("bullets/viro_needle", 1/15, false)
    self:setHitbox(8, 13, 14, 4)

    self.alpha = 0
    self.rotation = math.pi
    self.speed = 1
    self.friction = -0.2
end

function Vironeedle:update(dt)
    self.alpha = Utils.approach(self.alpha, 1, dt / (1/3))

    super:update(self, dt)
end

return Vironeedle