--- A line segment collider used for collision detection.
---@class LineCollider : Collider
---@field x1 number # The X coordinate of the first point of the line segment.
---@field y1 number # The Y coordinate of the first point of the line segment.
---@field x2 number # The X coordinate of the second point of the line segment.
---@field y2 number # The Y coordinate of the second point of the line segment.
---@overload fun(owner: Object?, x1: number, y1: number, x2: number, y2: number, mode: Collider.Mode?) : LineCollider
local LineCollider, super = Class(Collider)

---@param owner Object?
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param mode Collider.Mode?
function LineCollider:init(owner, x1, y1, x2, y2, mode)
    super.init(self, owner, mode)

    self.x1 = x1
    self.y1 = y1
    self.x2 = x2
    self.y2 = y2
end

function LineCollider:getColliderType()
    return CollisionRegistry.LINE
end

function LineCollider:getBounds()
    return Utils.getLineBounds(self.x1, self.y1, self.x2, self.y2)
end

--- Gets the coordinates of the line segment.
---@return number x1 # The X coordinate of the first point of the line segment.
---@return number y1 # The Y coordinate of the first point of the line segment.
---@return number x2 # The X coordinate of the second point of the line segment.
---@return number y2 # The Y coordinate of the second point of the line segment.
function LineCollider:getLine()
    return self.x1, self.y1, self.x2, self.y2
end

--- Sets the coordinates of the line segment.
---@param x1 number # The X coordinate of the first point of the line segment.
---@param y1 number # The Y coordinate of the first point of the line segment.
---@param x2 number # The X coordinate of the second point of the line segment.
---@param y2 number # The Y coordinate of the second point of the line segment.
function LineCollider:setLine(x1, y1, x2, y2)
    self.x1 = x1
    self.y1 = y1
    self.x2 = x2
    self.y2 = y2
end

--- Gets the coordinates of the line segment relative to another collider.
---@param other Collider # The other collider to get the line segment coordinates relative to.
---@return number x1 # The X coordinate of the first point of the line segment relative to the other collider.
---@return number y1 # The Y coordinate of the first point of the line segment relative to the other collider.
---@return number x2 # The X coordinate of the second point of the line segment relative to the other collider.
---@return number y2 # The Y coordinate of the second point of the line segment relative to the other collider.
function LineCollider:getLineFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    local x1, y1 = other:getLocalPoint(tf1, tf2, self.x1, self.y1)
    local x2, y2 = other:getLocalPoint(tf1, tf2, self.x2, self.y2)

    return x1, y1, x2, y2
end

--- Draws the line with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function LineCollider:draw(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setLineWidth(1)
    love.graphics.line(self.x1, self.y1, self.x2, self.y2)
    Draw.setColor(1, 1, 1, 1)
end

--- Draws the line with the given color and a thick line width.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function LineCollider:drawFill(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setLineWidth(5)
    love.graphics.line(self.x1, self.y1, self.x2, self.y2)
    Draw.setColor(1, 1, 1, 1)
end

return LineCollider
