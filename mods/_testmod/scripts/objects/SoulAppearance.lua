---@class SoulAppearance : Object
---@overload fun(...) : SoulAppearance
local SoulAppearance, super = Class(Object)

function SoulAppearance:init(x, y)
    super.init(self, x, y)

    self:setScale(2)
    self:setOrigin(0.5, 0.5)

    -- This is responsible for setting some variables!
    self:setSprite("player/heart_blur")

    self.t = -10
    self.tmax = 10
    self.m = 10
    self.x_scale = 0
    self.momentum = 0.5

    self.soul_width = 20
    self.soul_height = 20

    Assets.playSound("AUDIO_APPEARANCE")
    self:setColor(1, 0, 0, 1)
end

function SoulAppearance:setSprite(sprite)
    if type(sprite) == "string" then
        sprite = Assets.getTexture(sprite)
    end

    self.sprite = sprite
    self.width = self.sprite:getWidth()
    self.height = self.sprite:getHeight()
end

function SoulAppearance:hide()

    Assets.stopAndPlaySound("AUDIO_APPEARANCE")
    self.t = self.t - 2
    self.momentum = -0.5
    if self.t <= -10 then
        self:remove()
    end
end

function SoulAppearance:update()
    super.update(self)

    if (self.momentum > 0) then
        if (self.t < (self.tmax + 2)) then
            self.t = self.t + self.momentum * DTMULT
        end
    end

    if (self.momentum < 0) then
        self.t = self.t + self.momentum * DTMULT
    end

    if (self.t <= 0) then
        self.x_scale = (1 + (self.t / 10))
        if (self.x_scale < 0) then
            self.x_scale = 0
            self:remove()
        end
    end
end

function SoulAppearance:transformX(x)
    -- transform these to fit with our sprite (self.width, self.height) rather than (self.soul_width, self.soul_height)
    return x / self.soul_width * self.width
end

function SoulAppearance:transformY(y)
    -- same here
    return y / self.soul_height * self.height
end

function SoulAppearance:draw()
    super.draw(self)

    if (self.t <= 0) then
        Draw.drawPart(
            self.sprite,
            self:transformX((0 - ((self.soul_width / 2) * self.x_scale)) + (self.soul_width / 2)),
            self:transformY(self.m) - 400,
            0,
            self:transformY(self.m),
            self:transformX(self.soul_width),
            1,
            0,
            self.x_scale,
            800
        )
    end

    if ((self.t > 0) and (self.t < self.m)) then
        Draw.drawPart(
            self.sprite,
            0,
            self:transformY(0 - self.t + self.m),
            0,
            self:transformY((self.m - self.t)),
            self:transformX(self.soul_width),
            self:transformY(1 + (self.t * 2))
        )

        Draw.drawPart(
            self.sprite,
            0,
            -400 + self:transformY(-self.t + self.m),
            0,
            self:transformY((self.m - self.t) - 1),
            self:transformX(self.soul_width),
            1,
            0,
            1,
            400
        )

        Draw.drawPart(
            self.sprite,
            0,
            self:transformY(self.t + self.m),
            0,
            self:transformY(self.m + self.t),
            self:transformX(self.soul_width),
            1,
            0,
            1,
            400
        )
    end

    if (self.t >= self.m) then
        Draw.draw(self.sprite, 0, 0)
    end
end

return SoulAppearance
