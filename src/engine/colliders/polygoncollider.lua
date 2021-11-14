local PolygonCollider, super = Class(Collider)

function PolygonCollider:init(parent, points)
    super:init(self, parent)

    self.points = points
end

function PolygonCollider:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end

    if other:includes(Hitbox) then
        return other:collidesWith(self)
    elseif other:includes(LineCollider) then
        return CollisionUtil.polygonLine(self.points, other:getShapeFor(self))
    elseif other:includes(CircleCollider) then
        return CollisionUtil.polygonCircle(self.points, other:getShapeFor(self))
    elseif other:includes(PointCollider) then
        return CollisionUtil.polygonPoint(self.points, other:getShapeFor(self))
    elseif other:includes(PolygonCollider) then
        return CollisionUtil.polygonPolygon(self.points, other:getShapeFor(self))
    elseif other:includes(ColliderGroup) then
        return other:collidesWith(self)
    end

    return super:collidesWith(self, other)
end

function PolygonCollider:getShapeFor(other)
    return other:getLocalPointsWith(self, self.points)
end

function PolygonCollider:draw(r,g,b,a)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    local unpacked = {}
    for _,point in ipairs(self.points) do
        table.insert(unpacked, point[1])
        table.insert(unpacked, point[2])
    end
    table.insert(unpacked, unpacked[1])
    table.insert(unpacked, unpacked[2])
    love.graphics.line(unpack(unpacked))
    love.graphics.setColor(1, 1, 1, 1)
end

return PolygonCollider