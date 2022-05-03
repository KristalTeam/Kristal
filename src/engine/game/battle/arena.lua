local Arena, super = Class(Object)

function Arena:init(x, y, shape)
    super:init(self, x, y)

    self:setOrigin(0.5, 0.5)

    self.color = {0, 0.75, 0}
    self.bg_color = {0, 0, 0}

    self.x = math.floor(self.x)
    self.y = math.floor(self.y)

    self.collider = ColliderGroup(self)

    self.line_width = 4 -- must call setShape again if u change this
    self:setShape(shape or {{0, 0}, {142, 0}, {142, 142}, {0, 142}})

    self.sprite = ArenaSprite(self)
    self:addChild(self.sprite)

    self.mask = ArenaMask(1, 0, 0, self)
    self:addChild(self.mask)
end

function Arena:setSize(width, height)
    self:setShape{{0, 0}, {width, 0}, {width, height}, {0, height}}
end

function Arena:setShape(shape)
    self.shape = Utils.copy(shape, true)
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

    self.processed_width = self.width
    self.processed_height = self.height

    self.left = math.floor(self.x - self.width/2)
    self.right = math.floor(self.x + self.width/2)
    self.top = math.floor(self.y - self.height/2)
    self.bottom = math.floor(self.y + self.height/2)

    self.triangles = love.math.triangulate(Utils.unpackPolygon(self.shape))

    self.border_line = {Utils.unpackPolygon(Utils.getPolygonOffset(self.shape, self.line_width/2))}

    local edges = Utils.getPolygonEdges(self.shape)

    self.clockwise = Utils.isPolygonClockwise(edges)

    self.area_collider = PolygonCollider(self, Utils.copy(shape, true))

    self.collider.colliders = {}
    for _,v in ipairs(edges) do
        table.insert(self.collider.colliders, LineCollider(self, v[1][1], v[1][2], v[2][1], v[2][2]))
    end
end

function Arena:setBackgroundColor(r, g, b, a)
    self.bg_color = {r, g, b, a or 1}
end

function Arena:getBackgroundColor()
    return self.bg_color
end

function Arena:getCenter()
    return self:getRelativePos(self.width/2, self.height/2)
end

function Arena:getTopLeft() return self:getRelativePos(0, 0) end
function Arena:getTopRight() return self:getRelativePos(self.width, 0) end
function Arena:getBottomLeft() return self:getRelativePos(0, self.height) end
function Arena:getBottomRight() return self:getRelativePos(self.width, self.height) end

function Arena:getLeft() local x, y = self:getTopLeft(); return x end
function Arena:getRight() local x, y = self:getBottomRight(); return x end
function Arena:getTop() local x, y = self:getTopLeft(); return y end
function Arena:getBottom() local x, y = self:getBottomRight(); return y end

function Arena:onAdd(parent)
    self.sprite:setScale(0, 0)
    self.sprite.alpha = 0.5
    self.sprite.rotation = math.pi

    local center_x, center_y = self:getCenter()

    local afterimage_timer = 0
    local afterimage_count = 0
    Game.battle.timer:during(15/30, function()
        afterimage_timer = Utils.approach(afterimage_timer, 15, DTMULT)

        local real_progress = afterimage_timer / 15

        self.sprite:setScale(real_progress, real_progress)
        self.sprite.alpha = 0.5 + (0.5 * real_progress)
        self.sprite.rotation = (math.pi) * (1 - real_progress)

        while afterimage_count < math.floor(afterimage_timer) do
            afterimage_count = afterimage_count + 1

            local progress = afterimage_count / 15

            local afterimg = ArenaSprite(self, center_x, center_y)
            afterimg:setOrigin(0.5, 0.5)
            afterimg:setScale(progress, progress)
            afterimg:fadeOutAndRemove()
            afterimg.background = false
            afterimg.alpha = 0.6 - (0.5 * progress)
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
    local orig_sprite = ArenaSprite(self, self:getCenter())
    orig_sprite:setOrigin(0.5, 0.5)
    parent:addChild(orig_sprite)
    orig_sprite:setLayer(self.layer)

    local afterimage_timer = 0
    local afterimage_count = 0
    Game.battle.timer:during(15/30, function()
        afterimage_timer = Utils.approach(afterimage_timer, 15, DTMULT)

        local real_progress = 1 - (afterimage_timer / 15)

        orig_sprite:setScale(real_progress, real_progress)
        orig_sprite.alpha = 0.5 + (0.5 * real_progress)
        orig_sprite.rotation = (math.pi) * (1 - real_progress)

        while afterimage_count < math.floor(afterimage_timer) do
            afterimage_count = afterimage_count + 1

            local progress = 1 - (afterimage_count / 15)

            local afterimg = ArenaSprite(self, orig_sprite.x, orig_sprite.y)
            afterimg:setOrigin(0.5, 0.5)
            afterimg:setScale(progress, progress)
            afterimg:fadeOutAndRemove()
            afterimg.background = false
            afterimg.alpha = 0.6 - (0.5 * progress)
            afterimg.rotation = (math.pi) * (1 - progress)
            parent:addChild(afterimg)
            afterimg:setLayer(self.layer + (1 - progress))
        end
    end, function()
        orig_sprite:remove()
    end)
end

function Arena:update()
    if not Utils.equal(self.processed_shape, self.shape, true) then
        self:setShape(self.shape)
    elseif self.processed_width ~= self.width or self.processed_height ~= self.height then
        self:setSize(self.width, self.height)
    end

    super:update(self)

    if NOCLIP then return end

    local soul = Game.battle.soul
    if soul and Game.battle.soul.collidable then
        Object.startCache()
        local angle_diff = self.clockwise and -(math.pi/2) or (math.pi/2)
        for _,line in ipairs(self.collider.colliders) do
            local angle
            while soul:collidesWith(line) do
                if not angle then
                    local x1, y1 = self:getRelativePos(line.x, line.y, Game.battle)
                    local x2, y2 = self:getRelativePos(line.x2, line.y2, Game.battle)
                    angle = Utils.angle(x1, y1, x2, y2)
                end
                Object.uncache(soul)
                soul:setPosition(
                    soul.x + (math.cos(angle + angle_diff)),
                    soul.y + (math.sin(angle + angle_diff))
                )
            end
        end
        Object.endCache()
    end
end

function Arena:drawMask()
    love.graphics.push()
    self.sprite:preDraw()
    self.sprite:drawBackground()
    self.sprite:postDraw()
    love.graphics.pop()
end

function Arena:draw()
    super:draw(self)

    if DEBUG_RENDER and self.collider then
        self.collider:draw(0, 0, 1)
    end
end

return Arena