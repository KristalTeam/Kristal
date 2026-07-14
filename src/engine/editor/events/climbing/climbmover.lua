local EditorClimbMover, super = Class(EditorEvent)

EditorClimbMover.editor_sprite = "world/events/climb_mover"
function EditorClimbMover:init(data, options)
    super.init(self, data, options)
    self:registerProperty("target", "object_reference", { marker = true })
    self:registerProperty("exit", "object_reference", { marker = true })
    self:registerProperty("start_exit", "object_reference", { name = "Start Exit", marker = true })
    self:registerProperty("one_way", "boolean", { name = "One Way" })
end
function EditorClimbMover:createObject(map, context)
    local properties = self.data.properties
    return ClimbMover(self.data.x, self.data.y, self:getRectData(), {
        target = properties.target,
        exit = properties.exit,
        start_exit = properties.start_exit,
        one_way = properties.one_way
    })
end

return EditorClimbMover
