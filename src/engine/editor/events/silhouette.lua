---@class EditorSilhouette : EditorEvent
---@overload fun(data?: table, options?: table): EditorSilhouette
local EditorSilhouette, super = Class(EditorEvent)
EditorSilhouette.placement_shape = "region"
function EditorSilhouette:init(data, options)
    super.init(self, data, options)
    self:registerProperty("color", "color", { default = "#00000080" })
end
function EditorSilhouette:createObject(map, context)
    return Silhouette(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorSilhouette
