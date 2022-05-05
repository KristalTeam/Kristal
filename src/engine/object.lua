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

function Object._clearCache()
    Object.CACHE_TRANSFORMS = false
    Object.CACHE_ATTEMPTS = 0
    Object.CACHED = {}
    Object.CACHED_FULL = {}
end

function Object.uncache(obj)
    if Object.CACHE_TRANSFORMS then
        Object.CACHED[obj] = nil
        Object.uncacheFull(obj)
    end
end

function Object.uncacheFull(obj)
    if Object.CACHE_TRANSFORMS then
        Object.CACHED_FULL[obj] = nil
        for _,child in ipairs(obj.children) do
            Object.uncacheFull(child)
        end
    end
end

function Object:init(x, y, width, height)
    -- Intitialize this object's position (optional args)
    self.x = x or 0
    self.y = y or 0

    -- Initialize this object's size
    self.width = width or 0
    self.height = height or 0

    self:resetPhysics()
    self:resetGraphicsTransform()

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
    self.origin_exact = false
    -- Origin of the object's scaling
    self.scale_origin_x = nil
    self.scale_origin_y = nil
    self.scale_origin_exact = false
    -- Origin of the object's rotation
    self.rotation_origin_x = nil
    self.rotation_origin_y = nil
    self.rotation_origin_exact = nil

    -- How much this object is moved by the camera (1 = normal, 0 = none)
    self.parallax_x = nil
    self.parallax_y = nil
    -- Parallax origin
    self.parallax_origin_x = nil
    self.parallax_origin_y = nil

    -- Camera associated with this object (updates and transforms automatically)
    self.camera = nil

    -- Object scissor, no scissor when nil
    self.cutout_left = nil
    self.cutout_top = nil
    self.cutout_right = nil
    self.cutout_bottom = nil

    -- Post-processing effects
    self.draw_fx = {}

    -- Multiplier for DT for this object's update and draw
    self.timescale = 1

    -- This object's sorting, higher number = renders last (above siblings)
    self.layer = 0

    -- Collision hitbox
    self.collider = nil
    -- Whether this object can be collided with
    self.collidable = true

    -- Whether this object updates
    self.active = true

    -- Whether this object draws
    self.visible = true

    -- If set, children under this layer will be drawn below this object
    self.draw_children_below = nil
    -- If set, children at or above this layer will be drawn above this object
    self.draw_children_above = nil

    -- Ignores child drawing
    self._dont_draw_children = false

    -- Triggers list sort / child removal
    self.update_child_list = false
    self.children_to_remove = {}

    self.parent = nil
    self.children = {}
end

--[[ Common overrides ]]--

function Object:update()
    self:updatePhysicsTransform()
    self:updateGraphicsTransform()

    self:updateChildren()

    if self.camera then
        self.camera:update()
    end
end

function Object:draw()
    self:drawChildren()
end

function Object:onAdd(parent) end
function Object:onRemove(parent) end

function Object:onAddToStage(stage) end
function Object:onRemoveFromStage(stage) end

--[[ Common functions ]]--

function Object:resetPhysics()
    self.physics = {
        -- The speed this object moves (pixels per frame, at 30 fps)
        speed_x = 0,
        speed_y = 0,
        -- The speed this object moves, in the angle of its direction (pixels per frame, at 30 fps)
        speed = 0,
        direction = 0, -- right

        -- The amount this object should slow down (also per frame at 30 fps)
        friction = 0,
        -- The amount this object should accelerate in the gravity direction (also per frame at 30 fps)
        gravity = 0,
        gravity_direction = math.pi/2, -- down

        -- The amount this object's direction rotates (per frame at 30 fps)
        spin = 0,

        -- Whether direction should be based on rotation instead
        match_rotation = false,

        -- Movement target for Object:slideTo
        slide_target = nil,
    }
end

function Object:resetGraphicsTransform()
    self.graphics = {
        -- How fast this object fades its alpha (per frame at 30 fps)
        fade = 0,
        -- Target alpha to fade to
        fade_to = 0,
        -- Function called after this object reaches target fade
        fade_callback = nil,

        -- Speed at which this object gets scaled (per frame at 30 fps)
        grow_x = 0,
        grow_y = 0,
        -- Speed at which this object gets scaled in each direction (per frame at 30 fps)
        grow = 0,
        -- Whether this object should be removed at scale <= 0
        remove_shrunk = false,

        -- Amount this object rotates (per frame at 30 fps)
        spin = 0
    }
end

