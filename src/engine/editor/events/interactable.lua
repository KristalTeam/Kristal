local EditorInteractable, super = Class(EditorEvent)

EditorInteractable.editor_sprite = "editor/interactable"
function EditorInteractable:init(data, options)
    super.init(self, data, options)
    self:registerProperty("solid", "boolean")
    self:registerProperty("cutscene", "string")
    self:registerProperty("script", "string")
    self:registerProperty("setflag", "string", { name = "Set Flag" })
    self:registerProperty("setvalue", "value", { name = "Set Value" })
    self:registerProperty("once", "boolean")
    self:registerProperty("usetile", "boolean", { name = "Use Tile" })
end

return EditorInteractable
