---@class PointCollider : Collider
---@overload fun(...) : PointCollider
local PointCollider, super = Class(Collider)

function PointCollider:init(parent, x, y, mode)
    super.init(self, parent, x, y, mode)
end

function PointCollider:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end
    if not self:insideCheck(other) then return false end

    if other.inside then
        return other:collidesWith(self)
    elseif self.inside then
        if other:includes(Hitbox) then
            return self:applyInvert(other, CollisionUtil.pointPolygonInside(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.pointLineInside(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.pointCircleInside(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.pointPointInside(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.pointPolygonInside(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    else
        if other:includes(Hitbox) then
            return other:collidesWith(self)
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.pointLine(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.pointCircle(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.pointPoint(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.pointPolygon(self.x,self.y, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    end

    return super.collidesWith(self, other)
end

function PointCollider:getShapeFor(other)
    return other:getLocalPointsWith(self, self.x,self.y)
end

function PointCollider:draw(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setPointSize(3)
    love.graphics.points(self.x, self.y)
    Draw.setColor(1, 1, 1, 1)
end
function PointCollider:drawFill(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setPointSize(5)
    love.graphics.points(self.x, self.y)
    Draw.setColor(1, 1, 1, 1)
end

return PointCollider