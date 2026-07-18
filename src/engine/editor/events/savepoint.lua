---@class EditorSavepoint : EditorEvent
---@overload fun(data?: table, options?: table): EditorSavepoint
local EditorSavepoint, super = Class(EditorEvent)
EditorSavepoint.editor_sprite = "world/events/savepoint"
EditorSavepoint.scaling_mode = "scale"

function EditorSavepoint:init(data, options)
    super.init(self, data, options)
    self:registerProperty("marker", "object_reference", { allowed_types = { "marker", "player" } })
    self:registerProperty("simple", "boolean")
    self:registerProperty("text_once", "string", { name = "Text Once" })
    self:registerProperty("heals", "boolean")
end

function EditorSavepoint:createObject(map, context)
    return Savepoint(self.data.center_x, self.data.center_y, self.data.properties)
end

return EditorSavepoint
