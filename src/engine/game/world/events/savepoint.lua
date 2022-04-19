local Savepoint, super = Class(Readable)

function Savepoint:init(text, x, y)
    super:init(self, text, x, y)

    self.solid = true

    self:setOrigin(0.5, 0.5)
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
    self.world:openMenu(SaveMenu())
    --Assets.playSound("snd_save")
end

return Savepoint