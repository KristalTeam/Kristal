local CollisionUtil = {}
local self = CollisionUtil

local sqrt = math.sqrt
local min = math.min
local max = math.max
local pow = math.pow
local dist = function(x1,y1, x2,y2)
    local dx, dy = x1-x2, y1-y2
    return sqrt((dx*dx)+(dy*dy))
end
local clamp = function(v, a, b)
    return max(a, min(b, v))
end

-- Point

---@return boolean
function CollisionUtil.pointPoint(x1,y1, x2,y2)
    return x1 == x2 and y1 == y2
end
---@return boolean
function CollisionUtil.pointPointInside(x1,y1, x2,y2)
    return x1 == x2 and y1 == y2
end

---@return boolean
function CollisionUtil.pointCircle(px,py, cx,cy,cr)
    return dist(px,py, cx,cy) <= cr
end
---@return boolean
function CollisionUtil.pointCircleInside(px,py, cx,cy,cr)
    return false -- only a point can be inside a point
end

---@return boolean
function CollisionUtil.pointRect(px,py, rx,ry,rw,rh)
    return px >= rx and px < rx+rw and py >= ry and py < ry+rh
end
---@return boolean
function CollisionUtil.pointRectInside(px,py, rx,ry,rw,rh)
    return false -- only a point can be inside a point
end

---@return boolean
function CollisionUtil.pointLine(px,py, x1,y1,x2,y2, precision)
    return self.linePoint(x1,y1,x2,y2, px,py, precision)
end
---@return boolean
function CollisionUtil.pointLineInside(px,py, x1,y1,x2,y2, precision)
    return false -- only a point can be inside a point
end

---@param poly number[][]
---@return boolean
function CollisionUtil.pointPolygon(px,py, poly)
    return self.polygonPoint(poly, px,py)
end
---@param poly number[][]
---@return boolean
function CollisionUtil.pointPolygonInside(px,py, poly)
    return false -- only a point can be inside a point
end

-- Circle

---@return boolean
function CollisionUtil.circlePoint(cx,cy,cr, px,py)
    return self.pointCircle(px,py, cx,cy,cr)
end
---@return boolean
function CollisionUtil.circlePointInside(cx,cy,cr, px,py)
    return self.pointCircle(px,py, cx,cy,cr)
end

---@return boolean
function CollisionUtil.circleCircle(x1,y1,r1, x2,y2,r2)
    return dist(x1,y1, x2,y2) <= r1+r2
end
---@return boolean
function CollisionUtil.circleCircleInside(x1,y1,r1, x2,y2,r2)
    return dist(x1,y1, x2,y2) + r2 <= r1
end

---@return boolean
function CollisionUtil.circleRect(cx,cy,cr, rx,ry,rw,rh)
    return self.rectCircle(rx,ry,rw,rh, cx,cy,cr)
end
---@return boolean
function CollisionUtil.circleRectInside(cx,cy,cr, rx,ry,rw,rh)
    return dist(cx,cy, rx,ry) <= cr
       and dist(cx,cy, rx+rw,ry) <= cr
       and dist(cx,cy, rx,ry+rh) <= cr
       and dist(cx,cy, rx+rw,ry+rh) <= cr
end

---@return boolean
function CollisionUtil.circleLine(cx,cy,cr, x1,y1,x2,y2)
    return self.lineCircle(x1,y1,x2,y2, cx,cy,cr)
end
---@return boolean
function CollisionUtil.circleLineInside(cx,cy,cr, x1,y1,x2,y2)
    return dist(cx,cy, x1,y1) <= cr and dist(cx,cy, x2,y2) <= cr
end

---@param poly number[][]
---@return boolean
function CollisionUtil.circlePolygon(cx,cy,cr, poly)
    return self.polygonCircle(poly, cx,cy,cr)
end
---@param poly number[][]
---@return boolean
function CollisionUtil.circlePolygonInside(cx,cy,cr, poly)
    for _,v in ipairs(poly) do
        if dist(cx,cy, v[1],v[2]) > cr then
            return false
        end
    end
    return true
end

-- Rectangle

---@return boolean
function CollisionUtil.rectPoint(rx,ry,rw,rh, px,py)
    return self.pointRect(px,py, rx,ry,rw,rh)
end
---@return boolean
function CollisionUtil.rectPointInside(rx,ry,rw,rh, px,py)
    return self.pointRect(px,py, rx,ry,rw,rh)
end

