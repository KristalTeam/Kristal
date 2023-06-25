---@class Shopbox : Object
---@overload fun(...) : Shopbox
local Shopbox, super = Class(Object)

function Shopbox:init()
    super.init(self, 56, 220)

    self:setParallax(0, 0)

    if Game.world and Game.world.player and Game.world.camera then
        local player_x, _ = Game.world.player:localToScreenPos()
        if player_x <= 320 then
            self.x = self.x + 320
        end
    end

    self.box = UIBox(0, 0, 201, 57)
    self.box.layer = -1
    self:addChild(self.box)

    self.font = Assets.getFont("main")
end

function Shopbox:draw()
    super.draw(self)

    local pocket = Game.inventory:getFreeSpace("items", false)
    local storage = Game.inventory:getFreeSpace("storage")

    love.graphics.setFont(self.font)
    Draw.setColor(PALETTE["world_text"])
    love.graphics.print("$" .. Game.money, 28 - 36, 308 - 220 - 100)
    love.graphics.print("HELD SPACE: "    .. pocket , 28 - 36, 308 + 30 - 4 - 220 - 100)
    love.graphics.print("STORAGE SPACE: " .. storage , 28 - 36, 308 + 60 - 8 - 220 - 100)
end

return Shopbox