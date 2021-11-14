local SleepMistEffect, super = Class(Object)

function SleepMistEffect:init(x, y, success)
    super:init(self, x, y)

    self.texture = Assets.getTexture("effects/icespell/mist")

    self.success = success == nil or success
    self.siner = 0
end

function SleepMistEffect:update(dt)
    self.siner = self.siner + DTMULT
    self.alpha = (math.sin(self.siner / 9) - 0.3) + (self.success and 0.3 or 0)

    if self.siner >= 40 then
        self:remove()
    end

    super:update(self, dt)
end

function SleepMistEffect:draw()
    local amp = math.sin(self.siner / 9) * 30
    local x, y = math.sin(self.siner / 6) * amp, (math.cos(self.siner / 6) * amp) / 2

    local r,g,b,a = self:getDrawColor()
    love.graphics.setColor(r, g, b, a * 0.8)
    love.graphics.draw(self.texture, x, y, 0, 3, 2, self.texture:getWidth()/2, self.texture:getHeight()/2)
    love.graphics.draw(self.texture, -x, -y, 0, 3, 2, self.texture:getWidth()/2, self.texture:getHeight()/2)

    super:draw(self)
end

return SleepMistEffect