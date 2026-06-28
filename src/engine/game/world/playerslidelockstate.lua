---@class PlayerSlideLockState : PlayerSlideBaseState
---
---@field player Player
---
---@overload fun(player: Player) : PlayerSlideLockState
local PlayerSlideLockState, super = Class(PlayerSlideBaseState)

function PlayerSlideLockState:init(player)
    super.init(self, player)

    self.landed = false
    self.landed_timer = 0
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function PlayerSlideLockState:onEnter(old_state)
    super.onEnter(self, old_state)

    self.landed = false
    self.landed_timer = 0
end

function PlayerSlideLockState:updateSlideLand()
    self.landed_timer = self.landed_timer - DTMULT
    if self.landed_timer <= 0 then
        self.player:setState("WALK")
    end
end

function PlayerSlideLockState:handleMovement()
    self.player:move(0, 12, DTMULT)
end

function PlayerSlideLockState:onSlideEnd()
    self.landed = true
    self.landed_timer = 4
end

function PlayerSlideLockState:onUpdate()
    if self.landed then
        self:updateSlideLand()
        return
    end

    super.onUpdate(self)
end

return PlayerSlideLockState