---@return boolean
function CollisionUtil.rectCircle(rx,ry,rw,rh, cx,cy,cr)
    local ex, ey = clamp(cx, rx, rx+rw), clamp(cy, ry, ry+rh)
    return dist(cx,cy, ex,ey) <= cr
end
---@return boolean
function CollisionUtil.rectCircleInside(rx,ry,rw,rh, cx,cy,cr)
    return self.pointRect(cx,cy, rx+cr,ry+cr,rw-cr*2,rh-cr*2)
end

---@return boolean
function CollisionUtil.rectRect(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 + w1 >= x2 and x1 <= x2 + w2 and y1 + h1 >= y2 and y1 <= y2 + h2
end
---@return boolean
function CollisionUtil.rectRectInside(x1,y1,w1,h1, x2,y2,w2,h2)
    return x2 >= x1 and y2 >= y1 and x2+w2 <= x1+w1 and y2+h2 <= y1+h1
end

---@return boolean
function CollisionUtil.rectLine(rx,ry,rw,rh, x1,y1,x2,y2)
    return self.lineRect(x1,y1,x2,y2, rx,ry,rw,rh)
end
---@return boolean
function CollisionUtil.rectLineInside(rx,ry,rw,rh, x1,y1,x2,y2)
    return self.pointRect(x1,y1, rx,ry,rw,rh) and self.pointRect(x2,y2, rx,ry,rw,rh)
end

---@param poly number[][]
---@return boolean
function CollisionUtil.rectPolygon(rx,ry,rw,rh, poly)
    return self.polygonRect(poly, rx,ry,rw,rh)
end
---@param poly number[][]
---@return boolean
function CollisionUtil.rectPolygonInside(rx,ry,rw,rh, poly)
    for _,v in ipairs(poly) do
        if not self.pointRect(v[1],v[2], rx,ry,rw,rh) then
            return false
        end
    end
    return true
end

-- Line

---@return boolean
function CollisionUtil.linePoint(x1,y1,x2,y2, px,py, precision)
    local d1 = dist(px,py, x1,y1)
    local d2 = dist(px,py, x2,y2)

    local len = dist(x1,y1, x2,y2)

    local buffer = precision or 0.01

    return d1+d2 >= len-buffer and d1+d2 <= len+buffer
end
---@return boolean
function CollisionUtil.linePointInside(x1,y1,x2,y2, px,py, precision)
    return self.linePoint(x1,y1,x2,y2, px,py, precision)
end

---@return boolean
function CollisionUtil.lineCircle(x1,y1,x2,y2, cx,cy,cr)
    local inside1 = self.pointCircle(x1,y1, cx,cy,cr)
    local inside2 = self.pointCircle(x2,y2, cx,cy,cr)
    if inside1 or inside2 then return true end

    local len = dist(x1,y1, x2,y2)
    local dot = (((cx-x1)*(x2-x1)) + ((cy-y1)*(y2-y1))) / pow(len,2)

    local closest_x = x1 + (dot * (x2-x1))
    local closest_y = y1 + (dot * (y2-y1))

    if not self.linePoint(x1,y1,x2,y2, closest_x,closest_y) then return false end

    return dist(closest_x,closest_y, cx,cy) <= cr
end
---@return boolean
function CollisionUtil.lineCircleInside(x1,y1,x2,y2, cx,cy,cr)
    return false -- only a point or a line can be inside a line
end

---@return boolean
function CollisionUtil.lineRect(x1,y1,x2,y2, rx,ry,rw,rh)
    return self.lineLine(x1,y1,x2,y2, rx,ry,rx,ry+rh) or
           self.lineLine(x1,y1,x2,y2, rx+rw,ry,rx+rw,ry+rh) or
           self.lineLine(x1,y1,x2,y2, rx,ry,rx+rw,ry) or
           self.lineLine(x1,y1,x2,y2, rx,ry+rh,rx+rw,ry+rh) or
           self.pointRect(x1,y1, rx,ry,rw,rh)
end
---@return boolean
function CollisionUtil.lineRectInside(x1,y1,x2,y2, rx,ry,rw,rh)
    return false -- only a point or a line can be inside a line
end

---@return boolean
function CollisionUtil.lineLine(x1,y1,x2,y2, x3,y3,x4,y4)
    local ua = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    local ub = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
    return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1
end
---@return boolean
function CollisionUtil.lineLineInside(x1,y1,x2,y2, x3,y3,x4,y4)
    return (x1 == x3 and y1 == y3 and x2 == x4 and y2 == y4)
        or (x1 == x4 and y1 == y4 and x2 == x3 and y2 == y3)
end

---@param poly number[][]
---@return boolean
function CollisionUtil.linePolygon(x1,y1,x2,y2, poly)
    return self.polygonLine(poly, x1,y1,x2,y2)
end
---@param poly number[][]
---@return boolean
function CollisionUtil.linePolygonInside(x1,y1,x2,y2, poly)
    return false -- only a point or a line can be inside a line
end

-- Polygon

---@param poly number[][]
---@return boolean
function CollisionUtil.polygonPoint(poly, px,py)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if ((vc[2] > py) ~= (vn[2] > py)) and (px < (vn[1]-vc[1]) * (py-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end
---@param poly number[][]
---@return boolean
function CollisionUtil.polygonPointInside(poly, px,py)
    return self.polygonPoint(poly, px,py)
end

---@param poly number[][]
---@return boolean
function CollisionUtil.polygonCircle(poly, cx,cy,cr)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if self.lineCircle(vc[1],vc[2],vn[1],vn[2], cx,cy,cr) then
            return true
        end

        if ((vc[2] > cy) ~= (vn[2] > cy)) and (cx < (vn[1]-vc[1]) * (cy-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end
---@param poly number[][]
---@return boolean
function CollisionUtil.polygonCircleInside(poly, cx,cy,cr)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if self.lineCircle(vc[1],vc[2],vn[1],vn[2], cx,cy,cr) then
            return false
        end

        if ((vc[2] > cy) ~= (vn[2] > cy)) and (cx < (vn[1]-vc[1]) * (cy-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end

---@param poly number[][]
---@return boolean
function CollisionUtil.polygonRect(poly, rx,ry,rw,rh)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if self.lineRect(vc[1],vc[2],vn[1],vn[2], rx,ry,rw,rh) then
            return true
        end

        if ((vc[2] > ry) ~= (vn[2] > ry)) and (rx < (vn[1]-vc[1]) * (ry-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end
---@param poly number[][]
---@return boolean
function CollisionUtil.polygonRectInside(poly, rx,ry,rw,rh)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if self.lineRect(vc[1],vc[2],vn[1],vn[2], rx,ry,rw,rh) then
            return false
        end

        if ((vc[2] > ry) ~= (vn[2] > ry)) and (rx < (vn[1]-vc[1]) * (ry-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end

---@param poly number[][]
---@return boolean
function CollisionUtil.polygonLine(poly, x1,y1,x2,y2)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if self.lineLine(vc[1],vc[2],vn[1],vn[2], x1,y1,x2,y2) then
            return true
        end

        if ((vc[2] > y1) ~= (vn[2] > y1)) and (x1 < (vn[1]-vc[1]) * (y1-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end
---@param poly number[][]
---@return boolean
function CollisionUtil.polygonLineInside(poly, x1,y1,x2,y2)
    local collided = false
    for i = 1, #poly do
        local vc = poly[i]
        local vn = poly[(i % #poly) + 1]

        if self.lineLine(vc[1],vc[2],vn[1],vn[2], x1,y1,x2,y2) then
            return false
        end

        if ((vc[2] > y1) ~= (vn[2] > y1)) and (x1 < (vn[1]-vc[1]) * (y1-vc[2]) / (vn[2]-vc[2]) + vc[1]) then
            collided = not collided
        end
    end
    return collided
end

---@param poly1 number[][]
---@param poly2 number[][]
---@return boolean
function CollisionUtil.polygonPolygon(poly1, poly2)
    for i = 1, #poly1 do
        local vc = poly1[i]
        local vn = poly1[(i % #poly1) + 1]

        if self.polygonLine(poly2, vc[1],vc[2],vn[1],vn[2]) then
            return true
        end
    end
    return (#poly1>0 and self.polygonPoint(poly2, poly1[1][1],poly1[1][2])) or
           (#poly2>0 and self.polygonPoint(poly1, poly2[1][1],poly2[1][2]))
end
---@param poly1 number[][]
---@param poly2 number[][]
---@return boolean
function CollisionUtil.polygonPolygonInside(poly1, poly2)
    for i = 1, #poly1 do
        local vc = poly1[i]
        local vn = poly1[(i % #poly1) + 1]

        if self.polygonLine(poly2, vc[1],vc[2],vn[1],vn[2]) then
            return false
        end
    end
    return (#poly1>0 and self.polygonPoint(poly2, poly1[1][1],poly1[1][2])) or
           (#poly2>0 and self.polygonPoint(poly1, poly2[1][1],poly2[1][2]))
end

return CollisionUtil