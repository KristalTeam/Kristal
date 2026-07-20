---@class EditorClimbEntry : EditorObject
---@overload fun(data?: table, options?: table): EditorClimbEntry
local EditorClimbEntry, super = Class(EditorObject)
function EditorClimbEntry:init(data, options)
    super.init(self, data, options)
    self:registerProperty("target", "object_reference", { allowed_types = { "climbexit" } })
    self:registerProperty("solid", "boolean")
end
function EditorClimbEntry:createObject(map, context)
    local properties = self.data.properties
    return ClimbEntry(self.data.x, self.data.y, self:getRectData(), {
        target = properties.target,
        solid = properties.solid
    })
end

return EditorClimbEntry
