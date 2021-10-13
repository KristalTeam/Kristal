local Savepoint, super = Class(Event)

function Savepoint:init(data)
    super:init(self, data.center_x, data.center_y, data.width, data.height)

    self.solid = true

    self:setOrigin(0.5, 0.5)
    self:setSprite("world/event/savepoint", 1/6)
end

return Savepoint