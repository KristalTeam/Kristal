local Testing = {}

function Testing:enter()
    self.target_x = SCREEN_WIDTH/2
    self.target_y = SCREEN_HEIGHT/2
end

function Testing:update(dt)
end

function Testing:draw()
    love.graphics.clear(1, 1, 1)
    love.graphics.setPointSize(4)
    love.graphics.setLineWidth(4)
    local ix, iy, ints

    local centerx, centery = SCREEN_WIDTH/2, SCREEN_HEIGHT/2
    local mx, my = love.mouse.getX() / Kristal.Config["windowScale"], love.mouse.getY() / Kristal.Config["windowScale"]

    local points = {{centerx-100, centery-100}, {centerx+60, centery-100}, {centerx, centery}, {centerx+100, centery-60}, {centerx, centery+100}, {centerx-100, centery}}
    local points2 = {{mx-35,my-35}, {mx,my-10}, {mx+35,my-35}, {mx+10,my}, {mx+35,my+35}, {mx,my+10}, {mx-35,my+35}, {mx-10,my}}

    local hit = CollisionUtil.polygonPolygon(points, points2)

    if hit then
        love.graphics.setColor(1, 0.5, 0)
    else
        love.graphics.setColor(0, 0.5, 1)
    end
    --love.graphics.rectangle("fill", rx,ry, rw,rh)
    self:drawPolygon(points)

    love.graphics.setColor(0, 0, 0, 0.5)
    --love.graphics.line(x1,y1, x2,y2)
    self:drawPolygon(points2)

    if hit then
        if ix and iy then
            self:drawIntersect(ix, iy)
        elseif ints then
            for _,i in ipairs(ints) do
                self:drawIntersect(i[1], i[2])
            end
        end
    end
end

function Testing:mousepressed(x, y, btn)
    self.target_x = x
    self.target_y = y
end

function Testing:drawPolygon(points)
    local unpacked = {}
    for _,point in ipairs(points) do
        table.insert(unpacked, point[1])
        table.insert(unpacked, point[2])
    end
    local triangles = love.math.triangulate(unpacked)
    for _,triangle in ipairs(triangles) do
        love.graphics.polygon("fill", unpack(triangle))
    end
end

function Testing:drawIntersect(x, y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", x, y, 5)
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", x, y, 4)
end

return Testing