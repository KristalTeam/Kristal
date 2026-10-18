---@class EditorFountainShadowController : EditorObject
---@overload fun(data?: table, options?: table): EditorFountainShadowController
local EditorFountainShadowController, super = Class(EditorObject)

EditorFountainShadowController.editor_sprite = "editor/fountainshadow"
EditorFountainShadowController.runtime_type = "controller"
EditorFountainShadowController.placement_shape = "point"
EditorFountainShadowController.fixed_shape = "point"

function EditorFountainShadowController:init(data, options)
    super.init(self, data, options)
end

function EditorFountainShadowController:createObject(map, context)
    return FountainShadowController(self.data.properties)
end

return EditorFountainShadowController
