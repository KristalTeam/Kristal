local TensionBar, super = Class(Object)

function TensionBar:init(x, y)
    super:init(self, x, y)

    self.layer = LAYERS["ui"] - 1

    self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill")
    self.tp_bar_outline = Assets.getTexture("ui/battle/tp_bar_outline")

    self.apparent = 0
    self.current = 0

    self.change = 0
    self.changetimer = 15
    self.font = Assets.getFont("main")
    self.tp_text = Assets.getTexture("ui/battle/tp_text")

    self.parallax_y = 0

    self.animating_in = true
    self.animation_timer = 0

    self.tsiner = 0

    self.tension_preview = 0
end

function TensionBar:giveTension(amount)
    local start = Game.battle.tension
    Game.battle.tension = Game.battle.tension + amount
    if Game.battle.tension > Game.battle.max_tension then
        Game.battle.tension = Game.battle.max_tension
    end
    self.tension_preview = 0
    return Game.battle.tension - start
end

function TensionBar:removeTension(amount)
    Game.battle.tension = Game.battle.tension - amount
    if Game.battle.tension < 0 then
        Game.battle.tension = 0
    end
    self.tension_preview = 0
end

function TensionBar:setTensionPreview(amount)
    self.tension_preview = amount
end

function TensionBar:setTension(amount)
    Game.battle.tension = Utils.clamp(amount, 0, Game.battle.max_tension)
end

function TensionBar:update(dt)
    if self.animating_in then
        self.animation_timer = self.animation_timer + (dt * 30)
        if self.animation_timer > 12 then
            self.animation_timer = 12
        end

        self.x = Ease.outCubic(self.animation_timer, -25, 25 + 38, 12)
    end

    if (math.abs((self.apparent - Game.battle.tension)) < 20) then
        self.apparent = Game.battle.tension
    elseif (self.apparent < Game.battle.tension) then
        self.apparent = self.apparent + (20 * (DT * 30))
    elseif (self.apparent > Game.battle.tension) then
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

    if (self.tension_preview > 0) then
        self.tsiner = self.tsiner + DTMULT
    end

    super:update(self, dt)
end

function TensionBar:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.tp_bar_outline, 0, 0)

    love.graphics.setColor(128/255, 0, 0, 1)
    Draw.pushScissor()
    Draw.scissor(0, 0, 25, 196 - ((self.current / Game.battle.max_tension) * 196) + 1)
    love.graphics.draw(self.tp_bar_fill, 0, 0)
    Draw.popScissor()

    if (self.apparent < self.current) then
        love.graphics.setColor(1, 0, 0, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / Game.battle.max_tension) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(255 / 255, 160 / 255, 64 / 255, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.apparent / Game.battle.max_tension) * 196) + 1 + ((self.tension_preview / Game.battle.max_tension) * 196), 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent > self.current) then
        love.graphics.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.apparent / Game.battle.max_tension) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(255 / 255, 160 / 255, 64 / 255, 1)
        if (self.maxed) then
            love.graphics.setColor(255 / 255, 208 / 255, 32 / 255, 1)
        end
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / Game.battle.max_tension) * 196) + 1 + ((self.tension_preview / Game.battle.max_tension) * 196), 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent == self.current) then
        love.graphics.setColor(255 / 255, 160 / 255, 64 / 255, 1)
        if (self.maxed) then
            love.graphics.setColor(255 / 255, 208 / 255, 32 / 255, 1)
        end
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / Game.battle.max_tension) * 196) + 1 + ((self.tension_preview / Game.battle.max_tension) * 196), 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    if (self.tension_preview > 0) then
        local alpha = (math.abs((math.sin((self.tsiner / 8)) * 0.5)) + 0.2)
        local color_to_set = {1, 1, 1, alpha}

        local theight = 196 - ((self.current / Game.battle.max_tension) * 196)
        local theight2 = theight + ((self.tension_preview / Game.battle.max_tension) * 196)
        -- Note: DOESNT cause a visual bug. Sorry
        if (theight2 > 196) then
            theight2 = 196
            color_to_set = {COLORS.dkgray[1], COLORS.dkgray[2], COLORS.dkgray[3], 0.7}
        end

        Draw.pushScissor()
        Draw.scissor(0, theight2 + 1, 25, math.floor(theight + 1))

        -- No idea how Deltarune draws this, cause this code was added in Kristal:
        local r,g,b,_ = love.graphics.getColor()
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        -- And back to the translated code:
        love.graphics.setColor(color_to_set)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(1, 1, 1, 1)
    end


    if ((self.apparent > 20) and (self.apparent < Game.battle.max_tension)) then
        love.graphics.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissor(0, 196 - ((self.current / Game.battle.max_tension) * 196) + 1, 25, 196 - ((self.current / Game.battle.max_tension) * 196) + 3)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.tp_text, -30, 30)

    local tamt = math.floor(((self.apparent / Game.battle.max_tension) * 100))
    self.maxed = false
    love.graphics.setFont(self.font)
    if (tamt < 100) then
        love.graphics.print(tostring(math.floor((self.apparent / Game.battle.max_tension) * 100)), -30, 70)
        love.graphics.print("%", -25, 95)
    end
    if (tamt >= 100) then
        self.maxed = true

        love.graphics.setColor(1, 1, 0, 1)

        love.graphics.print("M", -28, 70)
        love.graphics.print("A", -24, 90)
        love.graphics.print("X", -20, 110)
    end

    super:draw(self)
end

return TensionBar