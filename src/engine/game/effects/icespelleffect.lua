local IceSpellEffect, super = Class(Sprite)

function IceSpellEffect:init(x, y, snowflake)
    super:init(self, snowflake and "effects/icespell/snowflake" or "effects/icespell/hexagon", x, y)

    self:setOrigin(0.5, 0.5)
    self:setScale(1.5)

    self.rotation_speed = 4
    self.timer = 0
end

function IceSpellEffect:update(dt)
    self.rotation = self.rotation + math.rad(self.rotation_speed * 2) * DTMULT

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