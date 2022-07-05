local GonerBackgroundPiece, super = Class(Object)

function GonerBackgroundPiece:init()
    super:init(self, 0, 0, 320, 240)

    self.sprite = Assets.getTexture("IMAGE_DEPTH")

    self.timer = 0
    self.alpha = 0.2
    self.xstretch = 1
    self.ystretch = 1
    self.o_insurance = 0
    self.stretch_speed = 0.02
    self.b_insurance = 0
    self.b_insurance = -0.2
end

function GonerBackgroundPiece:update()
    self.timer = self.timer + DTMULT
    if (self.stretch_speed > 0) then
        self.alpha = (math.sin((self.timer / 34)) * 0.2)
    end
    self.ystretch = self.ystretch + self.stretch_speed * DTMULT
    self.xstretch = self.xstretch + self.stretch_speed * DTMULT
    if (self.b_insurance < 0) then
        self.b_insurance = self.b_insurance + 0.01 * DTMULT
    end
    if (self.ystretch > 2) then
        self.o_insurance = self.o_insurance + 0.01 * DTMULT
        if self.o_insurance >= 0.5 then
            self:remove()
        end
    end

    super:update(self)
end

function GonerBackgroundPiece:draw()
    if (self.timer > 2) then
        love.graphics.setColor(1, 1, 1, ((0.2 + self.alpha) - self.o_insurance) + self.b_insurance)
        love.graphics.draw(self.sprite, 160, 120, 0, ( 1 + self.xstretch), ( 1 + self.ystretch))
        love.graphics.draw(self.sprite, 160, 120, 0, (-1 - self.xstretch), ( 1 + self.ystretch))
        love.graphics.draw(self.sprite, 160, 120, 0, (-1 - self.xstretch), (-1 - self.ystretch))
        love.graphics.draw(self.sprite, 160, 120, 0, ( 1 + self.xstretch), (-1 - self.ystretch))
    end
end

return GonerBackgroundPiece