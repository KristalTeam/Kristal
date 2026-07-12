local EditorFallingClimbArea, super = Class(EditorEvent)
EditorFallingClimbArea.placement_shape = "region"
function EditorFallingClimbArea:init(data, options)
    super.init(self, data, options)
    self:registerProperty("dont_break", "boolean", { name = "Don't Break" })
    self:registerProperty("breaks_on_leave", "boolean", { name = "Breaks On Leave" })
    self:registerProperty("fall_time", "number", { name = "Fall Time" })
    self:registerProperty("timed", "boolean")
    self:registerProperty("no_unsafe_area", "boolean", { name = "No Unsafe Area" })
end
return EditorFallingClimbArea
