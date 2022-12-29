---@class IceSpellEffect : Sprite
---@overload fun(...) : IceSpellEffect
local IceSpellEffect, super = Class(Sprite)

function IceSpellEffect:init(x, y, hexagon)
    super.init(self, hexagon and "effects/icespell/hexagon" or "effects/icespell/snowflake", x, y)

    self:setOrigin(0.5, 0.5)
    self:setScale(1.5)

    self.rotation_speed = 4

    self.physics.direction = 0
    self.physics.speed = 0

    self.timer = 0
end

function IceSpellEffect:update()
    self.rotation = self.rotation + math.rad(self.rotation_speed * 2) * DTMULT
    self.physics.direction = self.physics.direction + math.rad(self.rotation_speed * 3) * DTMULT

    self.timer = self.timer + DTMULT
    if self.timer >= 10 then
        self.alpha = self.alpha - 0.1 * DTMULT
    end

    if self.alpha < 0 then
        self:remove()
    end

    super.update(self)
end

return IceSpellEffect