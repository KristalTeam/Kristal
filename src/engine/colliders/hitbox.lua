---@class Hitbox : Collider
---@overload fun(...) : Hitbox
local Hitbox, super = Class(Collider)

function Hitbox:init(parent, x, y, width, height, mode)
    super.init(self, parent, x, y, mode)

    self.width = width or 0
    self.height = height or 0
end

function Hitbox:collidesWith(other)
    other = self:getOtherCollider(other)
    if not self:collidableCheck(other) then return false end
    if not self:insideCheck(other) then return false end

    if other.inside then
        return other:collidesWith(self)
    elseif self.inside then
        if other:includes(Hitbox) then
            return self:applyInvert(other, CollisionUtil.rectPolygonInside(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.rectLineInside(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.rectCircleInside(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.rectPointInside(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.rectPolygonInside(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    else
        if other:includes(Hitbox) then
            return self:applyInvert(other, CollisionUtil.rectPolygon(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(LineCollider) then
            return self:applyInvert(other, CollisionUtil.rectLine(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(CircleCollider) then
            return self:applyInvert(other, CollisionUtil.rectCircle(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(PointCollider) then
            return self:applyInvert(other, CollisionUtil.rectPoint(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(PolygonCollider) then
            return self:applyInvert(other, CollisionUtil.rectPolygon(self.x,self.y,self.width,self.height, other:getShapeFor(self)))
        elseif other:includes(ColliderGroup) then
            return other:collidesWith(self)
        end
    end

    return super.collidesWith(self, other)
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
    Draw.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, Utils.absClamp(self.width, 1, math.huge), Utils.absClamp(self.height, 1, math.huge))
    Draw.setColor(1, 1, 1, 1)
end
function Hitbox:drawFill(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.rectangle("fill", self.x, self.y, Utils.absClamp(self.width, 1, math.huge), Utils.absClamp(self.height, 1, math.huge))
    Draw.setColor(1, 1, 1, 1)
end

return Hitbox