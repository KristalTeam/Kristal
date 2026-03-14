--- The battle background object. By default, this is a purple grid.
--- 
--- This gets automatically spawned during battles; if you'd like to disable or customize it, override [`Encounter:createBackground`](lua://Encounter.createBackground).
---
---@class BattleBackground : Object
---
---@field position number An offset used to scroll the background.
---@field position2 number Another offset used to scroll the background.
---@field move_speed number The speed at which the background scrolls.
---@field private fading_out boolean Whether the background is currently fading out or not.
---
---@overload fun() : BattleBackground
local BattleBackground, super = Class(Object)

function BattleBackground:init()
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.debug_select = false

    self.layer = BATTLE_LAYERS["background"]

    self.position = 0
    self.position2 = 0
    self.move_speed = 1
    self.alpha = 0

    self.fading_out = false

    self:setParallax(0, 0)
end

function BattleBackground:update()
    self.position = self.position + (self.move_speed / 2) * DTMULT
    self.position2 = self.position2 + self.move_speed * DTMULT

    if self.position >= 100 then
        self.position = self.position - 100
    end

    if self.position2 >= 100 then
        self.position2 = self.position2 - 100
    end


    if not self.fading_out then
        self.alpha = MathUtils.approach(self.alpha, 1, 0.1 * DTMULT)
    else
        self.alpha = MathUtils.approach(self.alpha, 0, 0.1 * DTMULT)

        if self.alpha <= 0 then
            self:remove()
        end
    end
end

--- Returns whether the battle background is currently fading out or not.
---@return boolean
function BattleBackground:isFading()
    return self.fading_out
end

--- Request the battle background to fade out. The background will automatically be removed once it has fully faded out.
function BattleBackground:fadeOut()
    self.fading_out = true
end

function BattleBackground:drawBackground()
    -- Draw the black background
    love.graphics.setColor(0, 0, 0, self.alpha)
    love.graphics.rectangle("fill", -10, -10, SCREEN_WIDTH + 10, SCREEN_HEIGHT + 10)

    -- Draw the background grid
    local background = Assets.getTexture("ui/battle/background")

    love.graphics.setColor(1, 1, 1, self.alpha / 2)
    Draw.drawWrapped(background, true, true, MathUtils.round(-100 + self.position), MathUtils.round(-100 + self.position))
    love.graphics.setColor(1, 1, 1, self.alpha)
    Draw.drawWrapped(background, true, true, MathUtils.round(-200 - self.position2), MathUtils.round(-210 - self.position2))
end

function BattleBackground:draw()
    super.draw(self)

    self:drawBackground()
end

return BattleBackground
