--- A "piece" of the DEPTHS background effect. You should never really need to create this yourself.
---@class GonerBackgroundPiece : Object
---@overload fun(...) : GonerBackgroundPiece
local GonerBackgroundPiece, super = Class(Object)

function GonerBackgroundPiece:init(sprite, x, y)
    super.init(self, x, y, 320, 240)

    self:setOrigin(0.5, 0.5)

    self.sprite = sprite

    self.timer = 0
    self.alpha = 0.2
    self.xstretch = 1
    self.ystretch = 1
    self.o_insurance = 0
    self.stretch_speed = 0.02
    self.b_insurance = 0
    self.b_insurance = -0.2
end

function GonerBackgroundPiece:canDebugSelect()
    return false
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

    super.update(self)
end

function GonerBackgroundPiece:draw()
    super.draw(self)
    if (self.timer > 2) then
        Draw.setColor(1, 1, 1, ((0.2 + self.alpha) - self.o_insurance) + self.b_insurance)

        Draw.draw(self.sprite, self.width / 2, self.height / 2, 0, ( 1 + self.xstretch), ( 1 + self.ystretch))
        Draw.draw(self.sprite, self.width / 2, self.height / 2, 0, (-1 - self.xstretch), ( 1 + self.ystretch))
        Draw.draw(self.sprite, self.width / 2, self.height / 2, 0, (-1 - self.xstretch), (-1 - self.ystretch))
        Draw.draw(self.sprite, self.width / 2, self.height / 2, 0, ( 1 + self.xstretch), (-1 - self.ystretch))
    end
end

return GonerBackgroundPiece
