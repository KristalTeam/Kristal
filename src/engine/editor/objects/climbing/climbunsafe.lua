---@class EditorClimbUnsafe : EditorObject
---@overload fun(data?: table, options?: table): EditorClimbUnsafe
local EditorClimbUnsafe = Class(EditorObject)
EditorClimbUnsafe.placement_shape = "region"
function EditorClimbUnsafe:createObject(map, context)
    return ClimbUnsafe(self.data.x, self.data.y, self:getRectData())
end

return EditorClimbUnsafe
