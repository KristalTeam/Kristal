local DarkTransitionLine, super = Class(Object)

function DarkTransitionLine:init(x)
    super:init(self, x, 260)

    local h = (6 + Utils.round(40))
    self.image_xscale = 2
    self.image_yscale = (4 * h)
    self.vspeed = (-16 - math.random(4))
    self.depth = -100

end

function DarkTransitionLine:update(dt)
    self:move(0, self.vspeed * (dt * 30))
    if (self.y >= 400) then
        self.parent:removeChild(self)
    end
    self:updateChildren(dt)
end

function DarkTransitionLine:draw()
    love.graphics.setLineWidth(self.image_xscale)
    love.graphics.setLineStyle("rough")
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(0, 0, 0, self.image_yscale)

    self:drawChildren()
end

return DarkTransitionLine