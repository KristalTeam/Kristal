local EditorSavepoint, super = Class(EditorEvent)
EditorSavepoint.editor_sprite = "world/events/savepoint"

function EditorSavepoint:init(data, options)
    super.init(self, data, options)
    self:registerProperty("marker", "object_reference", { marker = true })
    self:registerProperty("simple", "boolean")
    self:registerProperty("text_once", "string", { name = "Text Once" })
    self:registerProperty("heals", "boolean")
end

return EditorSavepoint
