local Savepoint, super = Class(Interactable)

function Savepoint:init(x, y, properties)
    super:init(self, x, y, nil, nil, properties)

    self.marker = properties and properties["marker"]

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
    self.world:openMenu(SaveMenu(self.marker))
    --Assets.playSound("snd_save")
end

return Savepoint