local Script, super = Class(Event)

function Script:init(data)
    super:init(self, data.center_x, data.center_y, data.width, data.height)

    self.solid = false

    self.script = data.properties.script

    self:setOrigin(0.5, 0.5)
    self:setHitbox(0, 0, data.width, data.height)
end

function Script:onCollide(player, dir)
    Cutscene.start(self.script)
    self:remove()
    return true
end

return Script