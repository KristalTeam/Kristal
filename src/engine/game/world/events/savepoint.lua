local Savepoint, super = Class(Readable)

function Savepoint:init(data)
    super:init(self, data)

    self.solid = true

    self:setSprite("world/event/savepoint", 1/6)
end

function Savepoint:onInteract(player, dir)
    Assets.playSound("snd_power")
    super:onInteract(self)
    return true
end

function Savepoint:onTextEnd()
    Assets.playSound("snd_save")
end

return Savepoint