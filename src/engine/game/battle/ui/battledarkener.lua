--- The battle darkener object, used to darken the background while the enemy attacks.
--- 
--- This gets automatically spawned during battles; if you'd like to disable or customize it, override [`Encounter:createBattleDarkener`](lua://Encounter.createBattleDarkener).
---
---@class BattleDarkener : Object
---
---@field position number An offset used to scroll the background.
---@field position2 number Another offset used to scroll the background.
---@field move_speed number The speed at which the background scrolls.
---@field private fading_out boolean Whether the background is currently fading out or not.
---
---@overload fun() : BattleDarkener
local BattleDarkener, super = Class(Object)

function BattleDarkener:init()
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.debug_select = false

    self.layer = BATTLE_LAYERS["darkener"]

    self.darken = true
    self.dark_amount = 0

    self:setParallax(0, 0)
end

function BattleDarkener:undarken()
    self.darken = false
end

function BattleDarkener:update()
    if self.darken then
        -- Darken party members
        for _, battler in ipairs(Game.battle.party) do
            battler.should_darken = true
        end

        self.dark_amount = MathUtils.approach(self.dark_amount, 15, DTMULT)
    else
        -- Undarken party members
        for _, battler in ipairs(Game.battle.party) do
            battler.should_darken = false
        end

        self.dark_amount = MathUtils.approach(self.dark_amount, 0, DTMULT)

        if self.dark_amount <= 0 then
            self:remove()
            Game.battle.darkener = nil
        end
    end
end

function BattleDarkener:draw()
    super.draw(self)

    love.graphics.setColor(0, 0, 0, self.dark_amount / 20)
    love.graphics.rectangle("fill", -40, -40, SCREEN_WIDTH + 80, SCREEN_HEIGHT + 80)
end

return BattleDarkener
