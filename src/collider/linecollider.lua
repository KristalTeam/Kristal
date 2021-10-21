local LineCollider, super = Class(Collider)

function LineCollider:init(x1, y1, x2, y2, parent)
    super:init(self, x1, y1, parent)

    self.x2 = x2
    self.y2 = y2
end

function LineCollider:collidesWith(other, symmetrical)
    if not isClass(other) then return false end

    if other:includes(LineCollider) then
        local tf1, tf2 = self:getTransformsWith(other)
        return self:collideWithLine(other, tf1, tf2, other.x, other.y, other.x2, other.y2)
    elseif other:includes(Hitbox) then
        local tf1, tf2 = self:getTransformsWith(other)
        return self:collideWithLine(other, tf1, tf2, other.x, other.y, other.x + other.width, other.y) or
               self:collideWithLine(other, tf1, tf2, other.x + other.width, other.y, other.x + other.width, other.y + other.height) or
               self:collideWithLine(other, tf1, tf2, other.x + other.width, other.y + other.height, other.x, other.y + other.height) or
               self:collideWithLine(other, tf1, tf2, other.x, other.y + other.height, other.x, other.y)
    end

    return super:collidesWith(self, other)
end

function LineCollider:collideWithLine(other, tf1, tf2, x3, y3, x4, y4)
    local x1, y1 = self.x, self.y
    local x2, y2 = self.x2, self.y2

    if tf2 then
        x3, y3 = tf2:transformPoint(x3, y3)
        x4, y4 = tf2:transformPoint(x4, y4)
    end

    if tf1 then
        x3, y3 = tf1:inverseTransformPoint(x3, y3)
        x4, y4 = tf1:inverseTransformPoint(x4, y4)
    end

    -- http://www.jeffreythompson.org/collision-detection/line-line.php
    local uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    local uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    return uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1
end

return LineCollider