--- A ClimbArea is an area the player can climb on.
---
--- To enter one, you must either use a [`ClimbEntry`](lua://ClimbEntry), or enter the room at a marker with "player_state" set to "CLIMB".
---
--- To exit one, you must use a [`ClimbExit`](lua://ClimbExit).
---
--- `ClimbArea` is an [`Event`](lua://Event.init) - naming an object `climbarea` on an `objects` layer in a map creates this object.
---
---@class ClimbArea : Event
---
---@overload fun(...) : ClimbArea
local ClimbArea, super = Class(Event)

---@param x number?
---@param y number?
---@param shape EventShape?
function ClimbArea:init(x, y, shape)
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)

    self.climbable = true
end

--- *(Override)* Called when the player finishes a move on this area. Examples being moving, jumping, or falling onto this area.
---@param player Player
function ClimbArea:onClimbMove(player)
end

--- Whether or not this area can be climbed on.
function ClimbArea:isClimbable()
    return self.climbable
end

--- Sets whether or not this area can be climbed on.
function ClimbArea:setClimbable(climbable)
    self.climbable = climbable
end

function ClimbArea:drawDebug()
    self.collider:draw(0, 1, 1)
end

return ClimbArea
