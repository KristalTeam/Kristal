local EditorMirrorArea, super = Class(EditorEvent)
EditorMirrorArea.placement_shape = "region"
function EditorMirrorArea:init(data, options)
    super.init(self, data, options)
    self:registerProperty("offset", "number")
    self:registerProperty("opacity", "number", { default = 1 })
end
return EditorMirrorArea
