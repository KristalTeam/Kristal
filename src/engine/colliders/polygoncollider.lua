---@class PolygonCollider : Collider
---@overload fun(...) : PolygonCollider
local PolygonCollider, super = Class(Collider)

function PolygonCollider:init(parent, points, mode)
    super.init(self, parent, 0, 0, mode)

    self.points = points
end

function PolygonCollider:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end
    if not self:insideCheck(other) then return false end

    if other.inside then
        return other:collidesWith(self)
    elseif self.inside then
        if other:includes(Hitbox) then
            return self:applyInvert(other, CollisionUtil.polygonPolygonInside(self.points, other:getShapeFor(self)))
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.polygonLineInside(self.points, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.polygonCircleInside(self.points, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.polygonPointInside(self.points, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.polygonPolygonInside(self.points, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    else
        if other:includes(Hitbox) then
            return other:collidesWith(self)
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.polygonLine(self.points, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.polygonCircle(self.points, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.polygonPoint(self.points, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.polygonPolygon(self.points, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    end

    return super.collidesWith(self, other)
end

function PolygonCollider:getShapeFor(other)
    return other:getLocalPointsWith(self, self.points)
end

function PolygonCollider:draw(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    local unpacked = {}
    for _,point in ipairs(self.points) do
        table.insert(unpacked, point[1])
        table.insert(unpacked, point[2])
    end
    table.insert(unpacked, unpacked[1])
    table.insert(unpacked, unpacked[2])
    love.graphics.line(unpack(unpacked))
    Draw.setColor(1, 1, 1, 1)
end
function PolygonCollider:drawFill(r,g,b,a)
    Draw.setColor(r,g,b,a)
    local unpacked = {}
    for _,point in ipairs(self.points) do
        table.insert(unpacked, point[1])
        table.insert(unpacked, point[2])
    end
    local triangles = love.math.triangulate(unpacked)
    for _,triangle in ipairs(triangles) do
        love.graphics.polygon("fill", triangle)
    end
    Draw.setColor(1, 1, 1, 1)
end

return PolygonCollider