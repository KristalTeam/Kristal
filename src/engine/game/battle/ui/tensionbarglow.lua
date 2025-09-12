--- The "glow" effect for when you collect a blob of tension (like from Titan Spawn).
---
--- You should never need to create this yourself.
---@see TensionBar.flash
---
---@class TensionBarGlow : Object
---
---@field parent TensionBar? # The tension bar this is attached to.
---@field current_alpha number? # The current alpha of the glow effect.
---
local TensionBarGlow, super = Class(Object)

function TensionBarGlow:init(x, y)
    super.init(self, x, y)

    self.apparent = Game.tension
    self.current_alpha = 1
end

function TensionBarGlow:update()
    super.update(self)

    -- Copied from tension bars...
    if (math.abs((self.apparent - self.parent:getTension250())) < 20) then
        self.apparent = self.parent:getTension250()
    end

    if (self.apparent < self.parent:getTension250()) then
        self.apparent = self.apparent + (20 * DTMULT)
    end

    if (self.apparent > self.parent:getTension250()) then
        self.apparent = self.apparent - (20 * DTMULT)
    end

    -- Slowly fade out
    self.current_alpha = Utils.approach(self.current_alpha, 0, 0.15 * DTMULT)

    -- If we're fully faded out, remove
    if self.current_alpha <= 0 then
        self:remove()
    end
end

function TensionBarGlow:draw()
    -- Simplified draw code. DELTARUNE's is very verbose for no real reason
    -- The largest change is the lack of for loop, because DELTARUNE had a for loop
    -- that only did a single iteration... so that was completely removed

    Draw.setColor(1, 1, 1, 1)

    love.graphics.setBlendMode("add")

    -- Can be simplified to `0.75 * self.current_alpha`, but the `1` is the
    -- current iteration of the for loop... the one that only ran a single time
    local alpha = (1 - (1 * 0.25)) * self.current_alpha

    -- Do our draw code in all 8 directions
    local offsets = { -1, 0, 1 }
    for _, dx in ipairs(offsets) do
        for _, dy in ipairs(offsets) do
            if not (dx == 0 and dy == 0) then
                Draw.draw(self.parent.tp_text, -30 + dx, 30 + dy, 0, 1, 1)

                love.graphics.setFont(self.parent.font)
                Draw.setColor(1, 1, 1, alpha)

                if Game.tension < 100 then
                    love.graphics.print(tostring(math.floor(Game.tension)), -30 + dx, 70 + dy)
                    love.graphics.print("%", -25 + dx, 95 + dy)
                else
                    love.graphics.print("M", -28 + dx, 70 + dy)
                    love.graphics.print("A", -24 + dx, 90 + dy)
                    love.graphics.print("X", -20 + dx, 110 + dy)
                end
            end
        end
    end

    love.graphics.setBlendMode("alpha")

    Draw.setColor(1, 1, 1, 0.75 * self.current_alpha)
    Draw.draw(self.parent.tp_bar_fill, 0, 0, 0, 1, 1)

    super.draw(self)
end

return TensionBarGlow
