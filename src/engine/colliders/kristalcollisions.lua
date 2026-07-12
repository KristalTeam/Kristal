---@class KristalCollisions
local KristalCollisions = {}

--#region Hitbox Collisions

--#region [Base] Hitbox / Hitbox

---@param a Hitbox
---@param b Hitbox
---@return boolean
function KristalCollisions.rectRect(a, b)
    local b_aabb, b_shape = b:getRectOrPolyFor(a)

    if b_aabb then
        return CollisionUtil.rectRect(
            a.x, a.y, a.width, a.height,
            b_shape[1], b_shape[2], b_shape[3], b_shape[4]
        )
    else
        -- Perform a preliminary bounds check
        local b_x, b_y, b_width, b_height = Utils.getPolygonBounds(b_shape)

        local bounds_check = CollisionUtil.rectRect(
            a.x, a.y, a.width, a.height,
            b_x, b_y, b_width, b_height
        )

        if not bounds_check then
            return false
        end

        return CollisionUtil.rectPolygon(
            a.x, a.y, a.width, a.height,
            b_shape
        )
    end
end

---@param a Hitbox
---@param b Hitbox
---@return boolean
function KristalCollisions.rectRectInner(a, b)
    local b_aabb, b_shape = b:getRectOrPolyFor(a)

    if b_aabb then
        return CollisionUtil.rectRectInside(
            a.x, a.y, a.width, a.height,
            b_shape[1], b_shape[2], b_shape[3], b_shape[4]
        )
    else
        -- Calculation is simple, skip the usual bounds check
        return CollisionUtil.rectPolygonInside(
            a.x, a.y, a.width, a.height,
            b_shape
        )
    end
end

--#endregion
--#region [Base] Hitbox / LineCollider

