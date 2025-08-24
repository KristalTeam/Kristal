---@class Object : Object
local Object, super = Utils.hookScript(Object)

-- sorry hyperboid its awesome but we gotta kill it
--[[
function Object:preparefunny()
    if self.funny_rng then return end
    local rng = love.math.newRandomGenerator((tonumber((tostring(self)):sub(18), 16)/10000))
    for i=1,6 do
        rng:random()
    end
    self.funny_rng = (rng:random()-0.5) * 2
end

function Object:applyTransformTo(transform, ...)
    self:preparefunny()
    -- super.applyTransformTo(self, transform, ...)
    if Input.down("f") then
        transform:rotate(math.sin(RUNTIME * self.funny_rng)/5)
    end
    super.applyTransformTo(self, transform, ...)
end
]]

return Object
