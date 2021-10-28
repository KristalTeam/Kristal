local TensionBar, super = Class(Object)

function TensionBar:init(x, y)
    super:init(self, x, y)

    self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill")
    self.tp_bar = Assets.getTexture("ui/battle/tp_bar")

    self.tension = 0
    self.max_tension = 250

    self.apparent = 0
    self.current = 0

    self.change = 0
    self.changetimer = 15
    self.font = Assets.getFont("main")
    self.tp_text = Assets.getTexture("ui/battle/tp_text")

    self.animation_timer = 0
end

function TensionBar:giveTension(amount)
    local start = self.tension
    self.tension = self.tension + amount
    if self.tension > self.max_tension then
        self.tension = self.max_tension
    end
    return self.tension - start
end

function TensionBar:removeTension(amount)
    self.tension = self.tension - amount
    if self.tension < 0 then
        self.tension = 0
    end
end

function TensionBar:setTension(amount)
    self.tension = Utils.clamp(amount, 0, self.max_tension)
end

function TensionBar:update(dt)
    self.animation_timer = self.animation_timer + (dt * 30)
    if self.animation_timer > 12 then
        self.animation_timer = 12
    end

    self.x = Ease.outCubic(self.animation_timer, -25, 25 + 38, 12)

    self:updateChildren(dt)
end

function TensionBar:draw()

    if (math.abs((self.apparent - self.tension)) < 20) then
        self.apparent = self.tension
    elseif (self.apparent < self.tension) then
        self.apparent = self.apparent + (20 * (DT * 30))
    elseif (self.apparent > self.tension) then
        self.apparent = self.apparent - (20 * (DT * 30))
    end
    if (self.apparent ~= self.current) then
        self.changetimer = self.changetimer + (1 * (DT * 30))
        if (self.changetimer > 15) then
            if ((self.apparent - self.current) > 0) then
                self.current = self.current + (2 * (DT * 30))
            end
            if ((self.apparent - self.current) > 10) then
                self.current = self.current + (2 * (DT * 30))
            end
            if ((self.apparent - self.current) > 25) then
                self.current = self.current + (3 * (DT * 30))
            end
            if ((self.apparent - self.current) > 50) then
                self.current = self.current + (4 * (DT * 30))
            end
            if ((self.apparent - self.current) > 100) then
                self.current = self.current + (5 * (DT * 30))
            end
            if ((self.apparent - self.current) < 0) then
                self.current = self.current - (2 * (DT * 30))
            end
            if ((self.apparent - self.current) < -10) then
                self.current = self.current - (2 * (DT * 30))
            end
            if ((self.apparent - self.current) < -25) then
                self.current = self.current - (3 * (DT * 30))
            end
            if ((self.apparent - self.current) < -50) then
                self.current = self.current - (4 * (DT * 30))
            end
            if ((self.apparent - self.current) < -100) then
                self.current = self.current - (5 * (DT * 30))
            end
            if (math.abs((self.apparent - self.current)) < 3) then
                self.current = self.apparent
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.tp_bar, 0, 0)

    if (self.apparent < self.current) then
        love.graphics.setColor(1, 0, 0, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / 250) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(255 / 255, 160 / 255, 64 / 255, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.apparent / 250) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent > self.current) then
        love.graphics.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.apparent / 250) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(255 / 255, 160 / 255, 64 / 255, 1)
        if (self.maxed) then
            love.graphics.setColor(255 / 255, 208 / 255, 32 / 255, 1)
        end
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / 250) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent == self.current) then
        love.graphics.setColor(255 / 255, 160 / 255, 64 / 255, 1)
        if (self.maxed) then
            love.graphics.setColor(255 / 255, 208 / 255, 32 / 255, 1)
        end
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / 250) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    if ((self.apparent > 20) and (self.apparent < self.max_tension)) then
        love.graphics.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / 250) * 196) + 1, 25, 196 - ((self.current / 250) * 196) + 3)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.tp_text, -30, 30)

    local tamt = math.floor(((self.apparent / self.max_tension) * 100))
    self.maxed = false
    love.graphics.setFont(self.font)
    if (tamt < 100) then
        love.graphics.print(tostring(math.floor((self.apparent / self.max_tension) * 100)), -30, 70)
        love.graphics.print("%", -25, 95)
    end
    if (tamt >= 100) then
        self.maxed = true

        love.graphics.setColor(1, 1, 0, 1)

        love.graphics.print("M", -28, 70)
        love.graphics.print("A", -24, 90)
        love.graphics.print("X", -20, 110)
    end

    self:drawChildren()
end

return TensionBar