---@class CircleCollider : Collider
---@overload fun(...) : CircleCollider
local CircleCollider, super = Class(Collider)

function CircleCollider:init(parent, x, y, radius, mode)
    super.init(self, parent, x, y, mode)

    self.radius = radius
end

function CircleCollider:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end
    if not self:insideCheck(other) then return false end

    if other.inside then
        return other:collidesWith(self)
    elseif self.inside then
        if other:includes(Hitbox) then
            return self:applyInvert(other, CollisionUtil.circlePolygonInside(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.circleLineInside(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.circleCircleInside(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.circlePointInside(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.circlePolygonInside(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    else
        if other:includes(Hitbox) then
            return other:collidesWith(self)
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.circleLine(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.circleCircle(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.circlePoint(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.circlePolygon(self.x,self.y, self.radius, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    end

    return super.collidesWith(self, other)
end

function CircleCollider:getShapeFor(other)
    local cx,cy, crx,cry = other:getLocalPointsWith(self, self.x,self.y, self.x+self.radius,self.y)
    return cx, cy, Utils.dist(cx,cy, crx,cry)
end

function CircleCollider:draw(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.x, self.y, self.radius)
    Draw.setColor(1, 1, 1, 1)
end
function CircleCollider:drawFill(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    Draw.setColor(1, 1, 1, 1)
end

return CircleCollider