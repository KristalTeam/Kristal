---@class EditorFountainShadowController : EditorEvent
local EditorFountainShadowController, super = Class(EditorEvent)

function EditorFountainShadowController:init(data, options)
    super.init(self, data, options)
end

function EditorFountainShadowController:createObject(map, context)
    return FountainShadowController(self.data.properties)
end

return EditorFountainShadowController
