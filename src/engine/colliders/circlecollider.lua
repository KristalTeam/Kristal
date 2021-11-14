local CircleCollider, super = Class(Collider)

function CircleCollider:init(parent, x, y, radius)
    super:init(self, parent, x, y)

    self.radius = radius
end

function CircleCollider:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end

    if other:includes(Hitbox) then
        return other:collidesWith(self)
    elseif other:includes(LineCollider) then
        return CollisionUtil.circleLine(self.x,self.y, self.radius, other:getShapeFor(self))
    elseif other:includes(CircleCollider) then
        return CollisionUtil.circleCircle(self.x,self.y, self.radius, other:getShapeFor(self))
    elseif other:includes(PointCollider) then
        return CollisionUtil.circlePoint(self.x,self.y, self.radius, other:getShapeFor(self))
    elseif other:includes(PolygonCollider) then
        return CollisionUtil.circlePolygon(self.x,self.y, self.radius, other:getShapeFor(self))
    elseif other:includes(ColliderGroup) then
        return other:collidesWith(self)
    end

    return super:collidesWith(self, other)
end

function CircleCollider:getShapeFor(other)
    local cx,cy, crx,cry = other:getLocalPointsWith(self, self.x,self.y, self.x+self.radius,self.y)
    return cx, cy, Vector.dist(cx,cy, crx,cry)
end

function CircleCollider:draw(r,g,b,a)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1, 1)
end

return CircleCollider