function Object:move(x, y, speed)
    self.x = self.x + (x or 0) * (speed or 1)
    self.y = self.y + (y or 0) * (speed or 1)
end

function Object:fadeTo(target, speed, callback)
    self.graphics.fade = speed or 0.04
    self.graphics.fade_to = target or 0
    self.graphics.fade_callback = callback
end

function Object:fadeOutAndRemove(speed)
    self.graphics.fade = speed or 0.04
    self.graphics.fade_to = 0
    self.graphics.fade_callback = self.remove
end

function Object:slideTo(x, y, time, ease, after)
    -- Ability to specify World marker for convenience in cutscenes
    if type(x) == "string" then
        after = ease
        ease = time
        time = y
        x, y = Game.world.map:getMarker(x)
    end
    if self.x ~= x or self.y ~= y then
        self.physics.slide_target = {x = x, y = y, time = time, timer = 0, start_x = self.x, start_y = self.y, ease = ease or "linear", after = after}
        return true
    else
        if after then
            after()
        end
        return false
    end
end

function Object:slideToSpeed(x, y, speed, after)
    -- Ability to specify World marker for convenience in cutscenes
    if type(x) == "string" then
        after = speed
        speed = y
        x, y = Game.world.map:getMarker(x)
    end
    if self.x ~= x or self.y ~= y then
        self.physics.slide_target = {x = x, y = y, speed = speed, after = after}
        return true
    else
        if after then
            after()
        end
        return false
    end
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

function Object:setSize(width, height) self.width = width or 0; self.height = height or width or 0 end
function Object:getSize() return self.width, self.height end

function Object:getScaledWidth() return self.width * self.scale_x end
function Object:getScaledHeight() return self.height * self.scale_y end
function Object:getScaledSize() return self:getScaledWidth(), self:getScaledHeight() end

function Object:setScale(x, y) self.scale_x = x or 1; self.scale_y = y or x or 1 end
function Object:getScale() return self.scale_x, self.scale_y end

function Object:setColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = unpack(r)
    end
    self.color = {r, g, b};
    self.alpha = a or self.alpha
end
function Object:getColor() return self.color[1], self.color[2], self.color[3], self.alpha end

function Object:setOrigin(x, y) self.origin_x = x or 0; self.origin_y = y or x or 0; self.origin_exact = false end
function Object:getOrigin()
    if not self.origin_exact then
        return self.origin_x, self.origin_y
    else
        return self.origin_x / self.width, self.origin_y / self.height
    end
end
function Object:setOriginExact(x, y) self.origin_x = x or 0; self.origin_y = y or x or 0; self.origin_exact = true end
function Object:getOriginExact()
    if self.origin_exact then
        return self.origin_x, self.origin_y
    else
        return self.origin_x * self.width, self.origin_y * self.height
    end
end

function Object:setScaleOrigin(x, y) self.scale_origin_x = x or 0; self.scale_origin_y = y or x or 0; self.scale_origin_exact = false end
function Object:getScaleOrigin()
    if not self.scale_origin_exact then
        local ox, oy = self:getOrigin()
        return self.scale_origin_x or ox, self.scale_origin_y or oy
    else
        local ox, oy = self:getOriginExact()
        return (self.scale_origin_x or ox) / self.width, (self.scale_origin_y or oy) / self.height
    end
end
function Object:setScaleOriginExact(x, y) self.scale_origin_x = x or 0; self.scale_origin_y = y or x or 0; self.scale_origin_exact = true end
function Object:getScaleOriginExact()
    if self.scale_origin_exact then
        local ox, oy = self:getOriginExact()
        return self.scale_origin_x or ox, self.scale_origin_y or oy
    else
        local ox, oy = self:getOrigin()
        return (self.scale_origin_x or ox) * self.width, (self.scale_origin_y or oy) * self.height
    end
end

function Object:setRotationOrigin(x, y) self.rotation_origin_x = x or 0; self.rotation_origin_y = y or x or 0; self.rotation_origin_exact = false end
function Object:getRotationOrigin()
    if not self.rotation_origin_exact then
        local ox, oy = self:getOrigin()
        return self.rotation_origin_x or ox, self.rotation_origin_y or oy
    else
        local ox, oy = self:getOriginExact()
        return (self.rotation_origin_x or ox) / self.width, (self.rotation_origin_y or oy) / self.height
    end
