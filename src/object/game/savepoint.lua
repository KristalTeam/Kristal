local Savepoint, super = Class(Event)

function Savepoint:init(x, y, o)
    super:init(self, x, y, 0, 0)

    self:setSprite("world/event/savepoint", 1/6)

    self.solid = true
end

return Savepoint