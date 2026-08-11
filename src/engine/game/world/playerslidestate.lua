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
    super.handleMovement(self)

    if self.player:isMovementEnabled() then
        local slide_x = 0

        if Input.down("right") then
            slide_x = slide_x + (6 * DTMULT)
        end
        if Input.down("left") then
            slide_x = slide_x - (6 * DTMULT)
        end

        if slide_x ~= 0 then
            if not self.player:shouldCollideWithSolids() or not self.player:checkSolidCollisionAt(self.player.x + slide_x, self.player.y) then
                self.player.x = self.player.x + slide_x
            end
        end
    end
end

return PlayerSlideState
