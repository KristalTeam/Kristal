--- An overworld object that triggers a [Quicksave](lua://Game.saveQuick) when entered. \
--- `QuicksaveEvent` is an [`Event`](lua://Event.init) - naming an object `quicksave` on an `objects` layer in a map creates this objects. \
--- See this object's Fields for the configurable properties on this object.
--- 
---@class QuicksaveEvent : Event
---
---@field marker string *[Property `marker`]* The name of the marker to use for spawning the party when loading the quicksave
---
---@overload fun(...) : QuicksaveEvent
local QuicksaveEvent, super = Class(Event)

---@param x number
---@param y number
---@param shape {[1]: number, [2]: number, [3]: table?}? Shape data for this event. First two indexes are the width and height of the object. The third (optional) index is polygon data.
---@param marker string? The name of the marker to use for spawning the party when loading the quicksave
function QuicksaveEvent:init(x, y, shape, marker)
    super.init(self, x, y, shape)
    self.marker = marker
end

function QuicksaveEvent:onEnter()
    Game:saveQuick(self.marker)
end

return QuicksaveEvent
