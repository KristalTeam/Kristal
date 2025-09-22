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

function QuicksaveEvent:init(x, y, shape, marker)
    super.init(self, x, y, shape)
    self.marker = marker
end

function QuicksaveEvent:onEnter()
    Game:saveQuick(self.marker)
end

return QuicksaveEvent