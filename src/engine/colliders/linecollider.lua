---@class LineCollider : Collider
---@overload fun(...) : LineCollider
local LineCollider, super = Class(Collider)

function LineCollider:init(parent, x1, y1, x2, y2, mode)
    super.init(self, parent, x1, y1, mode)

    self.x2 = x2
    self.y2 = y2
end

function LineCollider:collidesWith(other, symmetrical)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end
    if not self:insideCheck(other) then return false end

    if other.inside then
        return other:collidesWith(self)
    elseif self.inside then
        if other:includes(Hitbox) then
            return self:applyInvert(other, CollisionUtil.linePolygonInside(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.lineLineInside(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.lineCircleInside(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.linePointInside(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.linePolygonInside(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    else
        if other:includes(Hitbox) then
            return other:collidesWith(self)
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.lineLine(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.lineCircle(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.linePoint(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.linePolygon(self.x,self.y, self.x2,self.y2, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    end

    return super.collidesWith(self, other)
end

function LineCollider:getShapeFor(other)
    return other:getLocalPointsWith(self, self.x,self.y, self.x2,self.y2)
end

function LineCollider:draw(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.line(self.x, self.y, self.x2, self.y2)
    Draw.setColor(1, 1, 1, 1)
end
function LineCollider:drawFill(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setLineWidth(5)
    love.graphics.line(self.x, self.y, self.x2, self.y2)
    Draw.setColor(1, 1, 1, 1)
end

return LineCollider