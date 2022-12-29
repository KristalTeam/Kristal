---@class Anchor : Object
---@overload fun(...) : Anchor
local Anchor, super = Class(Object)

function Anchor:init(ox, oy)
    super.init(self, 0, 0)

    self.ox = ox
    self.oy = oy
end

function Anchor:setAnchor(ox, oy)
    self.ox = ox
    self.oy = oy
end

function Anchor:getAnchor()
    return self.ox, self.oy
end

function Anchor:applyTransformTo(transform)
    -- Hacky way to translate by something other than X and Y
    local last_x, last_y = self.x, self.y
    self.x = self.parent.width * self.ox
    self.y = self.parent.height * self.oy
    super.applyTransformTo(self, transform)
    self.x, self.y = last_x, last_y
end

--[[function Anchor:createTransform()
    local transform = love.math.newTransform()
    transform:translate(self.parent.width * self.ox, self.parent.height * self.oy)
    if (self.parallax_x or self.parallax_y) and self.parent and self.parent.camera then
        transform:translate(self.parent.camera:getParallax(self.parallax_x or 1, self.parallax_y or 1))
    end
    if self.flip_x or self.flip_y then
        transform:translate(self.width/2, self.height/2)
        transform:scale(self.flip_x and -1 or 1, self.flip_y and -1 or 1)
        transform:translate(-self.width/2, -self.height/2)
    end
    local ox, oy = self:getOriginExact()
    transform:translate(-ox, -oy)
    if self.rotation ~= 0 then
        local ox, oy = self:getRotationOriginExact()
        transform:translate(ox, oy)
        transform:rotate(self.rotation)
        transform:translate(-ox, -oy)
    end
    if self.scale_x ~= 1 or self.scale_y ~= 1 then
        local ox, oy = self:getScaleOriginExact()
        transform:translate(ox, oy)
        transform:scale(self.scale_x, self.scale_y)
        transform:translate(-ox, -oy)
    end
    return transform
end]]

return Anchor