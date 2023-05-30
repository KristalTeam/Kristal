---@class SoulAppearance : Object
---@overload fun(...) : SoulAppearance
local SoulAppearance, super = Class(Object)

function SoulAppearance:init(x, y)
    super.init(self, x, y)

    self:setScale(2)
    self:setOrigin(0, 0)

    self.sprite = Assets.getTexture("player/heart_blur")
    self.width = self.sprite:getWidth()
    self.height = self.sprite:getHeight()

    self.t = -10
    self.m = (self.height / 2)
    self.momentum = 0.5

    Assets.playSound("AUDIO_APPEARANCE")
    self:setColor(1, 0, 0, 1)
end

function SoulAppearance:hide()
    Assets.playSound("AUDIO_APPEARANCE")
    self.t = self.t - 2
    self.momentum = -0.5
    if self.t <= -10 then
        self:remove()
    end
end

function SoulAppearance:draw()
    super.draw(self)

    if (self.t <= 0) then
        self.xs = (1 + (self.t / 10))
        if (self.xs < 0) then
            self.xs = 0
        end

        Draw.drawPart(self.sprite, ((0 - ((self.width / 2) * self.xs)) + (self.width / 2)), self.m - 400, 0, self.m, self.width, 1, 0, self.xs, 800)
    end

    if ((self.t > 0) and (self.t < self.m)) then
        Draw.drawPart(self.sprite, 0, ((0 - self.t) + self.m), 0, (self.m - self.t), self.width, (1 + (self.t * 2)))
        Draw.drawPart(self.sprite, 0, (((0 - 400) - self.t) + self.m), 0, ((self.m - self.t) - 1), self.width, 1, 0, 1, 400)
        Draw.drawPart(self.sprite, 0, ((0 + self.t) + self.m), 0, (self.m + self.t), self.width, 1, 0, 1, 400)
    end

    if (self.t >= self.m) then
        Draw.draw(self.sprite, 0, 0)
    end

    if (self.momentum > 0) then
        if (self.t < (self.m + 2)) then
            self.t = self.t + self.momentum * DTMULT
        end
    end
    if (self.momentum < 0) then
        self.t = self.t + self.momentum * DTMULT
    end
end

return SoulAppearance