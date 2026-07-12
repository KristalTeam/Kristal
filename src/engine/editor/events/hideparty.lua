local EditorHideParty, super = Class(EditorEvent)
EditorHideParty.placement_shape = "region"
function EditorHideParty:init(data, options)
    super.init(self, data, options)
    self:registerProperty("alpha", "number")
end
return EditorHideParty
