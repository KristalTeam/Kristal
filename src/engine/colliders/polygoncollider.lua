--- A polygonal collider used for collision detection.
---@class PolygonCollider : Collider
---@field protected points number[][] # The points of the polygon as a list of `{x, y}` pairs.
---@field protected bounds_x number # The X coordinate of the polygon's bounding box.
---@field protected bounds_y number # The Y coordinate of the polygon's bounding box.
---@field protected bounds_width number # The width of the polygon's bounding box.
---@field protected bounds_height number # The height of the polygon's bounding box.
---@overload fun(owner: Object?, points: number[][], mode: Collider.Mode?) : PolygonCollider
local PolygonCollider, super = Class(Collider)

---@param owner Object?
---@param points number[][]
---@param mode Collider.Mode?
function PolygonCollider:init(owner, points, mode)
    super.init(self, owner, mode)

    self:setPoints(points)
end

function PolygonCollider:getColliderType()
    return CollisionRegistry.POLYGON
end

function PolygonCollider:getBounds()
    return self.bounds_x, self.bounds_y, self.bounds_width, self.bounds_height
end

--- Gets the points of the polygon collider as a list of `{x, y}` pairs.
---
--- Modifying the returned table directly will not affect the internal points of the polygon collider. To update its points,
--- use [`PolygonCollider:setPoints`](lua://PolygonCollider.setPoints) instead.
---@return number[][] points # The points of the polygon collider as a list of `{x, y}` pairs.
function PolygonCollider:getPoints()
    local points = {}

    for i, point in ipairs(self.points) do
        points[i] = {point[1], point[2]}
    end

    return points
end

--- Sets the points of the polygon collider.
---@param points number[][] # The new points of the polygon collider as a list of `{x, y}` pairs.
function PolygonCollider:setPoints(points)
    self.points = points

    self.bounds_x, self.bounds_y, self.bounds_width, self.bounds_height = Utils.getPolygonBounds(points)
end

--- Gets the points of the polygon collider as a list of `{x, y}` pairs, without copying them.
---
--- This should only be called when performance is critical (e.g. collision checking). **Do not** modify the returned
--- table directly.
---@return number[][] points # The points of the polygon collider as a list of `{x, y}` pairs.
function PolygonCollider:getPointsDirect()
    return self.points
end

--- Gets the points of the polygon collider relative to another collider.
---@param other Collider # The other collider to get the points relative to.
---@return number[][] shape # The points of the polygon collider as a list of `{x, y}` pairs.
function PolygonCollider:getPointsFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    local local_points = {}

    for i, point in ipairs(self.points) do
        local x, y = other:getLocalPoint(tf1, tf2, point[1], point[2])

        local_points[i] = {x, y}
    end

    return local_points
end

--- Draws the polygon collider outlined with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function PolygonCollider:draw(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setLineWidth(1)
    local unpacked = {}
    for _,point in ipairs(self.points) do
        table.insert(unpacked, point[1])
        table.insert(unpacked, point[2])
    end
    table.insert(unpacked, unpacked[1])
    table.insert(unpacked, unpacked[2])
    love.graphics.line(unpack(unpacked))
    Draw.setColor(1, 1, 1, 1)
end

--- Draws the polygon collider filled with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function PolygonCollider:drawFill(r, g, b, a)
    Draw.setColor(r, g, b, a)
    local unpacked = {}
    for _,point in ipairs(self.points) do
        table.insert(unpacked, point[1])
        table.insert(unpacked, point[2])
    end
    local triangles = love.math.triangulate(unpacked)
    for _,triangle in ipairs(triangles) do
        love.graphics.polygon("fill", triangle)
    end
    Draw.setColor(1, 1, 1, 1)
end

return PolygonCollider
