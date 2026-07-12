local EditorSlideArea, super = Class(EditorEvent)
EditorSlideArea.placement_shape = "region"
function EditorSlideArea:init(data, options)
    super.init(self, data, options)
    self:registerProperty("lock", "boolean")
end
return EditorSlideArea
