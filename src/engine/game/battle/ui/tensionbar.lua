--- The bar you see on the left of the battle UI.
--- 
--- This is simply a display for tension, but not where tension itself is stored.
---
--- Does not depend on battle.
---
---@see Game.giveTension
---@class TensionBar : Object
---@overload fun(...) : TensionBar
---
---@field current_flash TensionBarGlow? # The current glow effect, if any.
---
local TensionBar, super = Class(Object)

--[[
    Some quick notes about the tension bar:

    "apparent" and "current" are still off of 250.
    This is because of how Deltarune draws the tensionbar,
    theres no way I would be able to keep accuracy if I didn't do it.

    Max tension is now 100 by default.
    Setting it to 1000 will make Heal Prayer cost 3.2% TP (displayed as 3% in the menu.)
    Setting it to 1 will make Heal Prayer cost 3200% TP.

    Tension is no longer stored in the tensionbar, it is now stored in Game.
]]

function TensionBar:init(x, y, dont_animate)
    if Game.world and (not x) then
        local x2 = Game.world.camera:getRect()
        x = x2 - 25
    end

    super.init(self, x or -25, y or 40)

    self.layer = BATTLE_LAYERS["ui"] - 1

    if Game:getConfig("oldTensionBar") then
        self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill_old")
        self.tp_bar_outline = Assets.getTexture("ui/battle/tp_bar_outline_old")
    else
        self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill")
        self.tp_bar_outline = Assets.getTexture("ui/battle/tp_bar_outline")
    end

    self.width = self.tp_bar_outline:getWidth()
    self.height = self.tp_bar_outline:getHeight()

    self.apparent = 0
    self.current = 0

    self.change = 0
    self.changetimer = 15
    self.font = Assets.getFont("main")
    self.tp_text = Assets.getTexture("ui/battle/tp_text")

    self.parallax_y = 0

    -- still dont understand nil logic
    if dont_animate then
        self.animating_in = false
    else
        self.animating_in = true
    end

    self.animation_timer = 0

    self.tension_preview_timer = 0

    self.tension_preview = 0
    self.shown = false

    self.timer = self:addChild(Timer())
end

function TensionBar:show()
    if not self.shown then
        self:resetPhysics()
        self.x = self.init_x
        self.shown = true
        self.animating_in = true
        self.animation_timer = 0
    end
end

function TensionBar:hide()
    if self.shown then
        self.animating_in = false
        self.shown = false
        self.physics.speed_x = -10
        self.physics.friction = -0.4
    end
end

function TensionBar:flash()
    -- Spawn the flash if needed
    if self.current_flash == nil or self.current_flash:isRemoved() then
        self.current_flash = self:addChild(TensionBarGlow()) --[[@as TensionBarGlow]]
    else
        -- Still exists, reuse it
        self.current_flash.current_alpha = 1
    end

    -- Spawn 3-5 sparkles
    for _ = 1, love.math.random(3, 5) do
        local x = self.x + love.math.random(0, 25)
        local y = self.y + 40 + love.math.random(0, 160)
        local sparkle = self.parent:addChild(Sprite("effects/spare/star", x, y))
        sparkle.layer = 999
        sparkle.alpha = 1

        local duration = 10 + love.math.random(0, 5)

        sparkle:play(1 / (30 * (5 / duration)), true)
        sparkle.physics.speed = 3 + love.math.random() * 3
        sparkle.physics.direction = -math.rad(90)
        sparkle:fadeTo(0.25, duration / 30)
        self.timer:tween(duration / 30, sparkle.physics, { speed = 0 }, "linear")

        self.timer:after(duration / 30, function ()
            sparkle:remove()
        end)
    end
end

function TensionBar:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Tension: " .. Utils.round(self:getPercentageFor(Game:getTension()) * 100) .. "%")
    table.insert(info, "Apparent: " .. Utils.round(self.apparent / 2.5))
    table.insert(info, "Current: " .. Utils.round(self.current / 2.5))
    table.insert(info, "Reduced: " .. (self:hasReducedTension() and "True" or "False"))
    return info
end

function TensionBar:hasReducedTension()
    return Game.battle and Game.battle:hasReducedTension() or false
end

function TensionBar:getTension250()
    return self:getPercentageFor(Game:getTension()) * 250
end

function TensionBar:setTensionPreview(amount)
    self.tension_preview = amount
end

function TensionBar:getPercentageFor(variable)
    return variable / Game:getMaxTension()
end

function TensionBar:getPercentageFor250(variable)
    return variable / 250
end

function TensionBar:processSlideIn()
    if self.animating_in then
        self.animation_timer = self.animation_timer + DTMULT
        if self.animation_timer > 12 then
            self.animation_timer = 12
            self.animating_in = false
        end

        self.x = Ease.outCubic(self.animation_timer, self.init_x, 25 + 38, 12)
    end
end

