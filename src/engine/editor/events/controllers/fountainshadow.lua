---@class EditorFountainShadowController : EditorEvent
local EditorFountainShadowController, super = Class(EditorEvent)

function EditorFountainShadowController:init(data, options)
    super.init(self, data, options)
end

return EditorFountainShadowController
