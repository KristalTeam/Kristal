---@alias point number[]

---@alias edge {[1]:point, [2]:point, ["angle"]:number}

---@alias linefailure
---| "The lines are parallel."
---| "The lines don't intersect."
---| "The lines are the same."

---@class ShapeUtils
local ShapeUtils = {}

--- Returns a table of line segments based on a set of polygon points.
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return edge[] edges # An array of tables containing four values each, defining line segments describing the edges of a polygon.
function ShapeUtils.getPolygonEdges(points)
    local edges = {}
    for i = 1, #points do
        local p1, p2 = points[i], points[(i % #points) + 1]
        table.insert(edges, { p1, p2, angle = math.atan2(p2[2] - p1[2], p2[1] - p1[1]) })
    end
    return edges
end

--- Determines whether a polygon's points are clockwise or counterclockwise.
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return boolean result # Whether the polygon is clockwise or not.
function ShapeUtils.isPolygonClockwise(points)
    local edges = ShapeUtils.getPolygonEdges(points)
    local sum = 0
    for _, edge in ipairs(edges) do
        sum = sum + ((edge[2][1] - edge[1][1]) * (edge[2][2] + edge[1][2]))
    end
    return sum > 0
end

--- Returns the point at which two lines intersect.
---@param x1 number # The horizontal position of the first point for the first line.
---@param y1 number # The vertical position of the first point for the first line.
---@param x2 number # The horizontal position of the second point for the first line.
---@param y2 number # The vertical position of the second point for the first line.
---@param x3 number # The horizontal position of the first point for the second line.
---@param y3 number # The vertical position of the first point for the second line.
---@param x4 number # The horizontal position of the second point for the second line.
---@param y4 number # The vertical position of the second point for the second line.
---@param seg1? boolean # If true, the first line will be treated as a line segment instead of an infinite line.
---@param seg2? boolean # If true, the second line will be treated as a line segment instead of an infinite line.
---@return number|boolean x # If the lines intersected, this will be the horizontal position of the intersection; otherwise, this value will be `false`.
---@return number|linefailure y # If the lines intersected, this will be the vertical position of the intersection; otherwise, this will be a string describing why the lines did not intersect.
function ShapeUtils.getLineIntersect(x1, y1, x2, y2, x3, y3, x4, y4, seg1, seg2)
    -- Get the slopes of the lines
    local m1 = (y1 - y2) / (x1 - x2)
    local m2 = (y3 - y4) / (x3 - x4)

    -- Get the offsets of the lines
    local b1 = -(m1 * x1 - y1) or y1
    local b2 = -(m2 * x3 - y3) or y3

    -- Make x and y variables
    local x = nil
    local y = nil

    -- Check whether any of the lines are vertical
    if (x1 - x2) == 0 then
        -- Find x and y
        x = x1
        y = m2 * x + b2
    elseif (x3 - x4) == 0 then
        -- Find x and y
        x = x3
        y = m1 * x + b1
    else
        -- Find x and y
        x = (b2 - b1) / (m1 - m2)
        y = m1 * x + b1
    end

    -- Check if the lines are parallel or the same
    if m1 == m2 and b1 ~= b2 then
        return false, "The lines are parallel."
    elseif m1 == m2 and b1 == b2 then
        return false, "The lines are the same."
    end

    -- Check if x and y are out of the segment bounds
    if seg1 or seg2 then
        local min, max = math.min, math.max
        if seg1 and (x < min(x1, x2) or x > max(x1, x2) or y < min(y1, y2) or y > max(y1, y2)) then
            return false, "The lines don't intersect."
        end
        if seg2 and (x < min(x3, x4) or x > max(x3, x4) or y < min(y3, y4) or y > max(y3, y4)) then
            return false, "The lines don't intersect."
        end
    end
    return x, y
end

--- Returns a new polygon with points offset outwards by a certain distance.
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@param dist number # The distance to offset the points by. If this value is negative, the points will be offset inwards.
---@return point[] A # new polygon array.
function ShapeUtils.getPolygonOffset(points, dist)
    -- Get the sign of the polygon's winding direction
    local sign = ShapeUtils.isPolygonClockwise(points) and 1 or -1

    local function offsetPoint(x, y, angle, dist)
        return x + math.cos(angle) * dist, y + math.sin(angle) * dist
    end

    -- Loop through all the edges of the polygon
    local edges = ShapeUtils.getPolygonEdges(points)
    local new_polygon = {}
    for i = 1, #edges do
        -- Get the current and the next edge, wrapping around
        -- to the first edge if we're at the last one
        local e1, e2 = edges[i], edges[(i % #edges) + 1]

        -- Offset the points of the edges by the given distance
        local p1x, p1y = offsetPoint(e1[1][1], e1[1][2], e1.angle + sign * (math.pi / 2), dist)
        local p2x, p2y = offsetPoint(e1[2][1], e1[2][2], e1.angle + sign * (math.pi / 2), dist)
        local p3x, p3y = offsetPoint(e2[1][1], e2[1][2], e2.angle + sign * (math.pi / 2), dist)
        local p4x, p4y = offsetPoint(e2[2][1], e2[2][2], e2.angle + sign * (math.pi / 2), dist)

        -- Add the intersection point of the two offset edges to the new polygon
        local ix, iy = ShapeUtils.getLineIntersect(p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y)
        if ix then
            table.insert(new_polygon, { ix, iy })
        end
    end

    -- Move the last point to the start of the table
    table.insert(new_polygon, 1, table.remove(new_polygon, #new_polygon))

    return new_polygon
end

--- Converts a set of polygon points to a series of numbers.
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return number ... # A series of numbers describing the horizontal and vertical positions of each point in the polygon.
function ShapeUtils.unpackPolygon(points)
    local line = {}
    for _, point in ipairs(points) do
        table.insert(line, point[1])
        table.insert(line, point[2])
    end
    table.insert(line, points[1][1])
    table.insert(line, points[1][2])
    return unpack(line)
end

--- Returns the bounds of a rectangle containing every point of a polygon.
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return number x # The horizontal position of the bounds.
---@return number y # The vertical position of the bounds.
---@return number width # The width of the bounds.
---@return number height # The height of the bounds.
function ShapeUtils.getPolygonBounds(points)
    if #points == 0 then
        return 0, 0, 0, 0
    end

    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge

    for _, point in ipairs(points) do
        local x, y = point[1], point[2]

        min_x, min_y = math.min(min_x, x), math.min(min_y, y)
        max_x, max_y = math.max(max_x, x), math.max(max_y, y)
    end

    return min_x, min_y, (max_x - min_x), (max_y - min_y)
end

--- Returns the bounding box of a line segment.
---@param x1 number # The X coordinate of the first point of the line segment.
---@param y1 number # The Y coordinate of the first point of the line segment.
---@param x2 number # The X coordinate of the second point of the line segment.
---@param y2 number # The Y coordinate of the second point of the line segment.
---@return number x # The X coordinate of the bounding box.
---@return number y # The Y coordinate of the bounding box.
---@return number width # The width of the bounding box.
---@return number height # The height of the bounding box.
function ShapeUtils.getLineBounds(x1, y1, x2, y2)
    local min_x = math.min(x1, x2)
    local min_y = math.min(y1, y2)
    local max_x = math.max(x1, x2)
    local max_y = math.max(y1, y2)

    return min_x, min_y, max_x - min_x, max_y - min_y
end

--- Returns the bounding box of a circle.
---@param x number # The X coordinate of the center of the circle.
---@param y number # The Y coordinate of the center of the circle.
---@param radius number # The radius of the circle.
---@return number x # The X coordinate of the bounding box.
---@return number y # The Y coordinate of the bounding box.
---@return number width # The width of the bounding box.
---@return number height # The height of the bounding box.
function ShapeUtils.getCircleBounds(x, y, radius)
    local diameter = radius * 2

    return x - radius, y - radius, diameter, diameter
end

--- Transforms a point from the local space of the source transform to the local space of the destination transform.
---@param source love.Transform? # The source transform, relative to a common parent.
---@param destination love.Transform? # The destination transform, relative to a common parent.
---@param x number # The X coordinate of the point to be transformed.
---@param y number # The Y coordinate of the point to be transformed.
---@return number local_x # The X coordinate of the point from the source, relative to the destination.
---@return number local_y # The Y coordinate of the point from the source, relative to the destination.
function ShapeUtils.relativeTransformPoint(source, destination, x, y)
    if source ~= nil then
        x, y = source:transformPoint(x, y)
    end

    if destination ~= nil then
        x, y = destination:inverseTransformPoint(x, y)
    end

    return x, y
end

return ShapeUtils
