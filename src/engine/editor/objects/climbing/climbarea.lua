---@class EditorClimbArea : EditorObject
---@overload fun(data?: table, options?: table): EditorClimbArea
local EditorClimbArea = Class(EditorObject)
EditorClimbArea.placement_shape = "region"
function EditorClimbArea:createObject(map, context)
    return ClimbArea(self.data.x, self.data.y, self:getRectData())
end

return EditorClimbArea
