local EditorDarkFountain, super = Class(EditorEvent)
EditorDarkFountain.editor_sprite = "world/events/darkfountain/bg"
EditorDarkFountain.scaling_mode = "scale"
function EditorDarkFountain:init(data, options)
    super.init(self, data, options)
    self:registerProperty("narrow", "boolean")
end
return EditorDarkFountain
