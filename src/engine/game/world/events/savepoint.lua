local Savepoint, super = Class(Readable)

function Savepoint:init(data)
    super:init(self, data)

    self.solid = true

    self:setSprite("world/event/savepoint", 1/6)
end

function Savepoint:onInteract(player, dir)
    Assets.playSound("snd_power")
    for _,party in ipairs(Game.party) do
        party:heal(math.huge, false)
    end
    super:onInteract(self, player, dir)
    return true
end

function Savepoint:onTextEnd()
    self.world:openMenu(DarkSaveMenu())
    --Assets.playSound("snd_save")
end

return Savepoint