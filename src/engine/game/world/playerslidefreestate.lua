---@class PlayerSlideFreeState : PlayerSlideBaseState
---
---@overload fun(player: Player) : PlayerSlideFreeState
local PlayerSlideFreeState, super = Class(PlayerSlideBaseState)

function PlayerSlideFreeState:init(player)
    super.init(self, player)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function PlayerSlideFreeState:handleMovement()
    local slide_x = 0
    local slide_y = 0

    if self.player:isMovementEnabled() then
        if Input.down("right") then slide_x = slide_x + 1 end
        if Input.down("left") then slide_x = slide_x - 1 end
        if Input.down("down") then slide_y = slide_y + 1 end
        if Input.down("up") then slide_y = slide_y - 1 end
    end

    self.player:move(slide_x, slide_y, 6 * DTMULT)
end

function PlayerSlideFreeState:checkSlideEnd()
end

return PlayerSlideFreeState
