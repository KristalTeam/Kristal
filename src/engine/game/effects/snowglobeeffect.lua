---@class SnowglobeEffect : Object
---@overload fun(...) : SnowglobeEffect
local SnowglobeEffect, super = Class(Object)

function SnowglobeEffect:init(x, y, foreground)
    super.init(self, x, y, 120, 136)

    self.siner = 0
    self.a_factor = 0

    --local sprite = self:addChild(Sprite("party/noelle/dark_b/battle/pray", 35, 6))
    --sprite:play(1/30 / 0.2, true)
    --sprite:setScale(2)

    self.foreground = foreground
end

function SnowglobeEffect:draw()
    super.draw(self)

    local x_off = 35
    local y_off = 8
    local n_x_off = 35
    local n_y_off = 6

    love.graphics.push()
    Draw.pushScissor()
    Draw.scissor(-n_x_off, -n_y_off, 120, 136)
    love.graphics.translate(-n_x_off, -n_y_off)

    self.a_factor = math.sin((self.siner / 24))

    self.siner = self.siner + DTMULT

    if (self.a_factor < -0.2 and self.siner >= 8) then
        self.siner = self.siner - DTMULT
        self:remove() -- added by Kristal
    end

    love.graphics.stencil(function()
        local last_shader = love.graphics.getShader()
        love.graphics.setShader(Kristal.Shaders["Mask"])
        Draw.draw(Assets.getTexture("effects/snowglobe/mask"), n_x_off - x_off, n_y_off - y_off, 0, 2, 2)
        love.graphics.setShader(last_shader)
    end, "replace", 1)
    love.graphics.setStencilTest("less", 1)

    if not self.foreground then
        Draw.setColor(1, 1, 1, 0.6 * self.a_factor)
        Draw.draw(Assets.getTexture("effects/snowglobe/background"), n_x_off - x_off, n_y_off - y_off, 0, 2, 2)

        local snowangle = (-20 + (self.siner / 2)) * -1 -- gamemaker is opposite to love2d, so negate
        local snowoff = (self.siner / 2)

        Draw.setColor(1, 1, 1, 0.5 * self.a_factor)
        Draw.draw(Assets.getTexture("effects/snowglobe/snow"), (n_x_off - x_off) + snowoff, (n_y_off - y_off) + (self.siner / 2), math.rad(snowangle), 2, 2, 0, 0)
        Draw.draw(Assets.getTexture("effects/snowglobe/snow"), (n_x_off - x_off) - snowoff, (n_y_off - y_off) - (self.siner / 2), math.rad(-snowangle), 2, 2, 0, 0)
    end
    --Draw.setColor(1, 1, 1, 1)
    --Draw.draw(Assets.getTexture("party/noelle/dark_b/battle/victory_1"), n_x_off, n_y_off, 0, 2, 2)

    if self.foreground then
        Draw.setColor(0, 0, 1, 0.2 * self.a_factor)
        Draw.draw(Assets.getTexture("effects/snowglobe/gradient"), n_x_off - x_off, n_y_off - y_off, 0, 2, 2)
        --additive blending
        love.graphics.setBlendMode("add") -- bm_add
        Draw.setColor(0, 0, 1, 0.6 * self.a_factor)
        Draw.draw(Assets.getTexture("effects/snowglobe/gradient"), n_x_off - x_off, n_y_off - y_off, 0, 2, 2)
        love.graphics.setBlendMode("alpha")
    end

    love.graphics.setStencilTest()

    Draw.popScissor()
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
end

return SnowglobeEffect