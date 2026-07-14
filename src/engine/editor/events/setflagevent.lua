local EditorSetFlagEvent, super = Class(EditorEvent)
EditorSetFlagEvent.placement_shape = "region"
function EditorSetFlagEvent:init(data, options)
    super.init(self, data, options)
    self:registerProperty("flag", "string")
    self:registerProperty("value", "value")
    self:registerProperty("once", "boolean")
    self:registerProperty("mapflag", "boolean", { name = "Map Flag" })
end
function EditorSetFlagEvent:createObject(map, context)
    return SetFlagEvent(self.data.x, self.data.y, self:getShapeData(), self.data.properties)
end

return EditorSetFlagEvent
