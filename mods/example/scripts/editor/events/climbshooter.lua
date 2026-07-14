local EditorClimbShooter, super = Class(EditorEvent)

function EditorClimbShooter:init(data, options)
    super.init(self, data, options)
    self:registerProperty("timer_offset", "number", { name = "Timer Offset" })
    self:registerProperty("shoot_speed", "number", { name = "Shoot Speed" })
end

function EditorClimbShooter:createObject(map, context)
    local properties = self.data.properties
    return ClimbShooter(self.data.x, self.data.y, self:getRectData(),
        properties.timer_offset, properties.shoot_speed)
end

return EditorClimbShooter
