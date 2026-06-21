--- The "Squeak" object. On interaction, this will play a squeak sound.
---@class Squeak : Event
local Squeak, super = Class(Event, "Squeak")

---@param x number
---@param y number
---@param shape EventShape?
function Squeak:init(x, y, shape)
    super.init(self, x, y, shape)
end

function Squeak:onInteract(player, dir)
    -- When we interact with this object, play the squeak sound.
    Assets.playSound("squeak")

    -- We've handled an interaction, so return true! This prevents multiple interactions happening at once.
    return true
end

return Squeak
