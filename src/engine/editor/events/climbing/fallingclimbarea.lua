---@class EditorFallingClimbArea : EditorEvent
---@overload fun(data?: table, options?: table): EditorFallingClimbArea
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
function EditorFallingClimbArea:createObject(map, context)
    local properties = self.data.properties
    return FallingClimbArea(self.data.x, self.data.y, self:getRectData(), {
        dont_break = properties.dont_break,
        breaks_on_leave = properties.breaks_on_leave,
        fall_time = properties.fall_time,
        timed = properties.timed,
        no_unsafe_area = properties.no_unsafe_area
    })
end

return EditorFallingClimbArea
