local EditorForcefield, super = Class(EditorEvent)
EditorForcefield.editor_sprite = "world/events/forcefield/single"
function EditorForcefield:init(data, options)
    super.init(self, data, options)
    self:registerProperty("solid", "boolean", { default = true })
    self:registerProperty("visible", "boolean")
end
function EditorForcefield:createObject(map, context)
    return Forcefield(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorForcefield
