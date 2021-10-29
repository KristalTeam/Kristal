local Arena, super = Class(Object)

function Arena:init(x, y, shape)
    super:init(self, x, y)

    self:setOrigin(0.5, 0.5)

    self.color = {0, 0.75, 0}

    self.collider = ColliderGroup(self)

    self.line_width = 4 -- must call setShape again if u change this
    self:setShape(shape or {{0, 0}, {142, 0}, {142, 142}, {0, 142}})

    self.sprite = ArenaSprite(self)
    self:addChild(self.sprite)
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
    self.sprite:setScale(0, 0)
    self.sprite.alpha = 0.5
    self.sprite.rotation = math.pi

    local afterimage_timer = 0
    local afterimage_count = 0
    Game.battle.timer:during(15/30, function(dt)
        afterimage_timer = Utils.approach(afterimage_timer, 15, DTMULT)

        local real_progress = afterimage_timer / 15

        self.sprite:setScale(real_progress, real_progress)
        self.sprite.alpha = 0.5 + (0.5 * real_progress)
        self.sprite.rotation = (math.pi) * (1 - real_progress)

        while afterimage_count < math.floor(afterimage_timer) do
            afterimage_count = afterimage_count + 1

            local progress = afterimage_count / 15

            local afterimg = ArenaSprite(self, self.x, self.y)
            afterimg:setOrigin(0.5, 0.5)
            afterimg:setScale(progress, progress)
            afterimg:fade(0.6 - (0.5 * progress))
            afterimg.rotation = (math.pi) * (1 - progress)
            parent:addChild(afterimg)
            afterimg:setLayer(self.layer + (1 - progress))
        end
    end, function()
        self.sprite:setScale(1)
        self.sprite.alpha = 1
        self.sprite.rotation = 0
    end)
end

function Arena:onRemove(parent)
    local orig_sprite = ArenaSprite(self, self.x, self.y)
    orig_sprite:setOrigin(0.5, 0.5)
    parent:addChild(orig_sprite)
    orig_sprite:setLayer(self.layer)

    local afterimage_timer = 0
    local afterimage_count = 0
    Game.battle.timer:during(15/30, function(dt)
        afterimage_timer = Utils.approach(afterimage_timer, 15, DTMULT)

        local real_progress = 1 - (afterimage_timer / 15)

        orig_sprite:setScale(real_progress, real_progress)
        orig_sprite.alpha = 0.5 + (0.5 * real_progress)
        orig_sprite.rotation = (math.pi) * (1 - real_progress)

        while afterimage_count < math.floor(afterimage_timer) do
            afterimage_count = afterimage_count + 1

            local progress = 1 - (afterimage_count / 15)

            local afterimg = ArenaSprite(self, self.x, self.y)
            afterimg:setOrigin(0.5, 0.5)
            afterimg:setScale(progress, progress)
            afterimg:fade(0.6 - (0.5 * progress))
            afterimg.rotation = (math.pi) * (1 - progress)
            parent:addChild(afterimg)
            afterimg:setLayer(self.layer + (1 - progress))
        end
    end, function()
        orig_sprite:remove()
    end)
end

function Arena:update(dt)
    if not Utils.equal(self.processed_shape, self.shape) then
        self:setShape(self.shape)
    end

    self:updateChildren(dt)
end

return Arena