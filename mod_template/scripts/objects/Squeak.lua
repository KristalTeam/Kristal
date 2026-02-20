---@class Squeak : Event
local Squeak, super = Class(Event)

function Squeak:init(x, y, shape)
    super.init(self, x, y, shape)
end

function Squeak:onInteract(player, dir)
    Assets.playSound("squeak")
    return true
end

return Squeak
