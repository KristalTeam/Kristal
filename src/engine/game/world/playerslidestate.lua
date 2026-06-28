---@class PlayerSlideState : PlayerSlideBaseState
---
---@field player Player
---
---@overload fun(player: Player) : PlayerSlideState
local PlayerSlideState, super = Class(PlayerSlideBaseState)

function PlayerSlideState:init(player)
    super.init(self, player)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function PlayerSlideState:handleMovement()
    local slide_x = 0

    if self.player:isMovementEnabled() then
        if Input.down("right") then slide_x = slide_x + 1 end
        if Input.down("left") then slide_x = slide_x - 1 end
    end

    self.player:move(slide_x, 2, 6 * DTMULT)
end

return PlayerSlideState
