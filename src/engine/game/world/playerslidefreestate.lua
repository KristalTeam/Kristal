---@class PlayerSlideFreeState : PlayerSlideBaseState
---
---@overload fun(player: Player) : PlayerSlideFreeState
local PlayerSlideFreeState, super = Class(PlayerSlideBaseState)

function PlayerSlideFreeState:init(player)
    super.init(self, player)
end

function PlayerSlideFreeState:registerEvents()
    super.registerEvents(self)
    self:registerEvent("checkRunningInput", self.checkRunningInput)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function PlayerSlideFreeState:checkRunningInput()
    self.player.run_timer = 50
    return true
end

function PlayerSlideFreeState:handleMovement()
    if self.player:isMovementEnabled() then
        self.player:handleMovement()
    end
end

function PlayerSlideFreeState:checkSlideEnd()
end

return PlayerSlideFreeState
