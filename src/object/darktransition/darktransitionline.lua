local DarkTransitionLine = newClass(Object)

function DarkTransitionLine:init(x)
    --super:init(self, x, y)
    Object.init(self, x, 260)

    local h = (6 + utils.round(40))
    self.image_xscale = 2
    self.image_yscale = (4 * h)
    self.vspeed = (-16 - math.random(4))
    self.depth = -100

end

function DarkTransitionLine:update(dt)
    self.pos.y = self.pos.y + self.vspeed * (dt * 30)
    if (self.pos.y >= 400) then
        self.parent:remove(self)
    end
end

function DarkTransitionLine:draw()

    love.graphics.setLineWidth(self.image_xscale * 2)
    love.graphics.setLineStyle("rough")
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(self.pos.x, self.pos.y, self.pos.x, self.pos.y + self.image_yscale)


    super:draw(self)
end

return DarkTransitionLine