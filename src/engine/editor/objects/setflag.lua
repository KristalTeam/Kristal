---@class EditorSetFlagObject : EditorObject
---@overload fun(data?: table, options?: table): EditorSetFlagObject
local EditorSetFlagObject, super = Class(EditorObject)
EditorSetFlagObject.placement_shape = "region"
function EditorSetFlagObject:init(data, options)
    super.init(self, data, options)
    self:registerProperty("flag", "string")
    self:registerProperty("value", "value")
    self:registerProperty("once", "boolean")
    self:registerProperty("mapflag", "boolean", { name = "Map Flag" })
end
function EditorSetFlagObject:createObject(map, context)
    return SetFlagEvent(self.data.x, self.data.y, self:getShapeData(), self.data.properties)
end

return EditorSetFlagObject
