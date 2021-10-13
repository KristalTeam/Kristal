local Hitbox, super = Class(Collider)

function Hitbox:init(x, y, width, height, parent)
    super:init(self, x, y, parent)

    self.width = width or 0
    self.height = height or 0
end

function Hitbox:collidesWith(other, symmetrical)
    if not isClass(other) then return false end

    if other:includes(Hitbox) then
        return self:collideWithHitbox(other) or (not symmetrical and other:collideWithHitbox(self, true))
    end
end

function Hitbox:collideWithHitbox(other)
    local x1, y1 = self:getPointFor(other, 0, 0)
    local x2, y2 = self:getPointFor(other, other.width, 0)
    local x3, y3 = self:getPointFor(other, 0, other.height)
    local x4, y4 = self:getPointFor(other, other.width, other.height)

    return (x1 >= self.x and x1 < self.x + self.width and y1 >= self.y and y1 < self.y + self.height) or
           (x2 >= self.x and x2 < self.x + self.width and y2 >= self.y and y2 < self.y + self.height) or
           (x3 >= self.x and x3 < self.x + self.width and y3 >= self.y and y3 < self.y + self.height) or
           (x4 >= self.x and x4 < self.x + self.width and y4 >= self.y and y4 < self.y + self.height)
end

return Hitbox