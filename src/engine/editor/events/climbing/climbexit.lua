local EditorClimbExit, super = Class(EditorEvent)
function EditorClimbExit:init(data, options)
    super.init(self, data, options)
    self:registerProperty("target", "object_reference", { marker = true })
    self:registerProperty("direction", "choice", { choices = { "up", "down", "left", "right" } })
    self:registerProperty("can_exit", "boolean", { name = "Can Exit", default = true })
end
return EditorClimbExit
