---@class DarkTransitionSparkle : Sprite
---@overload fun(...) : DarkTransitionSparkle
local DarkTransitionSparkle, super = Class(Sprite)

function DarkTransitionSparkle:init(texture, x, y)
    super.init(self, texture, x, y)

    self.hspeed = (math.random() * 6) - 3
    self.friction = 0.05
    self.gravity = -0.1
    self.vspeed = 0
    self:play(1/15)
end

function DarkTransitionSparkle:update()
    self.vspeed = self.vspeed + self.gravity * DTMULT
    self:move(self.hspeed * DTMULT, self.vspeed * DTMULT)

    if (self.y <= -30) then
        self:remove()
    end

    super.update(self)
end

return DarkTransitionSparkle