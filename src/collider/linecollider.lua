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
    elseif other:includes(CircleCollider) then
        return self:collideWithCircle(other)
    elseif other:includes(ColliderGroup) then
        return other:collidesWith(self)
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

function LineCollider:collideWithCircle(other)
    local tf1, tf2 = self:getTransformsWith(other)

    local x1, y1 = self.x, self.y
    local x2, y2 = self.x2, self.y2

    local cx, cy = other.x, other.y
    local crx, cry = other.x + other.radius, other.y

    if tf2 then
        cx, cy = tf2:transformPoint(cx, cy)
        crx, cry = tf2:transformPoint(crx, cry)
    end

    if tf1 then
        cx, cy = tf1:inverseTransformPoint(cx, cy)
        crx, cry = tf1:inverseTransformPoint(crx, cry)
    end

    local r = Vector.dist(cx,cy, crx,cry)

    local inside1 = CircleCollider.checkPoint(x1,y1, cx,cy,r)
    local inside2 = CircleCollider.checkPoint(x2,y2, cx,cy,r)
    if inside1 or inside2 then return true end

    local dx, dy = x1 - x2, y1 - y2
    local len = math.sqrt(dx*dx + dy*dy)

    local dot = ( ((cx-x1)*(x2-x1)) + ((cy-y1)*(y2-y1)) ) / math.pow(len,2)

    local closest_x = x1 + (dot * (x2-x1))
    local closest_y = y1 + (dot * (y2-y1))

    if not LineCollider.checkPoint(x1,y1,x2,y2, closest_x, closest_y) then
        return false
    end

    dx, dy = closest_x - cx, closest_y - cy
    local dist = math.sqrt(dx*dx + dy*dy)

    return dist <= r
end

-- https://www.jeffreythompson.org/collision-detection/line-point.php
function LineCollider.checkPoint(x1, y1, x2, y2, px, py)
    local d1 = Vector.dist(px,py, x1,y1)
    local d2 = Vector.dist(px,py, x2,y2)

    local len = Vector.dist(x1,y1, x2,y2)

    local buffer = 0.01

    return d1+d2 >= len-buffer and d1+d2 <= len+buffer
end

function LineCollider:draw()
    love.graphics.setLineWidth(1)
    love.graphics.line(self.x, self.y, self.x2, self.y2)
end

return LineCollider