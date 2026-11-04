---@class EditorClimbLanding : EditorObject
---@overload fun(data?: table, options?: table): EditorClimbLanding
local EditorClimbLanding = Class(EditorObject)
EditorClimbLanding.editor_sprite = "editor/climblanding"
function EditorClimbLanding:createObject(map, context)
    return ClimbLanding(self.data.x, self.data.y, self:getRectData())
end

return EditorClimbLanding
