--- A circular collider used for collision detection.
---@class CircleCollider : Collider
---@field x number # The X coordinate of the circle's center.
---@field y number # The Y coordinate of the circle's center.
---@field radius number # The radius of the circle.
---@overload fun(owner: Object?, x: number, y: number, radius: number, mode: Collider.Mode?) : CircleCollider
local CircleCollider, super = Class(Collider)

---@param owner Object?
---@param x number
---@param y number
---@param radius number
---@param mode Collider.Mode?
function CircleCollider:init(owner, x, y, radius, mode)
    super.init(self, owner, mode)

    self.x = x or 0
    self.y = y or 0
    self.radius = radius
end

function CircleCollider:getColliderType()
    return CollisionRegistry.CIRCLE
end

--- Gets the circle's center and radius.
---@return number x # The X coordinate of the circle's center.
---@return number y # The Y coordinate of the circle's center.
---@return number radius # The radius of the circle.
function CircleCollider:getCircle()
    return self.x, self.y, self.radius
end

--- Sets the circle's center and radius.
---@param x number # The X coordinate of the circle's center.
---@param y number # The Y coordinate of the circle's center.
---@param radius number # The radius of the circle.
function CircleCollider:setCircle(x, y, radius)
    self.x = x
    self.y = y
    self.radius = radius
end

--- Gets the circle's center and radius relative to another collider.
---@param other Collider # The other collider to get the circle's position relative to.
---@return number x # The X coordinate of the circle's center relative to the other collider.
---@return number y # The Y coordinate of the circle's center relative to the other collider.
---@return number radius # The radius of the circle relative to the other collider.
function CircleCollider:getCircleFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    local cx, cy = other:getLocalPoint(tf1, tf2, self.x, self.y)
    local crx, cry = other:getLocalPoint(tf1, tf2, self.x + self.radius, self.y)

    return cx, cy, MathUtils.dist(cx, cy, crx, cry)
end

--- Gets the axis-aligned bounding box of the circle.
---@return number x # The X coordinate of the bounding box.
---@return number y # The Y coordinate of the bounding box.
---@return number width # The width of the bounding box.
---@return number height # The height of the bounding box.
function CircleCollider:getBounds()
    return self.x - self.radius, self.y - self.radius, self.radius * 2, self.radius * 2
end

--- Draws the circle outlined with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function CircleCollider:draw(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.x, self.y, self.radius)
    Draw.setColor(1, 1, 1, 1)
end

--- Draws the circle filled with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function CircleCollider:drawFill(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    Draw.setColor(1, 1, 1, 1)
end

return CircleCollider
