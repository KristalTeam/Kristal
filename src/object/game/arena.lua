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

function Arena:onAdd(parent)
    self.visible = false

    local afterimage_count = 0
    local last_afterimage
    Game.battle.timer:every(1/30, function()
        if last_afterimage then
           last_afterimage.add_alpha = 0
        end

        afterimage_count = afterimage_count + 1
        if afterimage_count > 15 then
            self.visible = true
            return false
        else
            local progress = afterimage_count / 15

            local sx, sy = self:getScale()
            local rot = self.rotation
            self:setScale(sx * progress, sy * progress)
            self.rotation = rot + (math.pi) * (1 - progress)

            local afterimg = AfterImage(self, 0.6 - (0.5 * progress))
            afterimg.add_alpha = (progress - (0.6 - (0.5 * progress)))
            parent:addChild(afterimg)
            afterimg:setLayer(self.layer + (1 - progress))
            last_afterimage = afterimg

            self:setScale(sx, sy)
            self.rotation = rot
        end
    end)
end

function Arena:onRemove(parent)
    self.parent = parent
    local afterimg = AfterImage(self, 0.1)
    afterimg.add_alpha = 0.9
    Game.battle:addChild(afterimg)
    self.parent = nil

    local afterimage_count = 0
    local last_afterimage = afterimg
    Game.battle.timer:every(1/30, function()
        if last_afterimage then
           last_afterimage.add_alpha = 0
        end

        afterimage_count = afterimage_count + 1
        if afterimage_count > 15 then
            self.visible = true
            return false
        else
            local progress = 1 - (afterimage_count / 15)

            local sx, sy = self:getScale()
            local rot = self.rotation
            self:setScale(sx * progress, sy * progress)
            self.rotation = rot + (math.pi) * (1 - progress)

            local afterimg = AfterImage(self, 0.6 - (0.5 * progress))
            afterimg.add_alpha = (progress - (0.6 - (0.5 * progress)))
            parent:addChild(afterimg)
            afterimg:setLayer(self.layer + (1 - progress))
            last_afterimage = afterimg

            self:setScale(sx, sy)
            self.rotation = rot
        end
    end)
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