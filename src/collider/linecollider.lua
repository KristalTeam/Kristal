local LineCollider, super = Class(Collider)

function LineCollider:init(x1, y1, x2, y2, parent)
    super:init(self, x1, y1, parent)

    self.x2 = x2
    self.y2 = y2
end

function LineCollider:collidesWith(other, symmetrical)
    if not isClass(other) then return false end

    if other:includes(LineCollider) then
        return self:collideWithLine(other, 0, 0, other.x2 - other.x, other.y2 - other.y)
    elseif other:includes(Hitbox) then
        return self:collideWithLine(other, 0, 0, other.width, 0) or
               self:collideWithLine(other, other.width, 0, other.width, other.height) or
               self:collideWithLine(other, other.width, other.height, 0, other.height) or
               self:collideWithLine(other, 0, other.height, 0, 0)
    end

    return super:collidesWith(self, other)
end

function LineCollider:collideWithLine(other, ox, oy, ox2, oy2)
    local x1, y1 = self.x, self.y
    local x2, y2 = self.x2, self.y2

    local x3, y3 = self:getPointFor(other, ox, oy)
    local x4, y4 = self:getPointFor(other, ox2, oy2)

    -- http://www.jeffreythompson.org/collision-detection/line-line.php
    local uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    local uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    return uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1
end

return LineCollider