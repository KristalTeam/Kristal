--- A point collider used for collision detection.
---@class PointCollider : Collider
---@field x number # The X coordinate of the point.
---@field y number # The Y coordinate of the point.
---@overload fun(owner: Object?, x: number, y: number, mode: Collider.Mode?) : PointCollider
local PointCollider, super = Class(Collider)

---@param owner Object?
---@param x number
---@param y number
---@param mode Collider.Mode?
function PointCollider:init(owner, x, y, mode)
    super.init(self, owner, mode)

    self.x = x
    self.y = y
end

function PointCollider:getColliderType()
    return CollisionRegistry.POINT
end

--- Gets the coordinates of the point.
---@return number x # The X coordinate of the point.
---@return number y # The Y coordinate of the point.
function PointCollider:getPoint()
    return self.x, self.y
end

--- Sets the coordinates of the point.
---@param x number # The X coordinate of the point.
---@param y number # The Y coordinate of the point.
function PointCollider:setPoint(x, y)
    self.x = x
    self.y = y
end

--- Gets the coordinates of the point relative to another collider.
---@param other Collider # The other collider to get the point relative to.
---@return number x # The X coordinate of the point relative to the other collider.
---@return number y # The Y coordinate of the point relative to the other collider.
function PointCollider:getPointFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    return other:getLocalPoint(tf1, tf2, self.x, self.y)
end

--- Draws the point with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function PointCollider:draw(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setPointSize(3)
    love.graphics.points(self.x, self.y)
    Draw.setColor(1, 1, 1, 1)
end

--- Draws the point with the given color and a larger size.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function PointCollider:drawFill(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setPointSize(5)
    love.graphics.points(self.x, self.y)
    Draw.setColor(1, 1, 1, 1)
end

return PointCollider
