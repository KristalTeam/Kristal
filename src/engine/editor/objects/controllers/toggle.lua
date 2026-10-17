---@class EditorToggleController : EditorObject
---@overload fun(data?: table, options?: table): EditorToggleController
local EditorToggleController, super = Class(EditorObject)

EditorToggleController.editor_sprite = "editor/toggle"
EditorToggleController.runtime_type = "controller"
EditorToggleController.placement_shape = "point"
EditorToggleController.fixed_shape = "point"

function EditorToggleController:init(data, options)
    super.init(self, data, options)
    self:registerProperty("flag", "string")
    self:registerProperty("inverted", "boolean")
    self:registerProperty("value", "value")
    self:registerProperty("target", "table", {
        name = "Targets", array = true, entry_type = "object_reference",
        entry_options = { map_id = self.map_id }
    })
end

function EditorToggleController:createObject(map, context)
    return ToggleController(self.data.properties)
end

return EditorToggleController
