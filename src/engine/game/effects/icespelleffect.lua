local IceSpellEffect, super = Class(Sprite)

function IceSpellEffect:init(x, y, hexagon)
    super:init(self, hexagon and "effects/icespell/hexagon" or "effects/icespell/snowflake", x, y)

    self:setOrigin(0.5, 0.5)
    self:setScale(1.5)

    self.rotation_speed = 4
    self.direction = 0

    self.speed = 0

    self.timer = 0
end

function IceSpellEffect:update(dt)
    self.rotation = self.rotation + math.rad(self.rotation_speed * 2) * DTMULT
    self.direction = self.direction + math.rad(self.rotation_speed * 3) * DTMULT

    if self.speed > 0 then
        self.speed = Utils.approach(self.speed, 0, self.friction * DTMULT)

        self:move(math.cos(self.direction), math.sin(self.direction), self.speed * DTMULT)
    end

    self.timer = self.timer + DTMULT
    if self.timer >= 10 then
        self.alpha = self.alpha - 0.1 * DTMULT
    end

    if self.alpha < 0 then
        self:remove()
    end

    super:update(self, dt)
end

return IceSpellEffect