---@class AttackBar : Object
---@overload fun(...) : AttackBar
local AttackBar, super = Class(Object)

function AttackBar:init(x, y, width, height)
    super.init(self, x, y, width, height)

    self:setScaleOrigin(0.5, 0.5)

    self.bursting = false
    self.burst_speed = 0.1
end

function AttackBar:burst()
    self.bursting = true
    self:fadeOutSpeedAndRemove(0.1)
end

function AttackBar:update()
    if self.bursting then
        self.scale_x = self.scale_x + self.burst_speed * DTMULT
        self.scale_y = self.scale_y + self.burst_speed * DTMULT
    end

    super.update(self)
end

function AttackBar:draw()
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    super.draw(self)
end

return AttackBar