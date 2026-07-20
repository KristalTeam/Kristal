---@class EditorHideParty : EditorObject
---@overload fun(data?: table, options?: table): EditorHideParty
local EditorHideParty, super = Class(EditorObject)
EditorHideParty.placement_shape = "region"
function EditorHideParty:init(data, options)
    super.init(self, data, options)
    self:registerProperty("alpha", "number")
end
function EditorHideParty:createObject(map, context)
    return HideParty(self.data.x, self.data.y, self:getShapeData(), self.data.properties.alpha)
end

return EditorHideParty
