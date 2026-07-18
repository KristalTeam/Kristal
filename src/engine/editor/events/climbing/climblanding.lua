---@class EditorClimbLanding : EditorEvent
---@overload fun(data?: table, options?: table): EditorClimbLanding
local EditorClimbLanding = Class(EditorEvent)
function EditorClimbLanding:createObject(map, context)
    return ClimbLanding(self.data.x, self.data.y, self:getRectData())
end

return EditorClimbLanding
