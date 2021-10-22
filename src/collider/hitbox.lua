local Hitbox, super = Class(Collider)

function Hitbox:init(x, y, width, height, parent)
    super:init(self, x, y, parent)

    self.width = width or 0
    self.height = height or 0
end

function Hitbox:collidesWith(other)
    if not isClass(other) then return false end

    if other:includes(Hitbox) then
        return self:collideWithHitbox(other) or other:collideWithHitbox(self, true)
    elseif other:includes(LineCollider) then
        return other:collidesWith(self)
    end

    return super:collidesWith(self, other)
end

function Hitbox:collideWithHitbox(other)
    Utils.pushPerformance("Hitbox#collideWithHitbox")

    local tf1, tf2 = self:getTransformsWith(other)

    local x1, y1 = other.x, other.y
    local x2, y2 = other.x + other.width, other.y
    local x3, y3 = other.x + other.width, other.y + other.height
    local x4, y4 = other.x, other.y + other.height

    if tf2 then
        x1, y1 = tf2:transformPoint(x1, y1)
        x2, y2 = tf2:transformPoint(x2, y2)
        x3, y3 = tf2:transformPoint(x3, y3)
        x4, y4 = tf2:transformPoint(x4, y4)
    end

    if tf1 then
        x1, y1 = tf1:inverseTransformPoint(x1, y1)
        x2, y2 = tf1:inverseTransformPoint(x2, y2)
        x3, y3 = tf1:inverseTransformPoint(x3, y3)
        x4, y4 = tf1:inverseTransformPoint(x4, y4)
    end

    Utils.popPerformance()

    return (x1 > self.x and x1 < self.x + self.width and y1 > self.y and y1 < self.y + self.height) or
           (x2 > self.x and x2 < self.x + self.width and y2 > self.y and y2 < self.y + self.height) or
           (x3 > self.x and x3 < self.x + self.width and y3 > self.y and y3 < self.y + self.height) or
           (x4 > self.x and x4 < self.x + self.width and y4 > self.y and y4 < self.y + self.height)
end

return Hitbox