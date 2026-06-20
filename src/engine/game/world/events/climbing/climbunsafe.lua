--- A ClimbUnsafe event is an area deemed unsafe. Climbing sometimes needs the player's last "safe location" (ex. when you fall off the map, it tries to put you back somewhere safe). This object is to denote where may be unsafe.
---
--- `ClimbUnsafe` is an [`Event`](lua://Event.init) - naming an object `climbunsafe` on an `objects` layer in a map creates this object.
---
---@class ClimbUnsafe : Event
---
---@overload fun(...) : ClimbUnsafe
local ClimbUnsafe, super = Class(Event)

---@param x number?
---@param y number?
---@param shape EventShape?
function ClimbUnsafe:init(x, y, shape)
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)
end

function ClimbUnsafe:drawDebug()
    self.collider:draw(1, 1, 0)
end

return ClimbUnsafe