end
function Object:setRotationOriginExact(x, y) self.rotation_origin_x = x or 0; self.rotation_origin_y = y or x or 0; self.rotation_origin_exact = true end
function Object:getRotationOriginExact()
    if self.rotation_origin_exact then
        local ox, oy = self:getOriginExact()
        return self.rotation_origin_x or ox, self.rotation_origin_y or oy
    else
        local ox, oy = self:getOrigin()
        return (self.rotation_origin_x or ox) * self.width, (self.rotation_origin_y or oy) * self.height
    end
end

function Object:setParallax(x, y) self.parallax_x = x or 1; self.parallax_y = y or 1 end
function Object:getParallax() return self.parallax_x or 1, self.parallax_y or 1 end

function Object:setParallaxOrigin(x, y) self.parallax_origin_x = x; self.parallax_origin_y = y end
function Object:getParallaxOrigin() return self.parallax_origin_x, self.parallax_origin_y end

function Object:getLayer() return self.layer end
function Object:setLayer(layer)
    if self.layer ~= layer then
        self.layer = layer
        if self.parent then
            self.parent.update_child_list = true
        end
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

function Object:setSpeed(x, y)
    if x and y then
        self.physics.speed = 0
        self.physics.speed_x = x
        self.physics.speed_y = y
    else
        self.physics.speed = x or 0
        self.physics.speed_x = 0
        self.physics.speed_y = 0
    end
end
function Object:getSpeed()
    if self.physics then
        if self.physics.speed ~= 0 then
            return self.physics.speed
        else
            return self.physics.speed_x, self.physics.speed_y
        end
    else
        return 0
    end
end

function Object:setDirection(dir)
    if self.physics.match_rotation then
        self.rotation = dir
    else
        self.physics.direction = dir
    end
end
function Object:getDirection()
    return self.physics.match_rotation and self.rotation or self.physics.direction
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
    elseif other == self then
        return x or 0, y or 0
    else
        local sx, sy = self:getFullTransform():transformPoint(x or 0, y or 0)
        return other:getFullTransform():inverseTransformPoint(sx, sy)
    end
end

-- Please rename this soon
function Object:getRelativePosFor(other)
    if other == self then
        return 0, 0
    else
        return self.parent:getRelativePos(self.x, self.y, other)
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

function Object:addFX(fx, id)
    table.insert(self.draw_fx, fx)
    fx.parent = self
    if id then
        fx.id = id
    end
    return fx
end

function Object:getFX(id)
    if isClass(id) then
        for _,fx in ipairs(self.draw_fx) do
            if fx:includes(id) then
                return fx
            end
        end
    else
        for _,fx in ipairs(self.draw_fx) do
            if fx.id == id then
                return fx
            end
        end
    end
end

function Object:removeFX(id)
    for i,fx in ipairs(self.draw_fx) do
        if fx == id or fx.id == id then
            if fx.parent == self then
                fx.parent = nil
            end
            return table.remove(self.draw_fx, i)
        end
    end
end

function Object:applyTransformTo(transform)
    Utils.pushPerformance("Object#applyTransformTo")
    transform:translate(self.x, self.y)
    if self.parent and self.parent.camera and (self.parallax_x or self.parallax_y or self.parallax_origin_x or self.parallax_origin_y) then
        transform:translate(self.parent.camera:getParallax(self.parallax_x or 1, self.parallax_y or 1, self.parallax_origin_x, self.parallax_origin_y))
    end
    if self.flip_x or self.flip_y then
        transform:translate(self.width/2, self.height/2)
        transform:scale(self.flip_x and -1 or 1, self.flip_y and -1 or 1)
        transform:translate(-self.width/2, -self.height/2)
    end
    local ox, oy = self:getOriginExact()
    transform:translate(-ox, -oy)
    if self.rotation ~= 0 then
        local ox, oy = self:getRotationOriginExact()
        transform:translate(ox, oy)
        transform:rotate(self.rotation)
        transform:translate(-ox, -oy)
    end
    if self.scale_x ~= 1 or self.scale_y ~= 1 then
        local ox, oy = self:getScaleOriginExact()
        transform:translate(ox, oy)
        transform:scale(self.scale_x, self.scale_y)
        transform:translate(-ox, -oy)
    end
    if self.camera then
        self.camera:applyTo(transform)
    end
    Utils.popPerformance()
end

function Object:createTransform()
    Utils.pushPerformance("Object#createTransform")
    local transform = love.math.newTransform()
    self:applyTransformTo(transform)
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

function Object:explode(x, y, dont_remove)
    if self.parent then
        local rx, ry = self:getRelativePos(self.width/2 + (x or 0), self.height/2 + (y or 0))
        local e = Explosion(rx, ry)
        e.layer = self.layer + 0.001
        self.parent:addChild(e)
        if not dont_remove then
            self:remove()
        end
        return e
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
    return child
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
    return child
