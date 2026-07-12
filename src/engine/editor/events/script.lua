local EditorScriptEvent, super = Class(EditorEvent)

EditorScriptEvent.placement_shape = "region"

function EditorScriptEvent:init(data, options)
    super.init(self, data, options)
    self:registerProperty("cutscene", "string")
    self:registerProperty("script", "string")
    self:registerProperty("setflag", "string", { name = "Set Flag" })
    self:registerProperty("setvalue", "value", { name = "Set Value" })
    self:registerProperty("once", "boolean", { default = true })
    self:registerProperty("temp", "boolean")
end

return EditorScriptEvent
