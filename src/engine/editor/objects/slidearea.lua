---@class EditorSlideArea : EditorObject
---@overload fun(data?: table, options?: table): EditorSlideArea
local EditorSlideArea, super = Class(EditorObject)
EditorSlideArea.placement_shape = "region"
function EditorSlideArea:init(data, options)
    super.init(self, data, options)
    self:registerProperty("lock", "boolean")
end
function EditorSlideArea:createObject(map, context)
    return SlideArea(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorSlideArea
