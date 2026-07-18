---@class EditorClimbExit : EditorEvent
---@overload fun(data?: table, options?: table): EditorClimbExit
local EditorClimbExit, super = Class(EditorEvent)
function EditorClimbExit:init(data, options)
    super.init(self, data, options)
    self:registerProperty("target", "object_reference", { allowed_types = { "marker", "player" } })
    self:registerProperty("direction", "choice", { choices = { "up", "down", "left", "right" } })
    self:registerProperty("can_exit", "boolean", { name = "Can Exit", default = true })
end
function EditorClimbExit:createObject(map, context)
    local properties = self.data.properties
    return ClimbExit(self.data.x, self.data.y, self:getRectData(), {
        target = properties.target,
        direction = properties.direction,
        can_exit = properties.can_exit
    })
end

return EditorClimbExit
