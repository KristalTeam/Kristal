local CircleCollider, super = Class(Collider)

function CircleCollider:init(x, y, radius, parent)
    super:init(self, x, y, parent)

    self.radius = radius
end

function CircleCollider:collidesWith(other)
    other = self:getOtherCollider(other)
    if not other then return false end

    if other:includes(Hitbox) then
        return self:collideWithHitbox(other)
    elseif other:includes(LineCollider) then
        return other:collidesWith(self)
    elseif other:includes(CircleCollider) then
        return self:collideWithCircle(other)
    elseif other:includes(ColliderGroup) then
        return other:collidesWith(self)
    end
end

function CircleCollider:collideWithCircle(other)
    local tf1, tf2 = self:getTransformsWith(other)

    local x1, y1 = self.x, self.y
    local rx1, ry1 = self.x + self.radius, self.y
    if tf1 then
        x1, y1 = tf1:transformPoint(x1, y1)
        rx1, ry1 = tf1:transformPoint(rx1, ry1)
    end
    local r1 = Vector.dist(x1,y1, rx1,ry1)

    local x2, y2 = other.x, other.y
    local rx2, ry2 = other.x + other.radius, other.y
    if tf2 then
        x2, y2 = tf2:transformPoint(x2, y2)
        rx2, ry2 = tf2:transformPoint(rx2, ry2)
    end
    local r2 = Vector.dist(x2,y2, rx2,ry2)

    -- https://www.jeffreythompson.org/collision-detection/circle-circle.php
    local dx, dy = x1 - x2, y1 - y2
    local dist = math.sqrt(dx*dx + dy*dy)

    return dist <= r1+r2
end

function CircleCollider:collideWithHitbox(other)
    local cx, cy = other:getPointFor(self, 0, 0)
    local cx2, cy2 = other:getPointFor(self, self.radius, 0)

    local r = Vector.dist(cx,cy, cx2,cy2)

    local rx, ry, rw, rh = other.x, other.y, other.width, other.height

    -- https://www.jeffreythompson.org/collision-detection/circle-rect.php
    local test_x, test_y = cx, cy

    if cx < rx then
        test_x = rx -- left edge
    elseif cx > rx+rw then
        test_x = rx+rw -- right edge
    end

    if cy < ry then
        test_y = ry -- top edge
    elseif cy > ry+rh then
        test_y = ry+rh -- bottom edge
    end

    local dx, dy = cx - test_x, cy - test_y
    local dist = math.sqrt(dx*dx + dy*dy)

    return dist <= r
end

-- https://www.jeffreythompson.org/collision-detection/point-circle.php
function CircleCollider.checkPoint(px, py, cx, cy, r)
    local dx, dy = px - cx, py - cy
    local dist = math.sqrt(dx*dx + dy*dy)

    return dist <= r
end

function CircleCollider:draw(r,g,b,a)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1, 1)
end

return CircleCollider