local Hitbox, super = Class(Collider)

function Hitbox:init(parent, x, y, width, height)
    super:init(self, parent, x, y)

    self.width = width or 0
    self.height = height or 0
end

function Hitbox:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end

    if other:includes(Hitbox) then
        return CollisionUtil.rectPolygon(self.x,self.y,self.width,self.height, other:getShapeFor(self))
    elseif other:includes(LineCollider) then
        return CollisionUtil.rectLine(self.x,self.y,self.width,self.height, other:getShapeFor(self))
    elseif other:includes(CircleCollider) then
        return CollisionUtil.rectCircle(self.x,self.y,self.width,self.height, other:getShapeFor(self))
    elseif other:includes(PointCollider) then
        return CollisionUtil.rectPoint(self.x,self.y,self.width,self.height, other:getShapeFor(self))
    elseif other:includes(PolygonCollider) then
        return CollisionUtil.rectPolygon(self.x,self.y,self.width,self.height, other:getShapeFor(self))
    elseif other:includes(ColliderGroup) then
        return other:collidesWith(self)
    end

    return super:collidesWith(self, other)
end

-- Note: returns polygon
function Hitbox:getShapeFor(other)
    local points = {
        {self.x, self.y},
        {self.x+self.width, self.y},
        {self.x+self.width, self.y+self.height},
        {self.x, self.y+self.height}
    }
    return other:getLocalPointsWith(self, points)
end

function Hitbox:draw(r,g,b,a)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1, 1)
end

return Hitbox