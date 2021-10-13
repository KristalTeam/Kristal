local Hitbox, super = Class(Collider)

function Hitbox:init(x, y, width, height)
    super:init(self, x, y)

    self.width = width or 0
    self.height = height or 0
end

function Hitbox:collidesWith(other, symmetrical)
    if not isClass(other) then return false end

    if other:includes(Hitbox) then
        return self:collideWithHitbox(other) or (not symmetrical and other:collideWithHitbox(self))
    end
end

function Hitbox:collideWithHitbox(other)
    local tf = self:getTransform()
    local otf = other:getTransform()

    local x1, y1, x2, y2, x3, y3, x4, y4
    if otf then
        x1, y1 = otf:inverseTransformPoint(other.x, other.y)
        x2, y2 = otf:inverseTransformPoint(other.x + other.width, other.y)
        x3, y3 = otf:inverseTransformPoint(other.x, other.y + other.height)
        x4, y4 = otf:inverseTransformPoint(other.x + other.width, other.y + other.height)
    else
        x1, y1 = other.x, other.y
        x2, y2 = other.x + other.width, other.y
        x3, y3 = other.x, other.y + other.height
        x4, y4 = other.x + other.width, other.y + other.height
    end

    if tf then
        x1, y1 = tf:transformPoint(x1, y1)
        x2, y2 = tf:transformPoint(x2, y2)
        x3, y3 = tf:transformPoint(x3, y3)
        x4, y4 = tf:transformPoint(x4, y4)
    end

    return (x1 >= self.x and x1 < self.x + self.width and y1 >= self.y and y1 < self.y + self.height) or
           (x2 >= self.x and x2 < self.x + self.width and y2 >= self.y and y2 < self.y + self.height) or
           (x3 >= self.x and x3 < self.x + self.width and y3 >= self.y and y3 < self.y + self.height) or
           (x4 >= self.x and x4 < self.x + self.width and y4 >= self.y and y4 < self.y + self.height)
end

return Hitbox