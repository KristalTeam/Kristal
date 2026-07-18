---@class EditorDarkFountain : EditorEvent
---@overload fun(data?: table, options?: table): EditorDarkFountain
local EditorDarkFountain, super = Class(EditorEvent)
EditorDarkFountain.editor_sprite = "world/events/darkfountain/bg"
EditorDarkFountain.scaling_mode = "scale"
function EditorDarkFountain:init(data, options)
    super.init(self, data, options)
    self:registerProperty("narrow", "boolean")
end
function EditorDarkFountain:createObject(map, context)
    return DarkFountain(self.data.x, self.data.y, self.data.properties)
end

return EditorDarkFountain
