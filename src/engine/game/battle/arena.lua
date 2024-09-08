--- The region that the player is confined to within waves in a battle.
--- Usually accessed through [`Game.battle.arena`](lua://Battle.arena), which is only set during waves.
---
---@class Arena : Object
---
---@field color         table           The color of the arena border (Defaults to `{0, 0.75, 0}`)   
---@field bg_color      table           The color of the back of the arena (Defaults to `{0, 0, 0}`)
---
---@field x             number          The x-coordinate of the center of the arena. May be inaccurate if the arena is transformed. Use [`Arena:getCenter()`](lua://Arena.getCenter) where possible.
---@field y             number          The y-coordinate of the center of the arena. May be inaccurate if the arena is transformed. Use [`Arena:getCenter()`](lua://Arena.getCenter) where possible.
---
---@field left          number          Leftmost horizontal position of the arena. May be inaccurate if the arena is transformed. Use [`Arena:getLeft()`](lua://Arena.getLeft) where possible.
---@field right         number          Rightost horizontal position of the arena. May be inaccurate if the arena is transformed. Use [`Arena:getRight()`](lua://Arena.getRight) where possible.
---@field top           number          Topmost vertical position of the arena. May be inaccurate if the arena is transformed. Use [`Arena:getLeft()`](lua://Arena.getTop) where possible.
---@field bottom        number          Bottommost vertical position of the arena. May be inaccurate if the arena is transformed. Use [`Arena:getBottom()`](lua://Arena.getBottom) where possible.
---
---@field line_width    integer         The thickness of the arena border in pixels, must call [`Arena:setShape()`](lua://Arena.setShape) or [`Arena:setSize()`](lua://Arena.setSize) after changing this to make the change take effect. (Defaults to `4`)
---
---@field sprite        ArenaSprite
---
---@field mask          ArenaMask       A mask for the arena - Any object parented to this will only render inside of the arena's bounds. 
---
---@field shape         table<[number, number]>     The shape of the arena, represented as a table of `{x, y}` coordinates that form a polygon. 
---
---@overload fun(x?:number, y?:number, shape?:table<[number, number]>) : Arena
local Arena, super = Class(Object)

---@param x?        number                  The x-coordinate of the center of the arena.
---@param y?        number                  The y-coordinate of the center of the arena.
---@param shape?    table<[number, number]> The shape of the arena, represented as a table of `{x, y}` coordinates that form a polygon.
function Arena:init(x, y, shape)
    super.init(self, x, y)

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

--- Sets the arena to a rectangle with dimensions `width` by `height`. \
--- *If [`line_width`](lua://Arena.line_width) has been changed, this function makes the arena to reflect that change.*
---@param width     number
---@param height    number
function Arena:setSize(width, height)
    self:setShape{{0, 0}, {width, 0}, {width, height}, {0, height}}
end

--- Sets the arena to the polygon `shape`. \
--- *If [`line_width`](lua://Arena.line_width) has been changed, this function makes the arena to reflect that change.*
---@param shape table<[number, number]>     A table of `{x, y}` coordinates that form a polygon.
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

    self.clockwise = Utils.isPolygonClockwise(self.shape)

    self.area_collider = PolygonCollider(self, Utils.copy(shape, true))

    self.collider.colliders = {}
    for _,v in ipairs(Utils.getPolygonEdges(self.shape)) do
        table.insert(self.collider.colliders, LineCollider(self, v[1][1], v[1][2], v[2][1], v[2][2]))
    end
end

---@param r number
---@param g number
---@param b number
---@param a number?
function Arena:setBackgroundColor(r, g, b, a)
    self.bg_color = {r, g, b, a or 1}
end

---@return table
function Arena:getBackgroundColor()
    return self.bg_color
end

---@return number x
---@return number y
function Arena:getCenter()
    return self:getRelativePos(self.width/2, self.height/2)
end

---@return number x
---@return number y
function Arena:getTopLeft() return self:getRelativePos(0, 0) end
---@return number x
---@return number y
function Arena:getTopRight() return self:getRelativePos(self.width, 0) end
---@return number x
---@return number y
function Arena:getBottomLeft() return self:getRelativePos(0, self.height) end
---@return number x
---@return number y
function Arena:getBottomRight() return self:getRelativePos(self.width, self.height) end

---@return number x
function Arena:getLeft() local x, y = self:getTopLeft(); return x end
---@return number x
function Arena:getRight() local x, y = self:getBottomRight(); return x end
---@return number y
function Arena:getTop() local x, y = self:getTopLeft(); return y end
---@return number y
function Arena:getBottom() local x, y = self:getBottomRight(); return y end

---@param parent Object
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
            afterimg:fadeOutSpeedAndRemove()
            afterimg.background = false
            afterimg.alpha = 0.6 - (0.5 * progress)
            afterimg.rotation = (math.pi) * (1 - progress)
            parent:addChild(afterimg)
            afterimg:setLayer(self.layer + (1 - progress))
        end
    end, function()
        self.sprite:setScale(1)
        self.sprite.alpha = 1
    end)
end

---@param parent Object
function Arena:onRemove(parent)
    local orig_sprite = ArenaSprite(self, self:getCenter())
    orig_sprite:setOrigin(0.5, 0.5)
    parent:addChild(orig_sprite)
    orig_sprite:setLayer(self.layer)
    orig_sprite.rotation = self.rotation
    local rotation = self.rotation

    local afterimage_timer = 0
    local afterimage_count = 0
    Game.battle.timer:during(15/30, function()
        afterimage_timer = Utils.approach(afterimage_timer, 15, DTMULT)

        local real_progress = 1 - (afterimage_timer / 15)

        orig_sprite:setScale(real_progress, real_progress)
        orig_sprite.alpha = 0.5 + (0.5 * real_progress)
        orig_sprite.rotation = rotation + ((math.pi) * (1 - real_progress))

        while afterimage_count < math.floor(afterimage_timer) do
            afterimage_count = afterimage_count + 1

            local progress = 1 - (afterimage_count / 15)

            local afterimg = ArenaSprite(self, orig_sprite.x, orig_sprite.y)
            afterimg:setOrigin(0.5, 0.5)
            afterimg:setScale(progress, progress)
            afterimg:fadeOutSpeedAndRemove()
            afterimg.background = false
            afterimg.alpha = 0.6 - (0.5 * progress)
            afterimg.rotation = rotation + ((math.pi) * (1 - progress))
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

    super.update(self)

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
    super.draw(self)

    if DEBUG_RENDER and self.collider then
        self.collider:draw(0, 0, 1)
    end
end

return Arena