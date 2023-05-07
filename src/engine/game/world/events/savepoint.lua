---@class Savepoint : Interactable
---@overload fun(...) : Savepoint
local Savepoint, super = Class(Interactable)

function Savepoint:init(x, y, properties)
    super.init(self, x, y, nil, nil, properties)

    self.marker = properties and properties["marker"]

    self.simple_menu = properties["simple"]

    self.solid = true

    self:setOrigin(0.5, 0.5)
    self:setSprite("world/events/savepoint", 1/6)

    self.text_once = properties["text_once"]
    self.used = false

    local width, height = self:getSize()
    self:setHitbox(0, height / 2, width, height / 2)
end

function Savepoint:onInteract(player, dir)
    Assets.playSound("power")

    if self.text_once and self.used then
        self:onTextEnd()
        return
    end

    if self.text_once then
        self.used = true
    end

    super.onInteract(self, player, dir)
    return true
end

function Savepoint:onTextEnd()
    if not self.world then return end

    for _,party in ipairs(Game.party) do
        party:heal(math.huge, false)
    end
    if self.simple_menu or (self.simple_menu == nil and (Game:isLight() or Game:getConfig("smallSaveMenu"))) then
        self.world:openMenu(SimpleSaveMenu(Game.save_id, self.marker))
    else
        self.world:openMenu(SaveMenu(self.marker))
    end
end

return Savepoint