---@class DarkTransitionParticle : Object
---@overload fun(...) : DarkTransitionParticle
local DarkTransitionParticle, super = Class(Object)

function DarkTransitionParticle:init(x, y)
    super.init(self, x, y)

    self.vspeed = -2
    self.image_xscale = 2
    self.image_yscale = 2
    self.friction = 0.07
    self.hspeed = (-1 + (math.random() * 2))

    self.depth = -100
    self.image_alpha = 1
end

function DarkTransitionParticle:update()
    self.vspeed = self.vspeed - (self.friction * DTMULT)
    -- Divide by two, since this is drawn at 320x240 in DR
    self:move((self.hspeed * DTMULT) / 2, (self.vspeed * DTMULT) / 2)

    self.image_alpha = self.image_alpha - 0.05 * DTMULT
    if (self.image_alpha <= 0) then
        self:remove()
    end

    super.update(self)
end

function DarkTransitionParticle:draw()
    love.graphics.setPointSize(2 * 2)
    Draw.setColor(1, 1, 1, self.image_alpha)
    love.graphics.points(0, 0)

    super.draw(self)
end

return DarkTransitionParticle