local DarkTransitionSparkle, super = Class(Sprite)

function DarkTransitionSparkle:init(texture, x, y)
    super:init(self, texture, x, y)

    self.image_speed = 0.5
    self.hspeed = (math.random() * 6) - 3
    self.friction = 0.05
    self.gravity = -0.1
    self.vspeed = 0
end

function DarkTransitionSparkle:update(dt)
    self.vspeed = self.vspeed + self.gravity * (dt * 30)
    self:move(self.hspeed * (dt * 30), self.vspeed * (dt * 30))

    if (self.y <= -30) then
        self:remove()
    end

    super:update(self, dt)
end

return DarkTransitionSparkle