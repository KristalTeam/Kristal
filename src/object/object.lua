local Object = Class()

Object.LAYER_SORT = function(a, b) return a.layer < b.layer end

Object.CACHE_TRANSFORMS = false
Object.CACHE_ATTEMPTS = 0
Object.CACHED = {}
Object.CACHED_FULL = {}

function Object.startCache()
    Object.CACHE_ATTEMPTS = Object.CACHE_ATTEMPTS + 1
    if Object.CACHE_ATTEMPTS == 1 then
        Object.CACHED = {}
        Object.CACHED_FULL = {}
        Object.CACHE_TRANSFORMS = true
    end
end

function Object.endCache()
    Object.CACHE_ATTEMPTS = Object.CACHE_ATTEMPTS - 1
    if Object.CACHE_ATTEMPTS == 0 then
        Object.CACHED = {}
        Object.CACHED_FULL = {}
        Object.CACHE_TRANSFORMS = false
    end
end

function Object.uncache(obj)
    Object.CACHED[obj] = nil
    Object.uncacheFull(obj)
end

function Object.uncacheFull(obj)
    Object.CACHED_FULL[obj] = nil
    for _,child in ipairs(obj.children) do
        Object.uncacheFull(child)
    end
end

function Object:init(x, y, width, height)
    -- Intitialize this object's position (optional args)
    self.x = x or 0
    self.y = y or 0

    -- Initialize this object's size
    self.width = width or 0
    self.height = height or 0

    -- The speed this object moves (pixels per frame, at 30 fps)
    self.speed_x = 0
    self.speed_y = 0
    -- The amount this object should slow down (also per frame at 30 fps)
    self.friction = 0

    -- How fast this object fades its alpha (per frame at 30 fps)
    self.fade_speed = 0
    -- Target alpha to fade to
    self.target_fade = 0
    -- Function called after this object reaches target fade
    self.fade_callback = nil

    -- Various draw properties
    self.color = {1, 1, 1}
    self.alpha = 1
    self.scale_x = 1
    self.scale_y = 1
    self.rotation = 0
    self.flip_x = false
    self.flip_y = false
    
    -- Whether this object's color will be multiplied by its parent's color
    self.inherit_color = false

    -- Origin of the object's position
    self.origin_x = 0
    self.origin_y = 0
    -- Origin of the object's scaling
    self.scale_origin_x = nil
    self.scale_origin_y = nil
    -- Origin of the object's rotation
    self.rotate_origin_x = nil
    self.rotate_origin_y = nil

    -- How much this object is moved by the camera (1 = normal, 0 = none)
    self.parallax_x = nil
    self.parallax_y = nil

    -- Object scissor, no scissor when nil
    self.cutout_left = nil
    self.cutout_top = nil
    self.cutout_right = nil
    self.cutout_bottom = nil

    -- This object's sorting, higher number = renders last (above siblings)
    self.layer = 0

    -- Collision hitbox
    self.collider = nil
    -- Whether this object can be collided with
    self.collidable = true

    -- Triggers list sort / child removal
    self.update_child_list = false
    self.children_to_remove = {}

    -- Whether this object updates
    self.active = true

    -- Whether this object draws
    self.visible = true

    self.parent = nil
    self.children = {}
end

--[[ Common overrides ]]--

function Object:update(dt)
    if self.speed_x ~= 0 or self.speed_y ~= 0 then
        self.speed_x = Utils.approach(self.speed_x, 0, self.friction * DTMULT)
        self.speed_y = Utils.approach(self.speed_y, 0, self.friction * DTMULT)
        self:move(self.speed_x, self.speed_y, DTMULT)
    end

    if self.fade_speed ~= 0 and self.alpha ~= self.target_fade then
        self.alpha = Utils.approach(self.alpha, self.target_fade, self.fade_speed * DTMULT)
        if self.fade_callback and self.alpha == self.target_fade then
            self:fade_callback()
        end
    end

    self:updateChildren(dt)
end

function Object:draw()
    self:drawChildren()
end

function Object:onAdd(parent) end
function Object:onRemove(parent) end

--[[ Common functions ]]--

function Object:move(x, y, speed)
    self.x = self.x + (x or 0) * (speed or 1)
    self.y = self.y + (y or 0) * (speed or 1)
end

function Object:fadeTo(target, speed, callback)
    self.target_fade = target or 0
    self.fade_speed = speed or 0.04
    self.fade_callback = callback
end

function Object:fadeOutAndRemove(speed)
    self.target_fade = 0
    self.fade_speed = speed or 0.04
    self.fade_callback = self.remove
end

