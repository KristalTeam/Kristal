local Arena, super = Class(Object)

function Arena:init(x, y, shape)
    super:init(self, x, y)

    self:setOrigin(0.5, 0.5)

    self.color = {0, 0.75, 0}

    self.collider = ColliderGroup(self)

    self.line_width = 4 -- must call setShape again if u change this
    self:setShape(shape or {{0, 0}, {142, 0}, {142, 142}, {0, 142}})
end

function Arena:setShape(shape)
    self.shape = shape
    self.processed_shape = Utils.copy(shape, true)

    local min_x, min_y, max_x, max_y
    for _,point in ipairs(self.shape) do
        min_x, min_y = math.min(min_x or point[1], point[1]), math.min(min_y or point[2], point[2])
        max_x, max_y = math.max(max_x or point[1], point[1]), math.max(max_y or point[2], point[2])
    end
    for _,point in ipairs(self.shape) do
        point[1] = point[1] - min_x
        point[2] = point[2] - min_y
    end
    self.width = max_x - min_x
    self.height = max_y - min_y

    self.triangles = love.math.triangulate(Utils.unpackPolygon(self.shape))

    self.border_line = {Utils.unpackPolygon(Utils.getPolygonOffset(self.shape, self.line_width/2))}

    local edges = Utils.getPolygonEdges(self.shape)

    self.collider.colliders = {}
    for _,v in ipairs(edges) do
        table.insert(self.collider.colliders, LineCollider(v[1][1], v[1][2], v[2][1], v[2][2], self))
    end
end

function Arena:getCenter()
    return self:getTransform():transformPoint(self.width/2, self.height/2)
end

function Arena:update(dt)
    if not Utils.equal(self.processed_shape, self.shape) then
        self:setShape(self.shape)
    end

    self:updateChildren(dt)
end

function Arena:draw()
    love.graphics.setColor(0, 0, 0)
    for _,triangle in ipairs(self.triangles) do
        love.graphics.polygon("fill", unpack(triangle))
    end

    self:drawChildren()

    love.graphics.setColor(self:getDrawColor())
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(self.line_width)
    love.graphics.line(unpack(self.border_line))
end

return Arena