end

function Object:setParent(parent)
    if self.parent ~= parent then
        local old_parent = self.parent
        if parent then
            parent:addChild(self)
        end
        if old_parent then
            old_parent:removeChild(self)
        end
    end
end

function Object:isFullyActive()
    if self.stage and self.parent == self.stage then
        return self.active
    elseif self.stage and self.parent then
        return self.active and self.parent:isFullyActive()
    end
    return false
end

function Object:isFullyVisible()
    if self.stage and self.parent == self.stage then
        return self.visible
    elseif self.stage and self.parent then
        return self.visible and self.parent:isFullyVisible()
    end
    return false
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

function Object:updateChildren()
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    for _,v in ipairs(self.draw_fx) do
        v:update()
    end
    for _,v in ipairs(self.children) do
        if v.active and v.parent == self then
            v:fullUpdate()
        end
    end
end

function Object:fullUpdate()
    local used_timescale, last_dt, last_dt_mult, last_speed = false, DT, DTMULT, CURRENT_SPEED_MULT
    if self.timescale ~= 1 then
        used_timescale = true
        DT = DT * self.timescale
        DTMULT = DTMULT * self.timescale
        CURRENT_SPEED_MULT = CURRENT_SPEED_MULT * self.timescale
    end
    self:update()
    if used_timescale then
        DT = last_dt
        DTMULT = last_dt_mult
        CURRENT_SPEED_MULT = last_speed
    end
end

function Object:preDraw()
    local transform = love.graphics.getTransformRef()
    self:applyTransformTo(transform)
    love.graphics.replaceTransform(transform)

    love.graphics.setColor(self:getDrawColor())
    Draw.pushScissor()
    self:applyScissor()
end

function Object:postDraw()
    Draw.popScissor()
end

function Object:drawChildren(min_layer, max_layer)
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    if self._dont_draw_children then
        return
    end
    if not min_layer and not max_layer then
        min_layer = self.draw_children_below
        max_layer = self.draw_children_above
    end
    local oldr, oldg, oldb, olda = love.graphics.getColor()
    for _,v in ipairs(self.children) do
        if v.visible and (not min_layer or v.layer >= min_layer) and (not max_layer or v.layer < max_layer) then
            v:fullDraw()
        end
    end
    love.graphics.setColor(oldr, oldg, oldb, olda)
end

function Object:fullDraw(no_children)
    local used_timescale, last_dt, last_dt_mult, last_speed = false, DT, DTMULT, CURRENT_SPEED_MULT
    if self.timescale ~= 1 then
        used_timescale = true
        DT = DT * self.timescale
        DTMULT = DTMULT * self.timescale
        CURRENT_SPEED_MULT = CURRENT_SPEED_MULT * self.timescale
    end
    local processing_fx, canvas = self:shouldProcessDrawFX(), nil
    if processing_fx then
        Draw.pushCanvasLocks()
        canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT, {keep_transform = true})
    end
    local last_draw_children = self._dont_draw_children
    if no_children then
        self._dont_draw_children = true
    end
    love.graphics.push()
    self:preDraw()
    if self.draw_children_below then
        self:drawChildren(nil, self.draw_children_below)
    end
    self:draw()
    if self.draw_children_above then
        self:drawChildren(self.draw_children_above)
    end
    self:postDraw()
    love.graphics.pop()
    self._dont_draw_children = last_draw_children
    if processing_fx then
        Draw.popCanvas(true)
        local final_canvas = self:processDrawFX(canvas)
        love.graphics.push()
        love.graphics.origin()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(final_canvas)
        love.graphics.pop()
        Draw.popCanvasLocks()
    end
    if used_timescale then
        DT = last_dt
        DTMULT = last_dt_mult
        CURRENT_SPEED_MULT = last_speed
    end
end

function Object:shouldProcessDrawFX()
    for _,fx in ipairs(self.draw_fx) do
        if fx:isActive(self) then
            return true
        end
    end
end

function Object:processDrawFX(canvas)
    table.sort(self.draw_fx, FXBase.SORTER)

    for _,fx in ipairs(self.draw_fx) do
        if fx:isActive(self) then
            local next_canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
            love.graphics.setColor(1, 1, 1)
            fx:draw(canvas, self)
            Draw.popCanvas(true)
            Draw.unlockCanvas(canvas)
            canvas = next_canvas
        end
    end

    return canvas
end

