---@class Hitbox : Collider
---@overload fun(...) : Hitbox
local Hitbox, super = Class(Collider)

---@param width number?
---@param height number?
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
            local aabb, shape = other:getShapeFor(self)
            if aabb then
                return self:applyInvert(other, CollisionUtil.rectRectInside(self.x,self.y,self.width,self.height, unpack(shape)))
            else
                return self:applyInvert(other, CollisionUtil.rectPolygonInside(self.x,self.y,self.width,self.height, shape))
            end
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
            local aabb, shape = other:getShapeFor(self)
            if aabb then
                return self:applyInvert(other, CollisionUtil.rectRect(self.x,self.y,self.width,self.height, unpack(shape)))
            else
                return self:applyInvert(other, CollisionUtil.rectPolygon(self.x,self.y,self.width,self.height, shape))
            end
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

--- Gets this collider's shape as a rectangle or polygon (depending on transformation) for the given other collider.
---@param other Collider # The other collider to get the shape for.
---@return boolean aabb # `true` if the shape is a rectangle, `false` if it is a polygon.
---@return [number, number, number, number]|number[][] shape # The shape of the collider as a list of points or vertices.
function Hitbox:getShapeFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    local ul_x, ul_y = other:getLocalPoint(tf1, tf2, self.x, self.y)
    local ur_x, ur_y = other:getLocalPoint(tf1, tf2, self.x + self.width, self.y)
    local dr_x, dr_y = other:getLocalPoint(tf1, tf2, self.x + self.width, self.y + self.height)
    local dl_x, dl_y = other:getLocalPoint(tf1, tf2, self.x, self.y + self.height)

    if ul_y == ur_y and ul_x == dl_x then
        local min_x, min_y = math.min(ul_x, dr_x), math.min(ul_y, dr_y)
        local max_x, max_y = math.max(ul_x, dr_x), math.max(ul_y, dr_y)

        return true, {min_x, min_y, max_x - min_x, max_y - min_y}
    end

    return false, {
        {ul_x, ul_y},
        {ur_x, ur_y},
        {dr_x, dr_y},
        {dl_x, dl_y}
    }
end

function Hitbox:draw(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, MathUtils.absClamp(self.width, 1, math.huge), MathUtils.absClamp(self.height, 1, math.huge))
    Draw.setColor(1, 1, 1, 1)
end

function Hitbox:drawFill(r,g,b,a)
    Draw.setColor(r,g,b,a)
    love.graphics.rectangle("fill", self.x, self.y, MathUtils.absClamp(self.width, 1, math.huge), MathUtils.absClamp(self.height, 1, math.huge))
    Draw.setColor(1, 1, 1, 1)
end

return Hitbox
