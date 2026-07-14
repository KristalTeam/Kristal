local EditorMirrorArea, super = Class(EditorEvent)
EditorMirrorArea.placement_shape = "region"
function EditorMirrorArea:init(data, options)
    super.init(self, data, options)
    self:registerProperty("offset", "number")
    self:registerProperty("opacity", "number", { default = 1 })
end
function EditorMirrorArea:createObject(map, context)
    return MirrorArea(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorMirrorArea
