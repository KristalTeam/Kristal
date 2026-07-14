local EditorClimbArea = Class(EditorEvent)
EditorClimbArea.placement_shape = "region"
function EditorClimbArea:createObject(map, context)
    return ClimbArea(self.data.x, self.data.y, self:getRectData())
end

return EditorClimbArea
