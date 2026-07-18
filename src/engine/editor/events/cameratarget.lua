---@class EditorCameraTarget : EditorEvent
---@overload fun(data?: table, options?: table): EditorCameraTarget
local EditorCameraTarget, super = Class(EditorEvent)
EditorCameraTarget.placement_shape = "region"
function EditorCameraTarget:init(data, options)
    super.init(self, data, options)
    self:registerProperty("x", "number")
    self:registerProperty("y", "number")
    self:registerProperty("marker", "object_reference", { allowed_types = { "marker", "player" } })
    self:registerProperty("lockx", "boolean", { name = "Lock X", default = true })
    self:registerProperty("locky", "boolean", { name = "Lock Y", default = true })
    self:registerProperty("speed", "number")
    self:registerProperty("returnspeed", "number", { name = "Return Speed" })
    self:registerProperty("time", "number")
    self:registerProperty("returntime", "number", { name = "Return Time" })
end
function EditorCameraTarget:createObject(map, context)
    local data = self.data
    return CameraTarget(data.x, data.y, self:getShapeData(), data.properties)
end

return EditorCameraTarget
