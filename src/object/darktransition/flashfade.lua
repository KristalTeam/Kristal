local FlashFade, super = Class(Sprite)

function FlashFade:init(texture, x, y)
    super:init(self, texture, x, y)

    self.flashspeed = 1
    self.siner = 0
    self.target = nil

end

function FlashFade:draw()
    self.siner = self.siner + self.flashspeed * (DT * 30)

    love.graphics.setShader(Kristal.Shaders["White"])
    Kristal.Shaders["White"]:send("whiteAmount", 1)

    love.graphics.setColor(1, 1, 1, math.sin(self.siner / 3))

    if self.texture then
        super:draw(self)
    end

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setShader()

    if ((self.siner > 4) and (math.sin(self.siner / 3) < 0)) then
        self:remove()
    end

    super:draw(self)
end

return FlashFade