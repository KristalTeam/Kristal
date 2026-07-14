local EditorFountainFloor = Class(EditorEvent)
EditorFountainFloor.placement_shape = "region"
function EditorFountainFloor:createObject(map, context)
    return FountainFloor(self.data.x, self.data.y, self:getRectData())
end

return EditorFountainFloor