function Object:collidesWith(other)
    if other and self.collidable and self.collider then
        if isClass(other) and other:includes(Object) then
            return other.collidable and other.collider and self.collider:collidesWith(other.collider) or false
        else
            return self.collider:collidesWith(other)
        end
    end
    return false
end

function Object:setPosition(x, y) self.x = x or 0; self.y = y or 0 end
function Object:getPosition() return self.x, self.y end

function Object:setSpeed(x, y) self.speed_x = x or 0; self.speed_y = y or x or 0 end
function Object:getSpeed() return self.speed_x, self.speed_y end

function Object:setSize(width, height) self.width = width or 0; self.height = height or width or 0 end
function Object:getSize() return self.width, self.height end

function Object:setScale(x, y) self.scale_x = x or 1; self.scale_y = y or x or 1 end
function Object:getScale() return self.scale_x, self.scale_y end

function Object:setColor(r, g, b, a) self.color = {r, g, b}; self.alpha = a or self.alpha end
function Object:getColor() return self.color[1], self.color[2], self.color[3], self.alpha end

function Object:setOrigin(x, y) self.origin_x = x or 0; self.origin_y = y or x or 0 end
function Object:getOrigin() return self.origin_x, self.origin_y end

function Object:setScaleOrigin(x, y) self.scale_origin_x = x; self.scale_origin_y = y or x end
function Object:getScaleOrigin() return self.scale_origin_x or self.origin_x, self.scale_origin_y or self.origin_y end

function Object:setRotateOrigin(x, y) self.rotate_origin_x = x; self.rotate_origin_y = y or x end
function Object:getRotateOrigin() return self.rotate_origin_x or self.origin_x, self.rotate_origin_y or self.origin_y end

function Object:getLayer() return self.layer end
function Object:setLayer(layer)
    self.layer = layer
    if self.parent then
        self.parent.child_layer_changed = true
    end
end

function Object:setCutout(left, top, right, bottom)
    self.cutout_left = left
    self.cutout_top = top
    self.cutout_right = right
    self.cutout_bottom = bottom
end
function Object:getCutout()
    return self.cutout_left, self.cutout_top, self.cutout_right, self.cutout_bottom
end

function Object:getHitbox()
    if self.collider and self.collider:includes(Hitbox) then
        return self.collider.x, self.collider.y, self.collider.width, self.collider.height
    end
end
function Object:setHitbox(x, y, w, h)
    self.collider = Hitbox(self, x, y, w, h)
end

function Object:shiftOrigin(ox, oy)
    local tx, ty = self:getRelativePos((ox or 0) * self.width, (oy or ox or 0) * self.height)
    self:setOrigin(ox, oy)
    self:setPosition(tx, ty)
end

function Object:setScreenPos(x, y)
    if self.parent then
        self:setPosition(self.parent:getFullTransform():inverseTransformPoint(x or 0, y or 0))
    else
        self:setPosition(x, y)
    end
end
function Object:getScreenPos()
    if self.parent then
        return self.parent:getFullTransform():transformPoint(self.x, self.y)
    else
        return self.x, self.y
    end
end

function Object:localToScreenPos(x, y)
    return self:getFullTransform():transformPoint(x or 0, y or 0)
end

function Object:screenToLocalPos(x, y)
    return self:getFullTransform():inverseTransformPoint(x or 0, y or 0)
end

function Object:setRelativePos(x, y, other)
    -- ill be honest idk what this does it just feels weird to not have a setter
    other = other or self.parent
    local sx, sy = other:getFullTransform():inverseTransformPoint(x, y)
    local cx, cy = self:getFullTransform():transformPoint(sx, sy)
    self:setPosition(self:getTransform():inverseTransformPoint(cx, cy))
end
function Object:getRelativePos(x, y, other)
    if not other or other == self.parent then
        return self:getTransform():transformPoint(x or 0, y or 0)
    else
        local sx, sy = self:getFullTransform():transformPoint(x or 0, y or 0)
        return other:getFullTransform():inverseTransformPoint(sx, sy)
    end
end

function Object:getStage()
    if self.parent and self.parent.parent then
        return self.parent:getStage()
    elseif self.parent then
        return self.parent
    end
end

function Object:getDrawColor()
    local r, g, b = unpack(self.color)
    if self.inherit_color and self.parent then
        local pr, pg, pb, pa = self.parent:getDrawColor()
        return r * pr, g * pg, b * pb, self.alpha * pa
    else
        return r, g, b, self.alpha
    end
end

function Object:applyScissor()
    local left, top, right, bottom = self:getCutout()
    if left or top or right or bottom then
        Draw.scissorPoints(left, top, right and (self.width - right), bottom and (self.height - bottom))
    end
end