function TensionBar:processTension()
    if (math.abs((self.apparent - self:getTension250())) < 20) then
        self.apparent = self:getTension250()
    end

    if (self.apparent < self:getTension250()) then
        self.apparent = self.apparent + (20 * DTMULT)
    end

    if (self.apparent > self:getTension250()) then
        self.apparent = self.apparent - (20 * DTMULT)
    end

    if (self.apparent ~= self.current) then
        self.changetimer = self.changetimer + (1 * DTMULT)
        if (self.changetimer > 15) then
            if ((self.apparent - self.current) > 0) then
                self.current = self.current + (2 * DTMULT)
            end
            if ((self.apparent - self.current) > 10) then
                self.current = self.current + (2 * DTMULT)
            end
            if ((self.apparent - self.current) > 25) then
                self.current = self.current + (3 * DTMULT)
            end
            if ((self.apparent - self.current) > 50) then
                self.current = self.current + (4 * DTMULT)
            end
            if ((self.apparent - self.current) > 100) then
                self.current = self.current + (5 * DTMULT)
            end
            if ((self.apparent - self.current) < 0) then
                self.current = self.current - (2 * DTMULT)
            end
            if ((self.apparent - self.current) < -10) then
                self.current = self.current - (2 * DTMULT)
            end
            if ((self.apparent - self.current) < -25) then
                self.current = self.current - (3 * DTMULT)
            end
            if ((self.apparent - self.current) < -50) then
                self.current = self.current - (4 * DTMULT)
            end
            if ((self.apparent - self.current) < -100) then
                self.current = self.current - (5 * DTMULT)
            end
            if (math.abs((self.apparent - self.current)) < 3) then
                self.current = self.apparent
            end
        end
    end

    if (self.tension_preview > 0) then
        self.tension_preview_timer = self.tension_preview_timer + DTMULT
    end
end

function TensionBar:update()
    self:processSlideIn()
    self:processTension()

    super.update(self)
end

function TensionBar:drawText()
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.tp_text, -30, 30)

    local tamt = math.floor(self:getPercentageFor250(self.apparent) * 100)
    self.maxed = false
    love.graphics.setFont(self.font)
    if (tamt < 100) then
        love.graphics.print(tostring(math.floor(self:getPercentageFor250(self.apparent) * 100)), -30, 70)
        love.graphics.print("%", -25, 95)
    end
    if (tamt >= 100) then
        self.maxed = true

        self:drawMaxText()
    end
end

function TensionBar:drawMaxText()
    Draw.setColor(PALETTE["tension_maxtext"])

    love.graphics.print("M", -28, 70)
    love.graphics.print("A", -24, 90)
    love.graphics.print("X", -20, 110)
end

function TensionBar:drawBack()
    Draw.setColor(self:hasReducedTension() and PALETTE["tension_back_reduced"] or PALETTE["tension_back"])
    Draw.pushScissor()
    Draw.scissorPoints(0, 0, 25, 196 - (self:getPercentageFor250(self.current) * 196) + 1)
    Draw.draw(self.tp_bar_fill, 0, 0)
    Draw.popScissor()
end

--- Get the color for the tension bar's "fill".
function TensionBar:getFillColor()
    return self:hasReducedTension() and PALETTE["tension_fill_reduced"] or PALETTE["tension_fill"]
end

--- Get the color for the tension bar's "fill" when tension is maxed.
function TensionBar:getFillMaxColor()
    return self:hasReducedTension() and PALETTE["tension_max_reduced"] or PALETTE["tension_max"]
end

--- Get the color for the tension bar's "fill" when the tension is decreasing.
function TensionBar:getFillDecreaseColor()
    return self:hasReducedTension() and PALETTE["tension_decrease_reduced"] or PALETTE["tension_decrease"]
end

function TensionBar:drawFill()
    local tension_fill = self:getFillColor()
    local tension_max = self:getFillMaxColor()
    local tension_decrease = self:getFillDecreaseColor()

    if (self.apparent < self.current) then
        Draw.setColor(tension_decrease)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.current) * 196) + 1, 25, 196)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        Draw.setColor(tension_fill)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.apparent) * 196) + 1 + (self:getPercentageFor(self.tension_preview) * 196), 25, 196)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent > self.current) then
        Draw.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.apparent) * 196) + 1, 25, 196)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        Draw.setColor(tension_fill)
        if (self.maxed) then
            Draw.setColor(tension_max)
        end
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.current) * 196) + 1 + (self:getPercentageFor(self.tension_preview) * 196), 25, 196)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent == self.current) then
        Draw.setColor(tension_fill)
        if (self.maxed) then
            Draw.setColor(tension_max)
        end
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.current) * 196) + 1 + (self:getPercentageFor(self.tension_preview) * 196), 25, 196)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    if (self.tension_preview > 0) then
        local alpha = (math.abs((math.sin((self.tension_preview_timer / 8)) * 0.5)) + 0.2)
        local color_to_set = { 1, 1, 1, alpha }

        local theight = 196 - (self:getPercentageFor250(self.current) * 196)
        local theight2 = theight + (self:getPercentageFor(self.tension_preview) * 196)
        -- Note: causes a visual bug.
        if (theight2 > ((0 + 196) - 1)) then
            theight2 = ((0 + 196) - 1)
            color_to_set = { COLORS.dkgray[1], COLORS.dkgray[2], COLORS.dkgray[3], 0.7 }
        end

        Draw.pushScissor()
        Draw.scissorPoints(0, theight2 + 1, 25, theight + 1)

        -- No idea how Deltarune draws this, cause this code was added in Kristal:
        local r, g, b, _ = love.graphics.getColor()
        Draw.setColor(r, g, b, 0.7)
        Draw.draw(self.tp_bar_fill, 0, 0)
        -- And back to the translated code:
        Draw.setColor(color_to_set)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        Draw.setColor(1, 1, 1, 1)
    end


    if ((self.apparent > 20) and (self.apparent < 250)) then
        Draw.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.current) * 196) + 1, 25, 196 - (self:getPercentageFor250(self.current) * 196) + 3)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end
end

function TensionBar:draw()
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.tp_bar_outline, 0, 0)

    self:drawBack()
    self:drawFill()

    self:drawText()

    super.draw(self)
end

return TensionBar
