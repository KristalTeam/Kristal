local InteractScript, super = Class(Event)

function InteractScript:init(data)
    super:init(self, data.center_x, data.center_y, data.width, data.height)

    self.solid = false

    self.script = data.properties.script

    self:setOrigin(0.5, 0.5)
    self:setHitbox(0, 0, data.width, data.height)
end

function InteractScript:onInteract(player, dir)
    Cutscene.start(self.script)
    return true
end

return InteractScript