---@param rect Hitbox
---@param line LineCollider
---@return boolean
function KristalCollisions.rectLine(rect, line)
    local line_x1, line_y1, line_x2, line_y2 = line:getLineFor(rect)

    -- Perform a preliminary bounds check
    local line_bounds_x, line_bounds_y, line_bounds_w, line_bounds_h = Utils.getLineBounds(line_x1, line_y1, line_x2, line_y2)

    local bounds_check = CollisionUtil.rectRect(
        rect.x, rect.y, rect.width, rect.height,
        line_bounds_x, line_bounds_y, line_bounds_w, line_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.rectLine(
        rect.x, rect.y, rect.width, rect.height,
        line_x1, line_y1, line_x2, line_y2
    )
end

---@param rect Hitbox
---@param line LineCollider
---@return boolean
function KristalCollisions.rectLineInner(rect, line)
    local line_x1, line_y1, line_x2, line_y2 = line:getLineFor(rect)

    -- Calculation is simple, skip the usual bounds check
    return CollisionUtil.rectLineInside(
        rect.x, rect.y, rect.width, rect.height,
        line_x1, line_y1, line_x2, line_y2
    )
end

--#endregion
--#region [Base] Hitbox / CircleCollider

---@param rect Hitbox
---@param circle CircleCollider
---@return boolean
function KristalCollisions.rectCircle(rect, circle)
    local circle_x, circle_y, circle_radius = circle:getCircleFor(rect)

    -- Perform a preliminary bounds check
    local circle_bounds_x, circle_bounds_y, circle_bounds_w, circle_bounds_h = Utils.getCircleBounds(circle_x, circle_y, circle_radius)

    local bounds_check = CollisionUtil.rectRect(
        rect.x, rect.y, rect.width, rect.height,
        circle_bounds_x, circle_bounds_y, circle_bounds_w, circle_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.rectCircle(
        rect.x, rect.y, rect.width, rect.height,
        circle_x, circle_y, circle_radius
    )
end

---@param rect Hitbox
---@param circle CircleCollider
---@return boolean
function KristalCollisions.rectCircleInner(rect, circle)
    local circle_x, circle_y, circle_radius = circle:getCircleFor(rect)

    -- Calculation is simple, skip the usual bounds check
    return CollisionUtil.rectCircleInside(
        rect.x, rect.y, rect.width, rect.height,
        circle_x, circle_y, circle_radius
    )
end

--#endregion
--#region [Base] Hitbox / PointCollider

---@param rect Hitbox
---@param point PointCollider
---@return boolean
function KristalCollisions.rectPoint(rect, point)
    local point_x, point_y = point:getPointFor(rect)

    return CollisionUtil.rectPoint(
        rect.x, rect.y, rect.width, rect.height,
        point_x, point_y
    )
end

---@param rect Hitbox
---@param point PointCollider
---@return boolean
function KristalCollisions.rectPointInner(rect, point)
    local point_x, point_y = point:getPointFor(rect)

    return CollisionUtil.rectPointInside(
        rect.x, rect.y, rect.width, rect.height,
        point_x, point_y
    )
end

--#endregion
--#region        Hitbox / PolygonCollider

---@param rect Hitbox
---@param polygon PolygonCollider
---@return boolean
function KristalCollisions.rectPolygonInner(rect, polygon)
    --- Perform a preliminary bounds check
    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBoundsFor(rect)

    local bounds_check = CollisionUtil.rectRectInside(
        rect.x, rect.y, rect.width, rect.height,
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.rectPolygonInside(
        rect.x, rect.y, rect.width, rect.height,
        polygon:getPointsFor(rect)
    )
end

--#endregion

--#endregion
--#region LineCollider Collisions

--#region        LineCollider / Hitbox

---@param line LineCollider
---@param rect Hitbox
---@return boolean
function KristalCollisions.lineRectInner(line, rect)
    return false -- Only a point or line can be inside a line
end

--#endregion
--#region [Base] LineCollider / LineCollider

---@param a LineCollider
---@param b LineCollider
---@return boolean
function KristalCollisions.lineLine(a, b)
    local b_x1, b_y1, b_x2, b_y2 = b:getLineFor(a)

    return CollisionUtil.lineLine(
        a.x1, a.y1, a.x2, a.y2,
        b_x1, b_y1, b_x2, b_y2
    )
end

---@param a LineCollider
---@param b LineCollider
---@return boolean
function KristalCollisions.lineLineInner(a, b)
    local b_x1, b_y1, b_x2, b_y2 = b:getLineFor(a)

    return CollisionUtil.lineLineInside(
        a.x1, a.y1, a.x2, a.y2,
        b_x1, b_y1, b_x2, b_y2
    )
end

--#endregion
--#region [Base] LineCollider / CircleCollider

---@param line LineCollider
---@param circle CircleCollider
---@return boolean
function KristalCollisions.lineCircle(line, circle)
    local circle_x, circle_y, circle_radius = circle:getCircleFor(line)

    return CollisionUtil.lineCircle(
        line.x1, line.y1, line.x2, line.y2,
        circle_x, circle_y, circle_radius
    )
end

---@param line LineCollider
---@param circle CircleCollider
---@return boolean
function KristalCollisions.lineCircleInner(line, circle)
    return false -- Only a point or line can be inside a line
end

--#endregion
--#region [Base] LineCollider / PointCollider

---@param line LineCollider
---@param point PointCollider
---@return boolean
function KristalCollisions.linePoint(line, point)
    local point_x, point_y = point:getPointFor(line)

    return CollisionUtil.linePoint(
        line.x1, line.y1, line.x2, line.y2,
        point_x, point_y
    )
end

---@param line LineCollider
---@param point PointCollider
---@return boolean
function KristalCollisions.linePointInner(line, point)
    local point_x, point_y = point:getPointFor(line)

    return CollisionUtil.linePointInside(
        line.x1, line.y1, line.x2, line.y2,
        point_x, point_y
    )
end

--#endregion
--#region        LineCollider / PolygonCollider

---@param line LineCollider
---@param polygon PolygonCollider
---@return boolean
function KristalCollisions.linePolygonInner(line, polygon)
    return false -- Only a point or line can be inside a line
end

--#endregion

--#endregion
--#region CircleCollider Collisions

--#region        CircleCollider / Hitbox

---@param circle CircleCollider
---@param rect Hitbox
---@return boolean
function KristalCollisions.circleRectInner(circle, rect)
    local rect_aabb, rect_shape = rect:getRectOrPolyFor(circle)

    if rect_aabb then
        return CollisionUtil.circleRectInside(
            circle.x, circle.y, circle.radius,
            rect_shape[1], rect_shape[2], rect_shape[3], rect_shape[4]
        )
    else
        -- Calculation is simple, skip the usual bounds check
        return CollisionUtil.circlePolygonInside(
            circle.x, circle.y, circle.radius,
            rect_shape
        )
    end
end

--#endregion
--#region        CircleCollider / LineCollider

---@param circle CircleCollider
---@param line LineCollider
---@return boolean
function KristalCollisions.circleLineInner(circle, line)
    local line_x1, line_y1, line_x2, line_y2 = line:getLineFor(circle)

    return CollisionUtil.circleLineInside(
        circle.x, circle.y, circle.radius,
        line_x1, line_y1, line_x2, line_y2
    )
end

--#endregion
--#region [Base] CircleCollider / CircleCollider

---@param a CircleCollider
---@param b CircleCollider
---@return boolean
function KristalCollisions.circleCircle(a, b)
    local b_x, b_y, b_radius = b:getCircleFor(a)

    return CollisionUtil.circleCircle(
        a.x, a.y, a.radius,
        b_x, b_y, b_radius
    )
end

---@param a CircleCollider
---@param b CircleCollider
---@return boolean
function KristalCollisions.circleCircleInner(a, b)
    local b_x, b_y, b_radius = b:getCircleFor(a)

    return CollisionUtil.circleCircleInside(
        a.x, a.y, a.radius,
        b_x, b_y, b_radius
    )
end

--#endregion
--#region [Base] CircleCollider / PointCollider

---@param circle CircleCollider
---@param point PointCollider
---@return boolean
function KristalCollisions.circlePoint(circle, point)
    local point_x, point_y = point:getPointFor(circle)

    return CollisionUtil.circlePoint(
        circle.x, circle.y, circle.radius,
        point_x, point_y
    )
end

---@param circle CircleCollider
---@param point PointCollider
---@return boolean
function KristalCollisions.circlePointInner(circle, point)
    local point_x, point_y = point:getPointFor(circle)

    return CollisionUtil.circlePointInside(
        circle.x, circle.y, circle.radius,
        point_x, point_y
    )
end

--#endregion
--#region        CircleCollider / PolygonCollider

---@param circle CircleCollider
---@param polygon PolygonCollider
---@return boolean
function KristalCollisions.circlePolygonInner(circle, polygon)
    -- Perform a preliminary bounds check
    local circle_bounds_x, circle_bounds_y, circle_bounds_w, circle_bounds_h = circle:getBounds()
    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBoundsFor(circle)

    local bounds_check = CollisionUtil.rectRectInside(
        circle_bounds_x, circle_bounds_y, circle_bounds_w, circle_bounds_h,
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.circlePolygonInside(
        circle.x, circle.y, circle.radius,
        polygon:getPointsFor(circle)
    )
end

--#endregion

--#endregion
--#region PointCollider Collisions

--#region        PointCollider / Hitbox

---@param point PointCollider
---@param rect Hitbox
---@return boolean
function KristalCollisions.pointRectInner(point, rect)
    return false -- Only a point can be inside a point
end

--#endregion
--#region        PointCollider / LineCollider

---@param point PointCollider
---@param line LineCollider
---@return boolean
function KristalCollisions.pointLineInner(point, line)
    return false -- Only a point can be inside a point
end


--#endregion
--#region        PointCollider / CircleCollider

---@param point PointCollider
---@param circle CircleCollider
---@return boolean
function KristalCollisions.pointCircleInner(point, circle)
    return false -- Only a point can be inside a point
end

--#endregion
--#region [Base] PointCollider / PointCollider

---@param a PointCollider
---@param b PointCollider
---@return boolean
function KristalCollisions.pointPoint(a, b)
    local b_x, b_y = b:getPointFor(a)

    return CollisionUtil.pointPoint(
        a.x, a.y,
        b_x, b_y
    )
end

---@param a PointCollider
---@param b PointCollider
---@return boolean
function KristalCollisions.pointPointInner(a, b)
    local b_x, b_y = b:getPointFor(a)

    return CollisionUtil.pointPointInside(
        a.x, a.y,
        b_x, b_y
    )
end

--#endregion
--#region        PointCollider / PolygonCollider

---@param point PointCollider
---@param polygon PolygonCollider
---@return boolean
function KristalCollisions.pointPolygonInner(point, polygon)
    return false -- Only a point can be inside a point
end

--#endregion

--#endregion
--#region PolygonCollider Collisions

--#region [Base] PolygonCollider / Hitbox

---@param polygon PolygonCollider
---@param rect Hitbox
---@return boolean
function KristalCollisions.polygonRect(polygon, rect)
    local rect_aabb, rect_shape = rect:getRectOrPolyFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()

    if rect_aabb then
        local rect_x, rect_y, rect_w, rect_h = rect_shape[1], rect_shape[2], rect_shape[3], rect_shape[4]

        -- Perform a preliminary bounds check
        local bounds_check = CollisionUtil.rectRect(
            poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
            rect_x, rect_y, rect_w, rect_h
        )

        if not bounds_check then
            return false
        end

        return CollisionUtil.polygonRect(
            polygon:getPointsDirect(),
            rect_x, rect_y, rect_w, rect_h
        )
    else
        local rect_bounds_x, rect_bounds_y, rect_bounds_w, rect_bounds_h = Utils.getPolygonBounds(rect_shape)

        -- Perform a preliminary bounds check
        local bounds_check = CollisionUtil.rectRect(
            poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
            rect_bounds_x, rect_bounds_y, rect_bounds_w, rect_bounds_h
        )

        if not bounds_check then
            return false
        end

        return CollisionUtil.polygonPolygon(
            polygon:getPointsDirect(),
            rect_shape
        )
    end
end

---@param polygon PolygonCollider
---@param rect Hitbox
---@return boolean
function KristalCollisions.polygonRectInner(polygon, rect)
    local rect_aabb, rect_shape = rect:getRectOrPolyFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()

    if rect_aabb then
        local rect_x, rect_y, rect_w, rect_h = rect_shape[1], rect_shape[2], rect_shape[3], rect_shape[4]

        -- Perform a preliminary bounds check
        local bounds_check = CollisionUtil.rectRectInside(
            poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
            rect_x, rect_y, rect_w, rect_h
        )

        if not bounds_check then
            return false
        end

        return CollisionUtil.polygonRectInside(
            polygon:getPointsDirect(),
            rect_x, rect_y, rect_w, rect_h
        )
    else
        local rect_bounds_x, rect_bounds_y, rect_bounds_w, rect_bounds_h = Utils.getPolygonBounds(rect_shape)

        -- Perform a preliminary bounds check
        local bounds_check = CollisionUtil.rectRectInside(
            poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
            rect_bounds_x, rect_bounds_y, rect_bounds_w, rect_bounds_h
        )

        if not bounds_check then
            return false
        end

        return CollisionUtil.polygonPolygonInside(
            polygon:getPointsDirect(),
            rect_shape
        )
    end
end

--#endregion
--#region [Base] PolygonCollider / LineCollider

---@param polygon PolygonCollider
---@param line LineCollider
---@return boolean
function KristalCollisions.polygonLine(polygon, line)
    local line_x1, line_y1, line_x2, line_y2 = line:getLineFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()
    local line_bounds_x, line_bounds_y, line_bounds_w, line_bounds_h = Utils.getLineBounds(line_x1, line_y1, line_x2, line_y2)

    -- Perform a preliminary bounds check
    local bounds_check = CollisionUtil.rectRect(
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
        line_bounds_x, line_bounds_y, line_bounds_w, line_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonLine(
        polygon:getPointsDirect(),
        line_x1, line_y1, line_x2, line_y2
    )
end

---@param polygon PolygonCollider
---@param line LineCollider
---@return boolean
function KristalCollisions.polygonLineInner(polygon, line)
    local line_x1, line_y1, line_x2, line_y2 = line:getLineFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()

    -- Perform a preliminary bounds check
    -- Rect/Line inner collision is very cheap
    local bounds_check = CollisionUtil.rectLineInside(
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
        line_x1, line_y1, line_x2, line_y2
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonLineInside(
        polygon:getPointsDirect(),
        line_x1, line_y1, line_x2, line_y2
    )
end

--#endregion
--#region [Base] PolygonCollider / CircleCollider

---@param polygon PolygonCollider
---@param circle CircleCollider
---@return boolean
function KristalCollisions.polygonCircle(polygon, circle)
    local circle_x, circle_y, circle_r = circle:getCircleFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()
    local circle_bounds_x, circle_bounds_y, circle_bounds_w, circle_bounds_h = Utils.getCircleBounds(circle_x, circle_y, circle_r)

    -- Perform a preliminary bounds check
    local bounds_check = CollisionUtil.rectRect(
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
        circle_bounds_x, circle_bounds_y, circle_bounds_w, circle_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonCircle(
        polygon:getPointsDirect(),
        circle_x, circle_y, circle_r
    )
end

---@param polygon PolygonCollider
---@param circle CircleCollider
---@return boolean
function KristalCollisions.polygonCircleInner(polygon, circle)
    local circle_x, circle_y, circle_r = circle:getCircleFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()

    -- Perform a preliminary bounds check
    -- Rect/Circle inner collision is very cheap
    local bounds_check = CollisionUtil.rectCircleInside(
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
        circle_x, circle_y, circle_r
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonCircleInside(
        polygon:getPointsDirect(),
        circle_x, circle_y, circle_r
    )
end

--#endregion
--#region [Base] PolygonCollider / PointCollider

---@param polygon PolygonCollider
---@param point PointCollider
---@return boolean
function KristalCollisions.polygonPoint(polygon, point)
    local point_x, point_y = point:getPointFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()

    -- Perform a preliminary bounds check
    local bounds_check = CollisionUtil.rectPoint(
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
        point_x, point_y
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonPoint(
        polygon:getPointsDirect(),
        point_x, point_y
    )
end

---@param polygon PolygonCollider
---@param point PointCollider
---@return boolean
function KristalCollisions.polygonPointInner(polygon, point)
    local point_x, point_y = point:getPointFor(polygon)

    local poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h = polygon:getBounds()

    -- Perform a preliminary bounds check
    local bounds_check = CollisionUtil.rectPointInside(
        poly_bounds_x, poly_bounds_y, poly_bounds_w, poly_bounds_h,
        point_x, point_y
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonPointInside(
        polygon:getPointsDirect(),
        point_x, point_y
    )
end

--#endregion
--#region [Base] PolygonCollider / PolygonCollider

---@param a PolygonCollider
---@param b PolygonCollider
---@return boolean
function KristalCollisions.polygonPolygon(a, b)
    local a_bounds_x, a_bounds_y, a_bounds_w, a_bounds_h = a:getBounds()
    local b_bounds_x, b_bounds_y, b_bounds_w, b_bounds_h = b:getBoundsFor(a)

    -- Perform a preliminary bounds check
    local bounds_check = CollisionUtil.rectRect(
        a_bounds_x, a_bounds_y, a_bounds_w, a_bounds_h,
        b_bounds_x, b_bounds_y, b_bounds_w, b_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonPolygon(
        a:getPointsDirect(),
        b:getPointsFor(a)
    )
end

---@param a PolygonCollider
---@param b PolygonCollider
---@return boolean
function KristalCollisions.polygonPolygonInner(a, b)
    local a_bounds_x, a_bounds_y, a_bounds_w, a_bounds_h = a:getBounds()
    local b_bounds_x, b_bounds_y, b_bounds_w, b_bounds_h = b:getBoundsFor(a)

    -- Perform a preliminary bounds check
    local bounds_check = CollisionUtil.rectRectInside(
        a_bounds_x, a_bounds_y, a_bounds_w, a_bounds_h,
        b_bounds_x, b_bounds_y, b_bounds_w, b_bounds_h
    )

    if not bounds_check then
        return false
    end

    return CollisionUtil.polygonPolygonInside(
        a:getPointsDirect(),
        b:getPointsFor(a)
    )
end

--#endregion

--#endregion
--#region ColliderGroup Collisions

--#region [Base] ColliderGroup / any

---@param group ColliderGroup
---@param collider Collider
---@return boolean
function KristalCollisions.groupAny(group, collider)
    for _, child_collider in ipairs(group:getCollidersDirect()) do
        if child_collider:meetsCollider(collider) then
            return true
        end
    end

    return false
end

--#endregion

--#endregion

return KristalCollisions
