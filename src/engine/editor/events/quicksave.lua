local EditorQuicksave, super = Class(EditorEvent)
function EditorQuicksave:init(data, options)
    super.init(self, data, options)
    self:registerProperty("marker", "object_reference", { marker = true })
end
return EditorQuicksave