function Object:updatePhysicsTransform()
    local physics = self.physics

    if not physics then return end

    local direction = (physics.match_rotation and self.rotation or physics.direction) or physics.gravity_direction or 0

    if physics.gravity and physics.gravity ~= 0 then
        if physics.speed and physics.speed ~= 0 then
            local speed_x, speed_y = math.cos(direction) * physics.speed, math.sin(direction) * physics.speed
            local new_speed_x = speed_x + math.cos(physics.gravity_direction) * (physics.gravity * DTMULT)
            local new_speed_y = speed_y + math.sin(physics.gravity_direction) * (physics.gravity * DTMULT)
            if physics.match_rotation then
                self.rotation = math.atan2(new_speed_y, new_speed_x)
            else
                physics.direction = math.atan2(new_speed_y, new_speed_x)
            end
            physics.speed = math.sqrt(new_speed_x*new_speed_x + new_speed_y*new_speed_y)
        else
            physics.speed_x = physics.speed_x or 0
            physics.speed_y = physics.speed_y or 0
            physics.speed_x = physics.speed_x + math.cos(physics.gravity_direction) * (physics.gravity * DTMULT)
            physics.speed_y = physics.speed_y + math.sin(physics.gravity_direction) * (physics.gravity * DTMULT)
        end
    end

    if physics.spin and physics.spin ~= 0 then
        if physics.match_rotation then
            self.rotation = self.rotation + physics.spin * DTMULT
        else
            physics.direction = physics.direction + physics.spin * DTMULT
        end
    end

    if physics.speed and physics.speed ~= 0 then
        physics.speed = Utils.approach(physics.speed, 0, (physics.friction or 0) * DTMULT)
        self:move(math.cos(direction), math.sin(direction), physics.speed * DTMULT)
    end

    if (physics.speed_x and physics.speed_x ~= 0) or (physics.speed_y and physics.speed_y ~= 0) then
        physics.speed_x = Utils.approach(physics.speed_x or 0, 0, (physics.friction or 0) * DTMULT)
        physics.speed_y = Utils.approach(physics.speed_y or 0, 0, (physics.friction or 0) * DTMULT)
        self:move(physics.speed_x, physics.speed_y, DTMULT)
    end

    if physics.slide_target then
        if physics.slide_target.speed then
            local angle = Utils.angle(self.x, self.y, physics.slide_target.x, physics.slide_target.y)
            self.x = Utils.approach(self.x, physics.slide_target.x, physics.slide_target.speed * math.abs(math.cos(angle)) * DTMULT)
            self.y = Utils.approach(self.y, physics.slide_target.y, physics.slide_target.speed * math.abs(math.sin(angle)) * DTMULT)
        elseif physics.slide_target.time then
            physics.slide_target.timer = Utils.approach(physics.slide_target.timer, physics.slide_target.time, DT)

            self.x = Utils.ease(physics.slide_target.start_x, physics.slide_target.x, (physics.slide_target.timer / physics.slide_target.time), physics.slide_target.ease)
            self.y = Utils.ease(physics.slide_target.start_y, physics.slide_target.y, (physics.slide_target.timer / physics.slide_target.time), physics.slide_target.ease)
        end
        if self.x == physics.slide_target.x and self.y == physics.slide_target.y then
            local after = physics.slide_target.after
            physics.slide_target = nil
            if after then after() end
        end
    end
end

function Object:updateGraphicsTransform()
    local graphics = self.graphics

    if not graphics then return end

    if graphics.fade and graphics.fade ~= 0 and self.alpha ~= graphics.fade_to then
        self.alpha = Utils.approach(self.alpha, graphics.fade_to, graphics.fade * DTMULT)
        if graphics.fade_callback and self.alpha == graphics.fade_to then
            graphics.fade_callback(self)
        end
    end

    if (graphics.grow and graphics.grow ~= 0)
    or (graphics.grow_x and graphics.grow_x ~= 0)
    or (graphics.grow_y and graphics.grow_y ~= 0) then
        self.scale_x = self.scale_x + ((graphics.grow_x or 0) + (graphics.grow or 0)) * DTMULT
        self.scale_y = self.scale_y + ((graphics.grow_y or 0) + (graphics.grow or 0)) * DTMULT
    end
    if graphics.remove_shrunk and (self.scale_x <= 0 or self.scale_y <= 0) then
        self.scale_x = 0
        self.scale_y = 0
        self:remove()
    end

    if graphics.spin and graphics.spin ~= 0 then
        self.rotation = self.rotation + graphics.spin * DTMULT
    end
end

return Object