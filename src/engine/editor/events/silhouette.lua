local EditorSilhouette, super = Class(EditorEvent)
EditorSilhouette.placement_shape = "region"
function EditorSilhouette:init(data, options)
    super.init(self, data, options)
    self:registerProperty("color", "color", { default = "#00000080" })
end
return EditorSilhouette
