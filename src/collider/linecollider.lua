local LineCollider, super = Class(Collider)

function LineCollider:init(parent, x1, y1, x2, y2)
    super:init(self, parent, x1, y1)

    self.x2 = x2
    self.y2 = y2
end

function LineCollider:collidesWith(other, symmetrical)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end

    if other:includes(Hitbox) then
        return other:collidesWith(self)
    elseif other:includes(LineCollider) then
        return CollisionUtil.lineLine(self.x,self.y, self.x2,self.y2, other:getShapeFor(self))
    elseif other:includes(CircleCollider) then
        return CollisionUtil.lineCircle(self.x,self.y, self.x2,self.y2, other:getShapeFor(self))
    elseif other:includes(PointCollider) then
        return CollisionUtil.linePoint(self.x,self.y, self.x2,self.y2, other:getShapeFor(self))
    elseif other:includes(PolygonCollider) then
        return CollisionUtil.linePolygon(self.x,self.y, self.x2,self.y2, other:getShapeFor(self))
    elseif other:includes(ColliderGroup) then
        return other:collidesWith(self)
    end

    return super:collidesWith(self, other)
end

function LineCollider:getShapeFor(other)
    return other:getLocalPointsWith(self, self.x,self.y, self.x2,self.y2)
end

function LineCollider:draw(r,g,b,a)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.line(self.x, self.y, self.x2, self.y2)
    love.graphics.setColor(1, 1, 1, 1)
end

return LineCollider