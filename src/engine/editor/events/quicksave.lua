---@class EditorQuicksave : EditorEvent
---@overload fun(data?: table, options?: table): EditorQuicksave
local EditorQuicksave, super = Class(EditorEvent)
function EditorQuicksave:init(data, options)
    super.init(self, data, options)
    self:registerProperty("marker", "object_reference", { allowed_types = { "marker", "player" } })
end
function EditorQuicksave:createObject(map, context)
    return QuicksaveEvent(self.data.x, self.data.y, self:getShapeData(), self.data.properties.marker)
end

return EditorQuicksave
