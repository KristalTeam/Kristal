local EditorClimbEntry, super = Class(EditorEvent)
function EditorClimbEntry:init(data, options)
    super.init(self, data, options)
    self:registerProperty("target", "object_reference", { marker = true })
    self:registerProperty("solid", "boolean")
end
return EditorClimbEntry
