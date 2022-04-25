local Savepoint, super = Class(Interactable)

function Savepoint:init(x, y, properties)
    super:init(self, x, y, nil, nil, properties)

    self.marker = properties and properties["marker"]

    self.simple_menu = properties["simple"]

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
    if self.simple_menu or (self.simple_menu == nil and (Game:isLight() or Game:getConfig("smallSaveMenu"))) then
        self.world:openMenu(SimpleSaveMenu(Game.save_id, self.marker))
    else
        self.world:openMenu(SaveMenu(self.marker))
    end
end

return Savepoint