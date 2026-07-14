local EditorOutline = Class(EditorEvent)
EditorOutline.placement_shape = "region"
function EditorOutline:createObject(map, context)
    return Outline(self.data.x, self.data.y, self:getRectData())
end

return EditorOutline
