local EditorClimbEntry, super = Class(EditorEvent)
function EditorClimbEntry:init(data, options)
    super.init(self, data, options)
    self:registerProperty("target", "object_reference", { marker = true })
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
