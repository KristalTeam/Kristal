local RudeBusterEffect, super = Class(Object)

function RudeBusterEffect:init(x, y, tx, ty, after)
    super:init(self, x, y)

    self.target_x = tx
    self.target_y = ty

    self.rotation = Utils.angle(x, y, tx, ty) + math.rad(20)
    self.physics.speed = 24
    self.physics.friction = -1.5
    self.physics.match_rotation = true

    self.alpha = 0

    self.afterimg_timer = 0
    self.after_func = after
end

function RudeBusterEffect:update(dt)
    self.alpha = Utils.approach(self.alpha, 1, 0.25 * DTMULT)

    self.afterimg_timer = self.afterimg_timer + DTMULT
    if self.afterimg_timer >= 1 then

    end
end

return RudeBusterEffect