function Object:createTransform()
    Utils.pushPerformance("Object#createTransform")
    local transform = love.math.newTransform()
    transform:translate(self.x, self.y)
    if (self.parallax_x or self.parallax_y) and self.parent and self.parent.camera then
        transform:translate(self.parent.camera:getParallax(self.parallax_x or 1, self.parallax_y or 1))
    end
    if self.flip_x or self.flip_y then
        transform:translate(self.width/2, self.height/2)
        transform:scale(self.flip_x and -1 or 1, self.flip_y and -1 or 1)
        transform:translate(-self.width/2, -self.height/2)
    end
    transform:translate(-self.width * self.origin_x, -self.height * self.origin_y)
    if self.scale_x ~= 1 or self.scale_y ~= 1 then
        transform:translate(self.width * (self.scale_origin_x or self.origin_x), self.height * (self.scale_origin_y or self.origin_y))
        transform:scale(self.scale_x, self.scale_y)
        transform:translate(self.width * -(self.scale_origin_x or self.origin_x), self.height * -(self.scale_origin_y or self.origin_y))
    end
    if self.rotation ~= 0 then
        transform:translate(self.width * (self.rotate_origin_x or self.origin_x), self.height * (self.rotate_origin_y or self.origin_y))
        transform:rotate(self.rotation)
        transform:translate(self.width * -(self.rotate_origin_x or self.origin_x), self.height * -(self.rotate_origin_y or self.origin_y))
    end
    Utils.popPerformance()
    return transform
end

function Object:getTransform()
    if Object.CACHE_TRANSFORMS then
        if not Object.CACHED[self] then
            Object.CACHED[self] = self:createTransform()
        end
        return Object.CACHED[self]
    else
        return self:createTransform()
    end
end

function Object:getFullTransform(i)
    i = i or 0
    if i <= 0 then
        if Object.CACHE_TRANSFORMS then
            if not Object.CACHED_FULL[self] then
                if not self.parent then
                    Object.CACHED_FULL[self] = self:getTransform()
                else
                    Object.CACHED_FULL[self] = self.parent:getFullTransform() * self:getTransform()
                end
            end
            return Object.CACHED_FULL[self]
        else
            if not self.parent then
                return self:getTransform()
            else
                return self.parent:getFullTransform():apply(self:getTransform())
            end
        end
    elseif self.parent then
        return self.parent:getFullTransform(i - 1)
    else
        return love.math.newTransform()
    end
end

function Object:getHierarchy()
    local tbl = {self}
    if self.parent then
        for _,v in ipairs(self.parent:getHierarchy()) do
            table.insert(tbl, v)
        end
    end
    return tbl
end

function Object:remove()
    if self.parent then
        self.parent:removeChild(self)
    end
end

function Object:explode(x, y)
    if self.parent then
        local rx, ry = self:getRelativePos(self.width/2 + (x or 0), self.height/2 + (y or 0))
        local e = Explosion(rx, ry)
        e.layer = self.layer + 0.001
        self.parent:addChild(e)
        self:remove()
    end
end

function Object:addChild(child)
    child.parent = self
    if self.stage and child.stage ~= self.stage then
        self.stage:addToStage(child)
    end
    table.insert(self.children, child)
    child:onAdd(self)
    self.update_child_list = true
end

function Object:removeChild(child)
    if child.parent == self then
        child.parent = nil
    end
    if self.stage and (not child.parent or not child.parent.stage) then
        self.stage:removeFromStage(child)
    end
    self.children_to_remove[child] = true
    self.update_child_list = true
end

--[[ Internal functions ]]--

function Object:sortChildren()
    table.sort(self.children, Object.LAYER_SORT)
end

function Object:updateChildList()
    for child,_ in pairs(self.children_to_remove) do
        for i,v in ipairs(self.children) do
            if v == child then
                child:onRemove(self)
                table.remove(self.children, i)
                break
            end
        end
    end
    self.children_to_remove = {}
    self:sortChildren()
end

function Object:updateChildren(dt)
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    for _,v in ipairs(self.children) do
        if v.active then
            v:update(dt)
        end
    end
end

function Object:preDraw()
    love.graphics.applyTransform(self:getTransform())
    love.graphics.setColor(self:getDrawColor())
    Draw.pushScissor()
    self:applyScissor()
end

function Object:postDraw()
    Draw.popScissor()
end

function Object:drawChildren()
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    local oldr, oldg, oldb, olda = love.graphics.getColor()
    for _,v in ipairs(self.children) do
        if v.visible then
            love.graphics.push()
            v:preDraw()
            v:draw()
            v:postDraw()
            love.graphics.pop()
        end
    end
    love.graphics.setColor(oldr, oldg, oldb, olda)
end

return Object