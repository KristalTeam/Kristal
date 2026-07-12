local EditorDarkFountain, super = Class(EditorEvent)
EditorDarkFountain.editor_sprite = "world/events/darkfountain/bg"
function EditorDarkFountain:init(data, options)
    super.init(self, data, options)
    self:registerProperty("narrow", "boolean")
end
return EditorDarkFountain
