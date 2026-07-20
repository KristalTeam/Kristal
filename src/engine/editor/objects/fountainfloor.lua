---@class EditorFountainFloor : EditorObject
---@overload fun(data?: table, options?: table): EditorFountainFloor
local EditorFountainFloor = Class(EditorObject)
EditorFountainFloor.placement_shape = "region"
function EditorFountainFloor:createObject(map, context)
    return FountainFloor(self.data.x, self.data.y, self:getRectData())
end

return EditorFountainFloor
