---@class EditorFountainShadowController : EditorEvent
---@overload fun(data?: table, options?: table): EditorFountainShadowController
local EditorFountainShadowController, super = Class(EditorEvent)

EditorFountainShadowController.runtime_type = "controller"

function EditorFountainShadowController:init(data, options)
    super.init(self, data, options)
end

function EditorFountainShadowController:createObject(map, context)
    return FountainShadowController(self.data.properties)
end

return EditorFountainShadowController
