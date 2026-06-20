--- A ClimbLanding is an area the player can land on after falling while climbing.
---
--- `ClimbLanding` is an [`Event`](lua://Event.init) - naming an object `climblanding` on an `objects` layer in a map creates this object.
---
---@class ClimbLanding : Event
---
---@overload fun(...) : ClimbLanding
local ClimbLanding, super = Class(Event)

---@param x number?
---@param y number?
---@param shape EventShape?
function ClimbLanding:init(x, y, shape)
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)
end

return ClimbLanding
