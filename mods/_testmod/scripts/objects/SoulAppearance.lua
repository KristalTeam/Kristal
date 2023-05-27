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

    local function draw_sprite_part_ext(left, top, width, height, x, y, xscale, yscale)
        -- TODO: optimize?
        love.graphics.draw(self.sprite, love.graphics.newQuad(left, top, width, height, self.sprite:getDimensions()), x, y, 0, xscale, yscale)
    end

    local function draw_sprite_part(left, top, width, height, x, y)
        draw_sprite_part_ext(left, top, width, height, x, y, 1, 1)
    end

    if (self.t <= 0) then
        self.xs = (1 + (self.t / 10))
        if (self.xs < 0) then
            self.xs = 0
        end

        draw_sprite_part_ext(0, self.m, self.width, 1, ((0 - ((self.width / 2) * self.xs)) + (self.width / 2)), self.m - 400, self.xs, 800)
    end

    if ((self.t > 0) and (self.t < self.m)) then
        draw_sprite_part(0, (self.m - self.t), self.width, (1 + (self.t * 2)), 0, ((0 - self.t) + self.m))
        draw_sprite_part_ext(0, ((self.m - self.t) - 1), self.width, 1, 0, (((0 - 400) - self.t) + self.m), 1, 400)
        draw_sprite_part_ext(0, (self.m + self.t), self.width, 1, 0, ((0 + self.t) + self.m), 1, 400)
    end

    if (self.t >= self.m) then
        love.graphics.draw(self.sprite, 0, 0)
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