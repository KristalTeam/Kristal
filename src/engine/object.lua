--- The base class of all objects in Kristal. \
--- When added to the stage, an object will be updated and rendered.
---
---@class Object : Class
---@field x      number The horizontal position of the object, relative to its parent.
---@field y      number The vertical position of the object, relative to its parent.
---@field width  number The width of the object.
---@field height number The height of the object.
---
---@field init_x   number  The horizontal position of the object when it was created.
---@field init_y   number  The vertical position of the object when it was created.
---@field last_x   number  The horizontal position of the object in the previous frame.
---@field last_y   number  The vertical position of the object in the previous frame.
---
--- The color of the object in the form {R, G, B}. \
--- The values of R, G, and B are between 0 and 1.
---@field color table
---
---@field alpha    number  The alpha transparency of the object, between 0 (invisible) and 1 (fully visible).
---@field scale_x  number  The horizontal scale of the object.
---@field scale_y  number  The vertical scale of the object.
---@field rotation number  The rotation of the object, in radians. (`0` is right, positive is clockwise)
---@field flip_x   boolean Whether the object is flipped horizontally.
---@field flip_y   boolean Whether the object is flipped vertically.
---
---@field inherit_color boolean Whether the object's color will be multiplied by its parent's color.
---
---@field physics physics_table A table of data, defining ways the object should automatically move when updating.
---@field graphics graphics_table A table of data, defining ways the object's properties should automatically update.
---
--- The horizontal origin of the object. \
--- Origin is used to define the point that the object is scaled, rotated, and positioned from. \
--- This determines where the position (0, 0) is within the object. \
--- \
--- If `origin_exact` is false, the origin will be a ratio relative to the object's `width` and `height`, meaning an origin of 0.5, 0.5 will cause the object to be centered. \
--- If it is true, then the origin will be measured in exact pixels.
---@field origin_x number
--- The vertical origin of the object. \
--- Origin is used to define the point that the object is scaled, rotated, and positioned from. \
--- This determines where the position (0, 0) is within the object. \
--- \
--- If `origin_exact` is false, the origin will be a ratio relative to the object's `width` and `height`, meaning an origin of 0.5, 0.5 will cause the object to be centered. \
--- If it is true, then the origin will be measured in exact pixels.
---@field origin_y number
---@field origin_exact boolean Whether the object's origin is measured as a ratio of its `width` and `height`, or in exact pixels. (Defaults to false)
--- The horizontal scale origin of the object. \
--- Scale origin overrides the object's origin, and defines where the object will scale from.
---@field scale_origin_x number|nil
--- The vertical scale origin of the object. \
--- Scale origin overrides the object's origin, and defines where the object will scale from.
---@field scale_origin_y number|nil
---@field scale_origin_exact boolean Whether the object's scale origin is measured as a ratio of its `width` and `height`, or in exact pixels. (Defaults to false)
--- The horizontal rotation origin of the object. \
--- Rotation origin overrides the object's origin, and defines where the object will rotate from.
---@field rotation_origin_x number|nil
--- The vertical rotation origin of the object. \
--- Rotation origin overrides the object's origin, and defines where the object will rotate from.
---@field rotation_origin_y number|nil
---@field rotation_origin_exact boolean Whether the object's rotation origin is measured as a ratio of its `width` and `height`, or in exact pixels. (Defaults to false)
---
--- The horizontal camera origin of the object. (Defaults to 0.5) \
--- Camera origin defines what position on the object a camera attached to it should follow.
---@field camera_origin_x number
--- The vertical camera origin of the object. (Defaults to 0.5) \
--- Camera origin defines what position on the object a camera attached to it should follow.
---@field camera_origin_y number
---@field camera_origin_exact boolean Whether the object's camera origin is measured as a ratio of its `width` and `height`, or in exact pixels. (Defaults to false)
---
--- How much an object's position will be affected by the camera horizontally. \
--- A value of 1 means it fully moves with the camera (aka default behavior), and a value of 0 means it will not move at all when the camera moves. \
--- Parallax will only affect an object if its parent has a camera.
---@field parallax_x number|nil
--- How much an object's position will be affected by the camera vertically. \
--- A value of 1 means it fully moves with the camera (aka default behavior), and a value of 0 means it will not move at all when the camera moves. \
--- Parallax will only affect an object if its parent has a camera.
---@field parallax_y number|nil
---@field parallax_origin_x number The horizontal position on the object's parent that the object's parallax will orient around.
---@field parallax_origin_y number The vertical position on the object's parent that the object's parallax will orient around.
---@field camera Camera|nil A camera instance that will automatically move and scale the object and its children. Should be `nil` for most objects.
---
---@field cutout_left number|nil The amount of pixels to cut from the left of the object when drawing.
---@field cutout_top number|nil The amount of pixels to cut from the top of the object when drawing.
---@field cutout_right number|nil The amount of pixels to cut from the right of the object when drawing.
---@field cutout_bottom number|nil The amount of pixels to cut from the bottom of the object when drawing.
---
---@field draw_fx table A list of all DrawFX that are being applied to the object.
---
---@field debug_select boolean Whether the object can be selected by the Object Selection debug feature. (Defaults to true)
---@field debug_rect table|nil Defines the rectangle used for selecting the object with the Object Selection debug feature.
---
---@field timescale number A multiplier that determines the speed at which the object updates.
---
--- The layer of the object within its parent. \
--- Objects update and draw their children in order sorted by layer. Objects with a higher layer will update and draw later than objects with lower layers. \
--- \
--- All children of an object will draw at the same visual layer as the parent. In other words, a child cannot render above an object that is higher than its parent, even if its own layer is higher.
---@field layer number
---
---@field collider Collider|nil A Collider class used to check collision with other objects.
---@field collidable boolean Whether the object should be able to collide with other objects.
---
---@field active boolean Whether the object should update itself and its children.
---@field visible boolean Whether the object should draw itself and its children.
---
---@field draw_children_below number|nil If defined, children with a layer less than this value will be drawn underneath the object.
---@field draw_children_above number|nil If defined, children with a layer greater than this value will be drawn above the object.
---
---@field _dont_draw_children boolean *(Used internally)* Whether the object should draw its children or not.
---
---@field update_child_list boolean *(Used internally)* If true, the object will re-sort its children list.
---@field children_to_remove table *(Used internally)* A list of children for the object to remove next time it updates.
---
---@field parent Object|nil The object's parent.
---@field children table A list of all of this object's children.
---
---@overload fun(x?:number, y?:number, width?:number, height?:number) : Object
local Object = Class()

Object.LAYER_SORT = function(a, b) return a.layer < b.layer end

Object.CACHE_TRANSFORMS = false
Object.CACHE_ATTEMPTS = 0
Object.CACHED = {}
Object.CACHED_FULL = {}

--- Begin caching the transforms of all objects. \
--- This should be called before any collision checks, and ended with Object.endCache(). \
--- If an object is moved mid-cache, call Object.uncache() on it.
function Object.startCache()
    Object.CACHE_ATTEMPTS = Object.CACHE_ATTEMPTS + 1
    if Object.CACHE_ATTEMPTS == 1 then
        Object.CACHED = {}
        Object.CACHED_FULL = {}
        Object.CACHE_TRANSFORMS = true
    end
end

--- End caching the transforms of all objects (started with Object.startCache()).
function Object.endCache()
    Object.CACHE_ATTEMPTS = Object.CACHE_ATTEMPTS - 1
    if Object.CACHE_ATTEMPTS == 0 then
        Object.CACHED = {}
        Object.CACHED_FULL = {}
        Object.CACHE_TRANSFORMS = false
    end
end

--- *(Called internally)* Clears all cached transforms, and force-stops caching.
function Object._clearCache()
    Object.CACHE_TRANSFORMS = false
    Object.CACHE_ATTEMPTS = 0
    Object.CACHED = {}
    Object.CACHED_FULL = {}
end

--- Uncache an object's transform, if Object.startCache() is active. \
--- This recalculates the object's transform and all of its children, incase it was moved.
function Object.uncache(obj)
    if Object.CACHE_TRANSFORMS then
        Object.CACHED[obj] = nil
        Object.uncacheFull(obj)
    end
end

--- *(Called internally)* Uncaches an object's full transform, including all of its children.
function Object.uncacheFull(obj)
    if Object.CACHE_TRANSFORMS then
        Object.CACHED_FULL[obj] = nil
        for _, child in ipairs(obj.children) do
            Object.uncacheFull(child)
        end
    end
end

function Object:init(x, y, width, height)
    -- Intitialize this object's position (optional args)
    self.x = x or 0
    self.y = y or 0

    -- Save the initial position
    self.init_x = self.x
    self.init_y = self.y

    -- Save the previous position
    self.last_x = self.x
    self.last_x = self.y

    -- Initialize this object's size
    self.width = width or 0
    self.height = height or 0

    self:resetPhysics()
    self:resetGraphics()

    -- Various draw properties
    self.color = { 1, 1, 1 }
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

    -- Origin where the camera will attach to for this object
    self.camera_origin_x = 0.5
    self.camera_origin_y = 0.5
    self.camera_origin_exact = false

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

    -- Whether this object can be selected using debug selection
    self.debug_select = true
    -- The debug rectangle for this object (defaults to width and height)
    self.debug_rect = nil

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

--[[ Common overrides ]]
--

--- *(Override)* Called every frame by its parent if the object is active. \
--- By default, updates its physics and graphics tables, and its children.
function Object:update()
    self:updatePhysicsTransform()
    self:updateGraphicsTransform()

    self:updateChildren()

    if self.camera then
        self.camera:update()
    end
end

--- *(Override)* Called every frame by its parent during drawing if the object is visible. \
--- By default, draws its children.
function Object:draw()
    self:drawChildren()
end

--- *(Override)* Called when the object is added to a parent object via `parent:addChild(self)` or `self:setParent(parent)`.
---@param parent Object The parent that the object is being added to.
function Object:onAdd(parent) end

--- *(Override)* Called when the object is removed from its parent object via `self:remove()`, `parent:removeChild(self)`, or `self:setParent(new_parent)`.
---@param parent Object The parent that the object is being removed from.
function Object:onRemove(parent) end

--- *(Override)* Called when the object is first added to the Game stage, via `parent:addChild(self)` or `self:setParent(parent)`. \
--- Will not be called when changing to a new parent via `self:setParent(new_parent)` if the object had a parent prior.
---@param stage Object The Stage object that the object is being added to.
function Object:onAddToStage(stage) end

--- *(Override)* Called when the object is removed from the Game stage via `self:remove()` or `parent:removeChild(self)`. \
--- Will not be called when changing to a new parent via `self:setParent(new_parent)`.
---@param stage Object The Stage object that the object was a child of.
function Object:onRemoveFromStage(stage) end

--[[ Common functions ]]
--

---@class physics_table
---@field speed_x           number  The horizontal speed of the object, in pixels per frame at 30FPS.
---@field speed_y           number  The vertical speed of the object, in pixels per frame at 30FPS.
---@field speed             number  The speed the object will move in the angle of its direction, in pixels per frame at 30FPS.
---@field direction         number  The angle at which the object will move, in radians.
---@field friction          number  The amount the object's speed will slow down, per frame at 30FPS.
---@field gravity           number  The amount the object's speed will accelerate towards its gravity direction, per frame at 30FPS.
---@field gravity_direction number  The angle at which the object's gravity will accelerate towards, in radians.
---@field spin              number  The amount this object's direction will change, in radians per frame at 30FPS.
---@field match_rotation    boolean Whether the object's rotation should also define its direction. (Defaults to false)
---@field move_target?      table   A table containing data defined by `Object:slideTo()` or `Object:slideToSpeed()`.
---@field move_path?        table   A table containing data defined by `Object:slidePath()`.

--- Resets all of the object's `physics` table values to their default values, \
--- making it so it will stop moving if it was before.
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
        gravity_direction = math.pi / 2, -- down

        -- The amount this object's direction rotates (per frame at 30 fps)
        spin = 0,

        -- Whether direction should be based on rotation instead
        match_rotation = false,

        -- Movement target for Object:slideTo
        move_target = nil,
        -- Movement target for Object:slidePath
        move_path = nil,
    }
end

--- Resets the object's `physics` and sets new values for it.
---@param physics physics_table A table of values to set for the object's physics.
function Object:setPhysics(physics)
    self:resetPhysics()
    for k, v in pairs(physics) do
        self.physics[k] = v
    end
end

---@class graphics_table
---@field fade           number       The amount the object's alpha should approach its target value, per frame at 30FPS.
---@field fade_to        number       The target alpha to approach.
---@field fade_callback  function|nil A function that will be called when the object's alpha reaches its target value.
---@field grow_x         number       The amount the object's `scale_x` will increase, per frame at 30FPS.
---@field grow_y         number       The amount the object's `scale_y` will increase, per frame at 30FPS.
---@field grow           number       The amount the object's `scale_x` and `scale_y` will increase, per frame at 30FPS.
---@field remove_shrunk  boolean      If true, the object will remove itself if its scale goes below 0. (Defaults to false)
---@field spin           number       The amount the object's `rotation` will change, per frame at 30FPS.
---@field shake_x        number       The amount the object will shake in the `x` axis, per frame at 30FPS.
---@field shake_y        number       The amount the object will shake in the `y` axis, per frame at 30FPS.
---@field shake_friction number       The amount the object's shake will slow down, per frame at 30FPS.
---@field shake_delay    number       The time it takes for the object to invert its shake direction, in seconds.
---@field shake_timer    number       *(Used internally)* A timer used to invert the object's shake direction.

--- Resets all of the object's `graphics` table values to their default values, \
--- making it so it will stop transforming if it was before.
function Object:resetGraphics()
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
        spin = 0,

        -- Shake amount
        shake_x = 0,
        shake_y = 0,
        -- Shake friction (How much the shake decreases)
        shake_friction = 0,
        -- Shake speed (How much time it takes to invert the shake)
        shake_delay = 2 / 30,
        -- Shake timer (used to invert the shake)
        shake_timer = 0
    }
end

--- Resets the object's `graphics` and sets new values for it.
---@param graphics graphics_table A table of values to set for the object's graphics transformation.
function Object:setGraphics(graphics)
    self:resetGraphics()
    for k, v in pairs(graphics) do
        self.graphics[k] = v
    end
end

--- Moves the object's `x` and `y` values by the specified values.
---@param x      number How much to add to the object's `x` value.
---@param y      number How much to add to the object's `y` value.
---@param speed? number How much to multiply the `x` and `y` movement by. (Defaults to 1)
function Object:move(x, y, speed)
    self.x = self.x + (x or 0) * (speed or 1)
    self.y = self.y + (y or 0) * (speed or 1)
end

--- Fades the object's `alpha` to the specified value over `time` seconds.
---@param target    number   The alpha value that the object's `alpha` should approach.
---@param time?     number   The amount of time, in seconds, that the fade should take. (Defaults to 1 second)
---@param callback? function A function that will be called when the alpha value is reached. Receives `self` as an argument.
function Object:fadeTo(target, time, callback)
    self:fadeToSpeed(target, (1 / (time or 1)) / 30 * math.abs(self.alpha - target), callback)
end

--- Fades the object's `alpha` to the specified value at a speed of `speed` per frame.
---@param target    number   The alpha value that the object's `alpha` should approach.
---@param speed?    number   The amount that the object's `alpha` should approach the target value, per frame at 30FPS. (Defaults to 0.04)
---@param callback? function A function that will be called when the alpha value is reached. Receives `self` as an argument.
function Object:fadeToSpeed(target, speed, callback)
    self.graphics.fade = speed or 0.04
    self.graphics.fade_to = target or 0
    self.graphics.fade_callback = callback
end

--- Fades the object's `alpha` to 0 over `time` seconds, then removes it.
---@param time? number The amount of time, in seconds, that the fade should take. (Defaults to 1 second)
function Object:fadeOutAndRemove(time)
    self:fadeOutSpeedAndRemove((1 / (time or 1)) / 30 * self.alpha)
end

--- Fades the object's `alpha` to 0 at a speed of `speed` per frame, then removes it.
---@param speed? number The amount that the object's `alpha` should approach the target value, per frame at 30FPS. (Defaults to 0.04)
function Object:fadeOutSpeedAndRemove(speed)
    self.graphics.fade = speed or 0.04
    self.graphics.fade_to = 0
    self.graphics.fade_callback = self.remove
end

--- Makes the object shake by the specified amount.
---@param x?        number   The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number   The amount of shake in the `y` direction. (Defaults to `0`)
---@param friction? number   The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@param delay?    number   The time it takes for the object to invert its shake direction, in seconds. (Defaults to `1/30`)
function Object:shake(x, y, friction, delay)
    self.graphics.shake_x = x or 4
    self.graphics.shake_y = y or 0
    self.graphics.shake_friction = friction or 1
    self.graphics.shake_delay = delay or (1 / 30)
    self.graphics.shake_timer = 0
end

--- Stops the object from shaking.
function Object:stopShake()
    self.graphics.shake_x = 0
    self.graphics.shake_y = 0
end

--- Moves the object's `x` and `y` values to the new specified position over `time` seconds.
---@overload fun(self:Object, marker:string, time?:number, ease?:string, after?:function): success:boolean
---@param x      number   The new `x` value to approach.
---@param y      number   The new `y` value to approach.
---@param marker string   A map marker whose position the object should approach.
---@param time?  number   The amount of time, in seconds, that the slide should take. (Defaults to 1 second)
---@param ease?  string   The ease type to use when moving to the new position. (Defaults to "linear")
---@param after? function A function that will be called when the target position is reached. Receives no arguments.
---@return boolean success Whether the sliding will occur. False if the object's current position is already at the specified position, and true otherwise.
function Object:slideTo(x, y, time, ease, after)
    -- Ability to specify World marker for convenience in cutscenes
    if type(x) == "string" then
        ---@diagnostic disable-next-line: cast-local-type
        after = ease
        ---@diagnostic disable-next-line: cast-local-type
        ease = time
        time = y
        x, y = Game.world.map:getMarker(x)
    end
    time = time or 1
    self.physics.move_path = nil
    if self.x ~= x or self.y ~= y then
        self.physics.move_target = {
            x = x,
            y = y,
            time = time,
            timer = 0,
            start_x = self.x,
            start_y = self.y,
            ease = ease or "linear",
            after = after
        }
        return true
    else
        if after then
            after()
        end
        return false
    end
end

--- Moves the object's `x` and `y` values to the new specified position at a speed of `speed` pixels per frame.
---@overload fun(self:Object, marker:string, speed?:number, after?:function): success:boolean
---@param x      number   The new `x` value to approach.
---@param y      number   The new `y` value to approach.
---@param marker string   A map marker whose position the object should approach.
---@param speed? number   The amount that the object's `x` and `y` should approach the specified position, in pixels per frame at 30FPS. (Defaults to 4)
---@param after? function A function that will be called when the target position is reached. Receives no arguments.
---@return boolean success Whether the sliding will occur. False if the object's current position is already at the specified position, and true otherwise.
function Object:slideToSpeed(x, y, speed, after)
    -- Ability to specify World marker for convenience in cutscenes
    if type(x) == "string" then
        ---@diagnostic disable-next-line: cast-local-type
        after = speed
        speed = y
        x, y = Game.world.map:getMarker(x)
    end
    speed = speed or 4
    self.physics.move_path = nil
    if self.x ~= x or self.y ~= y then
        self.physics.move_target = { x = x, y = y, speed = speed, after = after }
        return true
    else
        if after then
            after()
        end
        return false
    end
end

--@param options? table A table defining additional properties that the path should follow:
--| "time" # The amount of time, in seconds, that the object should take to travel along the full path.
--| "speed" # The speed at which the object should travel along the path, in pixels per frame at 30FPS.
--| "ease" #
--| "relative" # Whether the path should be relative to the object's current position, or simply set its position directly.
--| "loop" # Whether the path should loop back to the first point when reaching the end, or if it should stop.
--| "reverse" # If true, reverse all of the points on the path.
--| "skip" # A number defining how many points of the path to skip.
--| "snap" # Whether the object's position should immediately "snap" to the first point, or if its initial position should be counted as a point on the path.

--- Moves the object along a path of points.
---@param path     table A table containing a list of tables with two number values in each, defining a list of points the object should follow.
---@param options? table A table defining additional properties that the path should use.
---| "time" # The amount of time, in seconds, that the object should take to travel along the full path.
---| "speed" # The speed at which the object should travel along the path, in pixels per frame at 30FPS.
---| "ease" # The ease type to use when travelling along the path. Unused if `speed` is specified instead of `time`. (Defaults to "linear")
---| "after" # A function that will be called when the end of the path is reached. Receives no arguments.
---| "move_func" # A function called every frame while the object is travelling along the path. Receives `self` and the `x` and `y` offset from the previous frame as arguments.
---| "relative" # Whether the path should be relative to the object's current position, or simply set its position directly.
---| "loop" # Whether the path should loop back to the first point when reaching the end, or if it should stop.
---| "reverse" # If true, reverse all of the points on the path.
---| "skip" # A number defining how many points of the path to skip.
---| "snap" # Whether the object's position should immediately "snap" to the first point, or if its initial position should be counted as a point on the path.
function Object:slidePath(path, options)
    options = options or {}

    -- Ability to specify World path for convenience in cutscenes
    if type(path) == "string" then
        local map_path = Game.world.map:getPath(path)
        assert(map_path, "No path found for slidePath: " .. path)
        assert(map_path.shape ~= "ellipse", "slidePath not compatible with ellipse paths")
        path = {}
        for _, point in ipairs(map_path.points) do
            if not options["relative"] then
                table.insert(path, { point.x, point.y })
            else
                table.insert(path, { point.x - map_path.points[1].x, point.y - map_path.points[1].y })
            end
        end
        if map_path.closed and options["loop"] == nil then
            options["loop"] = true
        end
    end

    if not options["relative"] and options["reverse"] then
        path = Utils.reverse(path)
    end

    if options["skip"] then
        for i = 1, options["skip"] do
            table.remove(path, 1)
        end
    end

    if options["relative"] then
        for _, point in ipairs(path) do
            point[1] = point[1] + self.x
            point[2] = point[2] + self.y
        end
    else
        if options["snap"] or options["loop"] then
            self:setPosition(path[1][1], path[1][2])
        elseif self.x ~= path[1][1] or self.y ~= path[1][2] then
            table.insert(path, 1, { self.x, self.y })
        end
    end

    local length = 0
    for i = 1, #path - 1 do
        length = length + Utils.dist(path[i][1], path[i][2], path[i + 1][1], path[i + 1][2])
    end

    self.physics.move_target = nil
    self.physics.move_path = {
        path = path,
        loop = options.loop or false,
        length = length,
        progress = 0,

        time = options.time,
        timer = 0,
        speed = options.speed,
        ease = options.ease or "linear",
        after = options.after,
        move_func = options.move_func
    }
end

--- Whether the object is colliding with another object or collider.
---@param other Object|Collider The object or collider to check collision with.
---@return boolean collided Whether the collision occurred or not.
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

--- Sets the object's `x` and `y` values to the specified position.
---@param x number The value to set `x` to.
---@param y number The value to set `y` to.
function Object:setPosition(x, y)
    self.x = x or 0; self.y = y or 0
end

--- Returns the position of the object.
---@return number x The `x` position of the object.
---@return number y The `y` position of the object.
function Object:getPosition() return self.x, self.y end

--- Sets the object's `width` and `height` values to the specified size.
---@param width   number The value to set `width` to.
---@param height? number The value to set `height` to. (Defaults to the `width` parameter)
function Object:setSize(width, height)
    self.width = width or 0; self.height = height or width or 0
end

--- Returns the size of the object.
---@return number width The `width` value of the object.
---@return number height The `height` value of the object.
function Object:getSize() return self.width, self.height end

--- Returns the width of the object, accounting for scale.
---@return number width The `width` of the object multiplied by its `scale_x`.
function Object:getScaledWidth() return self.width * self.scale_x end

--- Returns the height of the object, accounting for scale.
---@return number height The `height` of the object multiplied by its `scale_y`.
function Object:getScaledHeight() return self.height * self.scale_y end

--- Returns the size of the object, accounting for scale.
---@return number width The `width` of the object multiplied by its `scale_x`.
---@return number height The `height` of the object multiplied by its `scale_y`.
function Object:getScaledSize() return self:getScaledWidth(), self:getScaledHeight() end

--- Sets the object's `scale_x` and `scale_y` values to the specified scale.
---@param x  number The value to set `scale_x` to.
---@param y? number The value to set `scale_y` to. (Defaults to the `x` parameter)
function Object:setScale(x, y)
    self.scale_x = x or 1; self.scale_y = y or x or 1
end

--- Returns the scale of the object.
---@return number x The `scale_x` value of the object.
---@return number y The `scale_y` value of the object.
function Object:getScale() return self.scale_x, self.scale_y end

--- Sets the object's `color` and `alpha` values to the specified color.
---@overload fun(self:Object, color:{r:number, g:number, b:number, a?:number})
---@param r  number The red value to set for the object's `color`.
---@param g  number The green value to set for the object's `color`.
---@param b  number The blue value to set for the object's `color`.
---@param a? number The value to set `alpha` to. (Doesn't change alpha if unspecified)
---@param color table The value to set `color` to. Can optionally define a 4th value to set alpha.
function Object:setColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = unpack(r)
    end
    self.color = { r, g, b }
    self.alpha = a or self.alpha
end

--- Returns the values of the object's `color` and `alpha` values.
---@return number r The red value of the object's `color`.
---@return number g The green value of the object's `color`.
---@return number b The blue value of the object's `color`.
---@return number a The `alpha` value of the object.
function Object:getColor() return self.color[1], self.color[2], self.color[3], self.alpha end

--- Sets the object's `origin_x` and `origin_y` values to the specified origin, and sets `origin_exact` to false. \
--- The origin set by this function will therefore be a ratio relative to the object's width and height.
---@param x  number The value to set `origin_x` to.
---@param y? number The value to set `origin_y` to. (Defaults to the `x` parameter)
function Object:setOrigin(x, y)
    self.origin_x = x or 0; self.origin_y = y or x or 0; self.origin_exact = false
end

--- Returns the origin of the object, simplifying to be a ratio relative to its width and height if its current origin is exact.
---@return number x The horizontal origin of the object.
---@return number y The vertical origin of the object.
function Object:getOrigin()
    if not self.origin_exact then
        return self.origin_x, self.origin_y
    else
        return self.origin_x / self.width, self.origin_y / self.height
    end
end

--- Sets the object's `origin_x` and `origin_y` values to the specified origin, and sets `origin_exact` to true. \
--- The origin set by this function will therefore be in exact pixels.
---@param x  number The value to set `origin_x` to.
---@param y? number The value to set `origin_y` to. (Defaults to the `x` parameter)
function Object:setOriginExact(x, y)
    self.origin_x = x or 0; self.origin_y = y or x or 0; self.origin_exact = true
end

--- Returns the origin of the object, multiplying to give the exact pixels if its current origin is not exact.
---@return number x The horizontal origin of the object.
---@return number y The vertical origin of the object.
function Object:getOriginExact()
    if self.origin_exact then
        return self.origin_x, self.origin_y
    else
        return self.origin_x * self.width, self.origin_y * self.height
    end
end

--- Sets the object's `scale_origin_x` and `scale_origin_y` values to the specified origin, and sets `scale_origin_exact` to false. \
--- The scaling origin set by this function will therefore be a ratio relative to the object's width and height.
---@param x  number The value to set `scale_origin_x` to.
---@param y? number The value to set `scale_origin_y` to. (Defaults to the `x` parameter)
function Object:setScaleOrigin(x, y)
    self.scale_origin_x = x or 0; self.scale_origin_y = y or x or 0; self.scale_origin_exact = false
end

--- Returns the scaling origin of the object, simplifying to be a ratio relative to its width and height if its current scaling origin is exact. \
--- If the object doesn't have a scaling origin defined, it will return `self:getOrigin()` instead.
---@return number x The horizontal scaling origin of the object.
---@return number y The vertical scaling origin of the object.
function Object:getScaleOrigin()
    if not self.scale_origin_exact then
        local ox, oy = self:getOrigin()
        return self.scale_origin_x or ox, self.scale_origin_y or oy
    else
        local ox, oy = self:getOriginExact()
        return (self.scale_origin_x or ox) / self.width, (self.scale_origin_y or oy) / self.height
    end
end

--- Sets the object's `scale_origin_x` and `scale_origin_y` values to the specified origin, and sets `scale_origin_exact` to true. \
--- The scaling origin set by this function will therefore be in exact pixels.
---@param x  number The value to set `scale_origin_x` to.
---@param y? number The value to set `scale_origin_y` to. (Defaults to the `x` parameter)
function Object:setScaleOriginExact(x, y)
    self.scale_origin_x = x or 0; self.scale_origin_y = y or x or 0; self.scale_origin_exact = true
end

--- Returns the scaling origin of the object, multiplying to give the exact pixels if its current scaling origin is not exact. \
--- If the object doesn't have a scaling origin defined, it will return `self:getOriginExact()` instead.
---@return number x The horizontal scaling origin of the object.
---@return number y The vertical scaling origin of the object.
function Object:getScaleOriginExact()
    if self.scale_origin_exact then
        local ox, oy = self:getOriginExact()
        return self.scale_origin_x or ox, self.scale_origin_y or oy
    else
        local ox, oy = self:getOrigin()
        return (self.scale_origin_x or ox) * self.width, (self.scale_origin_y or oy) * self.height
    end
end

--- Sets the object's `rotation_origin_x` and `rotation_origin_y` values to the specified origin, and sets `rotation_origin_exact` to false. \
--- The rotation origin set by this function will therefore be a ratio relative to the object's width and height.
---@param x  number The value to set `rotation_origin_x` to.
---@param y? number The value to set `rotation_origin_y` to. (Defaults to the `x` parameter)
function Object:setRotationOrigin(x, y)
    self.rotation_origin_x = x or 0; self.rotation_origin_y = y or x or 0; self.rotation_origin_exact = false
end

--- Returns the rotation origin of the object, simplifying to be a ratio relative to its width and height if its current rotation origin is exact. \
--- If the object doesn't have a rotation origin defined, it will return `self:getOrigin()` instead.
---@return number x The horizontal rotation origin of the object.
---@return number y The vertical rotation origin of the object.
function Object:getRotationOrigin()
    if not self.rotation_origin_exact then
        local ox, oy = self:getOrigin()
        return self.rotation_origin_x or ox, self.rotation_origin_y or oy
    else
        local ox, oy = self:getOriginExact()
        return (self.rotation_origin_x or ox) / self.width, (self.rotation_origin_y or oy) / self.height
    end
end

--- Sets the object's `rotation_origin_x` and `rotation_origin_y` values to the specified origin, and sets `rotation_origin_exact` to true. \
--- The rotation origin set by this function will therefore be in exact pixels.
---@param x  number The value to set `rotation_origin_x` to.
---@param y? number The value to set `rotation_origin_y` to. (Defaults to the `x` parameter)
function Object:setRotationOriginExact(x, y)
    self.rotation_origin_x = x or 0; self.rotation_origin_y = y or x or 0; self.rotation_origin_exact = true
end

--- Returns the rotation origin of the object, multiplying to give the exact pixels if its current rotation origin is not exact. \
--- If the object doesn't have a rotation origin defined, it will return `self:getOriginExact()` instead.
---@return number x The horizontal rotation origin of the object.
---@return number y The vertical rotation origin of the object.
function Object:getRotationOriginExact()
    if self.rotation_origin_exact then
        local ox, oy = self:getOriginExact()
        return self.rotation_origin_x or ox, self.rotation_origin_y or oy
    else
        local ox, oy = self:getOrigin()
        return (self.rotation_origin_x or ox) * self.width, (self.rotation_origin_y or oy) * self.height
    end
end

--- Sets the object's `camera_origin_x` and `camera_origin_y` values to the specified origin, and sets `camera_origin_exact` to false. \
--- The camera origin set by this function will therefore be a ratio relative to the object's width and height.
---@param x  number The value to set `camera_origin_x` to.
---@param y? number The value to set `camera_origin_y` to. (Defaults to the `x` parameter)
function Object:setCameraOrigin(x, y)
    self.camera_origin_x = x or 0; self.camera_origin_y = y or x or 0; self.camera_origin_exact = false
end

--- Returns the camera origin of the object, simplifying to be a ratio relative to its width and height if its current camera origin is exact.
---@return number x The horizontal camera origin of the object.
---@return number y The vertical camera origin of the object.
function Object:getCameraOrigin()
    if not self.camera_origin_exact then
        return self.camera_origin_x, self.camera_origin_y
    else
        return self.camera_origin_x / self.width, self.camera_origin_y / self.height
    end
end

--- Sets the object's `camera_origin_x` and `camera_origin_y` values to the specified origin, and sets `camera_origin_exact` to true. \
--- The camera origin set by this function will therefore be in exact pixels.
---@param x  number The value to set `camera_origin_x` to.
---@param y? number The value to set `camera_origin_y` to. (Defaults to the `x` parameter)
function Object:setCameraOriginExact(x, y)
    self.camera_origin_x = x or 0; self.camera_origin_y = y or x or 0; self.camera_origin_exact = true
end

--- Returns the camera origin of the object, multiplying to give the exact pixels if its current camera origin is not exact.
---@return number x The horizontal camera origin of the object.
---@return number y The vertical camera origin of the object.
function Object:getCameraOriginExact()
    if self.camera_origin_exact then
        return self.camera_origin_x, self.camera_origin_y
    else
        return self.camera_origin_x * self.width, self.camera_origin_y * self.height
    end
end

--- *(Override)* \
--- By default, returns true.
---@return boolean attached Whether a Camera attached to this object should follow it.
function Object:isCameraAttachable() return true end

--- Sets the object's `parallax_x` and `parallax_y` to the specified parallax.
---@param x  number The value to set `parallax_x` to.
---@param y? number The value to set `parallax_y` to. (Defaults to the `x` parameter)
function Object:setParallax(x, y)
    self.parallax_x = x or 1; self.parallax_y = y or x or 1
end

--- Returns the parallax of the object.
---@return number x The `parallax_x` value of the object.
---@return number y The `parallax_y` value of the object.
function Object:getParallax() return self.parallax_x or 1, self.parallax_y or 1 end

--- Sets the object's `parallax_origin_x` and `parallax_origin_y` values to the specified origin.
---@param x number The value to set `parallax_origin_x` to.
---@param y number The value to set `parallax_origin_y` to.
function Object:setParallaxOrigin(x, y)
    self.parallax_origin_x = x; self.parallax_origin_y = y
end

--- Returns the parallax origin of the object.
---@return number x The `parallax_origin_x` value of the object.
---@return number y The `parallax_origin_y` value of the object.
function Object:getParallaxOrigin() return self.parallax_origin_x, self.parallax_origin_y end

--- Returns the layer of the object.
---@return number The `layer` value of the object.
function Object:getLayer() return self.layer end

--- Sets the object's `layer`, and updates its position in its parent's children list.
---@param layer number The value to set `layer` to.
function Object:setLayer(layer)
    if self.layer ~= layer then
        self.layer = layer
        if self.parent then
            self.parent.update_child_list = true
        end
    end
end

--- Sets the object's `cutout` values to the specified cutout.
---@param left   number|nil The value to set `cutout_left` to.
---@param top    number|nil The value to set `cutout_top` to.
---@param right  number|nil The value to set `cutout_right` to.
---@param bottom number|nil The value to set `cutout_bottom` to.
function Object:setCutout(left, top, right, bottom)
    self.cutout_left = left
    self.cutout_top = top
    self.cutout_right = right
    self.cutout_bottom = bottom
end

--- Returns the object's `cutout` values.
---@return number|nil The `cutout_left` value of the object.
---@return number|nil The `cutout_top` value of the object.
---@return number|nil The `cutout_right` value of the object.
---@return number|nil The `cutout_bottom` value of the object.
function Object:getCutout()
    return self.cutout_left, self.cutout_top, self.cutout_right, self.cutout_bottom
end

--- Sets the object's speed in its `physics` table.
---@overload fun(self:Object, speed:number)
---@param x number The value to set `physics.speed_x` to.
---@param y number The value to set `physics.speed_y` to.
---@param speed number The value to set `physics.speed` to.
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

--- Returns the velocity and direction of the object's physics, converting `physics.speed_x` and `physics.speed_y` if necessary.
---@return number speed     The linear speed the object moves at.
---@return number direction The direction the object is moving in.
function Object:getSpeedDir()
    if self.physics then
        if self.physics.speed and self.physics.speed ~= 0 then
            return self.physics.speed, self:getDirection()
        else
            local speed_x, speed_y = self.physics.speed_x or 0, self.physics.speed_y or 0
            if speed_x ~= 0 or speed_y ~= 0 then
                return Utils.dist(0, 0, speed_x, speed_y), Utils.angle(0, 0, speed_x, speed_y)
            end
        end
    end
    return 0, 0
end

--- Returns the horizontal and vertical speed of the object's physics, converting `physics.speed` and `physics.direction` if necessary
---@return number speed_x The horizontal speed of the object.
---@return number speed_y The vertical speed of the object.
function Object:getSpeedXY()
    if self.physics then
        if self.physics.speed and self.physics.speed ~= 0 then
            local direction = self:getDirection()
            return self.physics.speed * math.cos(direction), self.physics.speed * math.sin(direction)
        else
            return self.physics.speed_x or 0, self.physics.speed_y or 0
        end
    end
    return 0, 0
end

--- Sets the object's movement direction to the specified direction, or its rotation if `physics.match_rotation` is true.
---@param dir number The value to set `physics.direction` or `rotation` to.
function Object:setDirection(dir)
    if self.physics.match_rotation then
        self.rotation = dir
    else
        self.physics.direction = dir
    end
end

--- Returns the object's `physics.direction`, or the object's `rotation` if `physics.match_rotation` is true.
---@return number dir The movement direction of the object.
function Object:getDirection()
    return (self.physics.match_rotation and self.rotation) or self.physics.direction or 0
end

--- Returns the dimensions of the object's `collider` if that collider is a Hitbox.
---@return number|nil x The `x` position of the collider, relative to the object.
---@return number|nil y The `y` position of the collider, relative to the object.
---@return number|nil width The `width` of the collider, in pixels.
---@return number|nil height The `height` of the collider, in pixels.
function Object:getHitbox()
    if self.collider and self.collider:includes(Hitbox) then
        return self.collider.x, self.collider.y, self.collider.width, self.collider.height
    end
end

--- Sets the object's `collider` to a new Hitbox with the specified dimensions.
---@param x number The `x` position of the collider, relative to the object.
---@param y number The `y` position of the collider, relative to the object.
---@param w number The `width` of the collider, in pixels.
---@param h number The `height` of the collider, in pixels.
function Object:setHitbox(x, y, w, h)
    self.collider = Hitbox(self, x, y, w, h)
end

--- *(Override)* Used by World to determine what position should be used when sorting its layer. \
--- By default, returns `self:getRelativePos(self.width/2, self.height)`.
---@return number x The horizontal position to use.
---@return number y The vertical position to use.
function Object:getSortPosition()
    return self:getRelativePos(self.width / 2, self.height)
end

--- *(Override)* \
--- By default, returns `self.debug_select`.
---@return boolean can_select Whether the object can be selected by the Object Selection debug feature.
function Object:canDebugSelect()
    return self.debug_select
end

--- *(Override)* Returns a table defining the rectangle to use for selecting the object with the Object Selection debug feature. \
--- By default, returns `self.debug_rect`, or a rectangle with the same width and height as the object if `self.debug_rect` is `nil`.
---@return table rectangle A table containing 4 number values, defining the `x`, `y`, `width` and `height` of the selection rectangle.
function Object:getDebugRectangle()
    return self.debug_rect or { 0, 0, self.width, self.height }
end

--- *(Override)* \
--- By default, returns an empty table.
---@return table info A list of strings to display if the object is selected by the Object Selection debug feature.
function Object:getDebugInfo()
    return {}
end

--- *(Override)* Defines options that can be used when selecting the object with the Object Selection debug feature. \
--- By default, defines options that all objects use.
---@param context ContextMenu The menu object containing the debug options that can be used.
--- To define an option, use `context:addMenuItem(name: string, description: string, code: function)`, where:
--- - `name` defines the name that appears in the menu.
--- - `description` defines the text that appears when hovering over the option.
--- - `code` is the function that will be called when selecting the option.
---@return ContextMenu context The modified menu object.
function Object:getDebugOptions(context)
    context:addMenuItem("Delete", "Delete this object", function()
        self:remove()
        if Kristal.DebugSystem then
            Kristal.DebugSystem:unselectObject()
        end
    end)
    context:addMenuItem("Clone", "Clone this object", function()
        local clone = self:clone()
        clone:removeFX("debug_flash")
        self.parent:addChild(clone)
        clone:setScreenPos(Input.getMousePosition())
        Kristal.DebugSystem:selectObject(clone)
    end)
    context:addMenuItem("Copy", "Copy this object to paste it later", function()
        Kristal.DebugSystem:copyObject(self)
    end)
    context:addMenuItem("Cut", "Cut this object to paste it later", function()
        Kristal.DebugSystem:cutObject(self)
    end)
    if Kristal.DebugSystem and Kristal.DebugSystem.copied_object then
        context:addMenuItem("Paste Into", "Paste the copied object into this one", function()
            Kristal.DebugSystem:pasteObject(self)
        end)
    end
    if self.visible then
        context:addMenuItem("Hide", "Hide this object.", function() self.visible = false end)
    else
        context:addMenuItem("Show", "Show this object.", function() self.visible = true end)
    end
    context:addMenuItem("Explode", "'cuz it's funny", function() self:explode() end)
    return context
end

--- Sets the object's relative origin to the specified values, and adjusts its position so that it stays in the same place visually.
---@param ox  number The value to set `origin_x` to.
---@param oy? number The value to set `origin_y` to. (Defaults to the `ox` parameter)
function Object:shiftOrigin(ox, oy)
    local tx, ty = self:getRelativePos((ox or 0) * self.width, (oy or ox or 0) * self.height)
    self:setOrigin(ox, oy)
    self:setPosition(tx, ty)
end

--- Sets the object's exact origin to the specified values, and adjusts its position so that it stays in the same place visually.
---@param ox  number The value to set `origin_x` to.
---@param oy? number The value to set `origin_y` to. (Defaults to the `ox` parameter)
function Object:shiftOriginExact(ox, oy)
    local tx, ty = self:getRelativePos(ox or 0, oy or ox or 0)
    self:setOriginExact(ox, oy)
    self:setPosition(tx, ty)
end

--- Sets the object's position relative to the topleft of the game window.
---@param x number The `x` position for the object.
---@param y number The `y` position for the object.
function Object:setScreenPos(x, y)
    if self.parent then
        self:setPosition(self.parent:getFullTransform():inverseTransformPoint(x or 0, y or 0))
    else
        self:setPosition(x, y)
    end
end

--- Returns the object's position relative to the topleft of the game window.
---@return number x The `x` position of the object.
---@return number y The `y` position of the object.
function Object:getScreenPos()
    if self.parent then
        return self.parent:getFullTransform():transformPoint(self.x, self.y)
    else
        return self.x, self.y
    end
end

--- Returns the specified position for the object, relative to the object's stage.
---@param x? number The `x` position relative to the object.
---@param y? number The `y` position relative to the object.
---@return number x The new `x` position relative to the object's stage.
---@return number y The new `y` position relative to the object's stage.
function Object:localToScreenPos(x, y)
    return self:getFullTransform():transformPoint(x or 0, y or 0)
end

--- Returns the specified position for the object's stage, relative to this object.
---@param x? number The `x` position relative to the object's stage.
---@param y? number The `y` position relative to the object's stage.
---@return number x The new `x` position relative to the object.
---@return number y The new `y` position relative to the object.
function Object:screenToLocalPos(x, y)
    return self:getFullTransform():inverseTransformPoint(x or 0, y or 0)
end

--- Returns the specified position for the object, relative to another object.
---@param x?     number The `x` position relative to the object.
---@param y?     number The `y` position relative to the object.
---@param other? Object The object the returned values should be relative to.
---@return number x The new `x` position relative to the `other` object.
---@return number y The new `y` position relative to the `other` object.
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

--- Returns the object's position, relative to another object.
---@param other Object The object the returned values should be relative to.
---@return number x The new `x` position relative to the `other` object.
---@return number y The new `y` position relative to the `other` object.
function Object:getRelativePosFor(other)
    if other == self then
        return 0, 0
    else
        return self.parent:getRelativePos(self.x, self.y, other)
    end
end

---@return Object|nil stage The object's highest parent.
function Object:getStage()
    if self.parent and self.parent.parent then
        return self.parent:getStage()
    elseif self.parent then
        return self.parent
    end
end

--- Returns the object's color and alpha. \
--- If the object's `inherit_color` is true, the result is multiplied by its parent's color and alpha, to get the color it should draw at.
---@return number r The red value of the object's draw color.
---@return number g The green value of the object's draw color.
---@return number b The blue value of the object's draw color.
---@return number a The object's draw alpha.
function Object:getDrawColor()
    local r, g, b = unpack(self.color)
    if self.inherit_color and self.parent then
        local pr, pg, pb, pa = self.parent:getDrawColor()
        return r * pr, g * pg, b * pb, self.alpha * pa
    else
        return r, g, b, self.alpha
    end
end

--- Called during drawing to apply cutouts.
function Object:applyScissor()
    local left, top, right, bottom = self:getCutout()
    if left or top or right or bottom then
        Draw.scissorPoints(left, top, right and (self.width - right), bottom and (self.height - bottom))
    end
end

--- Adds a DrawFX to the object. \
--- DrawFX are classes that can apply visual effects to an object when drawing it. \
--- Each effect will be applied in sequence, with effects of higher priority rendering later.
---@generic T : DrawFX
---@param fx T The DrawFX instance to add to the object.
---@param id? string An optional string ID that can be used to reference the DrawFX in other functions.
---@return T fx The DrawFX instance that was added to the object.
function Object:addFX(fx, id)
    table.insert(self.draw_fx, fx)
    fx.parent = self
    if id then
        fx.id = id
    end
    return fx
end

--- Returns a DrawFX added to the object.
---@param id string|Class|DrawFX A string referring to the ID of a DrawFX, the class type that a DrawFX includes, or a DrawFX instance.
---@return DrawFX|nil fx A DrawFX instance if the object has one that matches the ID, or `nil` otherwise.
function Object:getFX(id)
    if isClass(id) then
        for _, fx in ipairs(self.draw_fx) do
            if fx:includes(id) or fx == id then
                return fx
            end
        end
    else
        for _, fx in ipairs(self.draw_fx) do
            if fx.id == id then
                return fx
            end
        end
    end
end

--- Removes the specified DrawFX from the object.
---@param id string|Class|DrawFX A string referring to the ID of a DrawFX, the class type that a DrawFX includes, or a DrawFX instance.
---@return DrawFX|nil fx The removed DrawFX instance if the object has one that matches the ID, or `nil` otherwise.
function Object:removeFX(id)
    local fx = self:getFX(id)
    if fx then
        if fx.parent == self then
            fx.parent = nil
        end
        Utils.removeFromTable(self.draw_fx, fx)
        return fx
    end
end

function Object:applyTransformTo(transform, floor_x, floor_y)
    Utils.pushPerformance("Object#applyTransformTo")
    if not floor_x then
        transform:translate(self.x, self.y)
    else
        transform:translate(Utils.floor(self.x, floor_x), Utils.floor(self.y, floor_y))
    end
    if self.parent and self.parent.camera and (self.parallax_x or self.parallax_y or self.parallax_origin_x or self.parallax_origin_y) then
        local px, py = self.parent.camera:getParallax(self.parallax_x or 1, self.parallax_y or 1, self.parallax_origin_x,
            self.parallax_origin_y)
        if not floor_x then
            transform:translate(px, py)
        else
            transform:translate(Utils.floor(px, floor_x), Utils.floor(py, floor_y))
        end
    end
    if self.flip_x or self.flip_y then
        transform:translate(self.width / 2, self.height / 2)
        transform:scale(self.flip_x and -1 or 1, self.flip_y and -1 or 1)
        transform:translate(-self.width / 2, -self.height / 2)
    end
    if floor_x then
        floor_x = floor_x / self.scale_x
        floor_y = floor_y / self.scale_y
    end
    local ox, oy = self:getOriginExact()
    if not floor_x then
        transform:translate(-ox, -oy)
    else
        transform:translate(-Utils.floor(ox, floor_x), -Utils.floor(oy, floor_y))
    end
    if self.rotation ~= 0 then
        local ox, oy = self:getRotationOriginExact()
        if floor_x then
            ox, oy = Utils.floor(ox, floor_x), Utils.floor(oy, floor_y)
        end
        transform:translate(ox, oy)
        transform:rotate(self.rotation)
        transform:translate(-ox, -oy)
    end
    if self.scale_x ~= 1 or self.scale_y ~= 1 then
        local ox, oy = self:getScaleOriginExact()
        if floor_x then
            ox, oy = Utils.floor(ox, floor_x), Utils.floor(oy, floor_y)
        end
        transform:translate(ox, oy)
        transform:scale(self.scale_x, self.scale_y)
        transform:translate(-ox, -oy)
    end
    if self.camera then
        self.camera:applyTo(transform, floor_x, floor_y)
    end
    if self.graphics and ((self.graphics.shake_x and self.graphics.shake_x ~= 0) or (self.graphics.shake_y and self.graphics.shake_y ~= 0)) then
        local shake_x, shake_y = math.ceil(self.graphics.shake_x), math.ceil(self.graphics.shake_y)
        if not floor_x then
            transform:translate(shake_x, shake_y)
        else
            transform:translate(Utils.floor(shake_x, floor_x), Utils.floor(shake_y, floor_y))
        end
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

---@return table hierarchy A table of all parents between this object and its stage (inclusive).
function Object:getHierarchy()
    local tbl = { self }
    if self.parent then
        for _, v in ipairs(self.parent:getHierarchy()) do
            table.insert(tbl, v)
        end
    end
    return tbl
end

--- Returns the object's scale, multiplied by its parent's full scale.
---@return number x The horizontal scale of the object.
---@return number y The vertical scale of the object.
function Object:getFullScale()
    local sx, sy = self.scale_x, self.scale_y
    if self.parent then
        local psx, psy = self.parent:getFullScale()
        sx = sx * psx
        sy = sy * psy
    end
    return sx, sy
end

--- Removes the object from its parent.
function Object:remove()
    if self.parent then
        self.parent:removeChild(self)
    end
end

---@param x? number The explosion's horizontal offset.
---@param y? number The explosion's vertical offset.
---@param dont_remove? boolean Whether the object should not be removed.
---@param options? table Additional properties.
---| "play_sound" # Whether it should play the sound. (Defaults to true)
---@return Explosion|nil
function Object:explode(x, y, dont_remove, options)
    if self.parent then
        options = options or {}
        local rx, ry = self:getRelativePos(self.width / 2 + (x or 0), self.height / 2 + (y or 0))
        local e = Explosion(rx, ry)
        e.layer = self.layer + 0.001
        e.play_sound = options["play_sound"] ~= false
        self.parent:addChild(e)
        if not dont_remove then
            self:remove()
        end
        return e
    end
end

--- Adds the specified object as a child to this object, and adds it to a stage if it was not added to one previously. \
--- Calls `child:onAdd(self)`.
---@generic T : Object
---@param child T The object to be added.
---@return T child The object that was added.
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

--- Removes the specified object from this object's children, and removes it from its stage. \
--- Calls `child:onRemove(self)`.
---@generic T : Object
---@param child T The object to be removed.
---@return T child The object that was removed.
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

---@return boolean has_stage Whether the object has a parent or not.
function Object:isRemoved()
    return self.stage == nil
end

--- Sets the object's parent, removing it from its previous parent if it had one.
---@param parent Object The object to add `self` to.
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

--- Returns whether the object and its parents are active, determining whether the object should be updated or not.
---@return boolean active Whether the object and its parents are active.
function Object:isFullyActive()
    if self.stage and self.parent == self.stage then
        return self.active
    elseif self.stage and self.parent then
        return self.active and self.parent:isFullyActive()
    end
    return false
end

--- Returns whether the object and its parents are visible, determining whether the object should be drawn or not.
---@return boolean visible Whether the object and its parents are visible.
function Object:isFullyVisible()
    if self.stage and self.parent == self.stage then
        return self.visible
    elseif self.stage and self.parent then
        return self.visible and self.parent:isFullyVisible()
    end
    return false
end

--[[ Internal functions ]]
--

function Object:sortChildren()
    table.stable_sort(self.children, Object.LAYER_SORT)
end

function Object:updateChildList()
    local to_remove = Utils.copy(self.children_to_remove)
    self.children_to_remove = {}
    for child, _ in pairs(to_remove) do
        for i, v in ipairs(self.children) do
            if v == child then
                child:onRemove(self)
                table.remove(self.children, i)
                break
            end
        end
    end
    self:sortChildren()
end

function Object:updateChildren()
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    for _, v in ipairs(self.draw_fx) do
        v:update()
    end
    for _, v in ipairs(self.children) do
        if v.active and v.parent == self then
            v:fullUpdate()
        end
    end
end

function Object:fullUpdate()
    local used_timescale, last_dt, last_dt_mult, last_runtime = false, DT, DTMULT, RUNTIME
    if self.timescale ~= 1 then
        used_timescale = true
        self._runtime_update_offset = (self._runtime_update_offset or 0) + (self.timescale - 1) * DT
        DT = DT * self.timescale
        DTMULT = DTMULT * self.timescale
    end
    if self._runtime_update_offset then
        used_timescale = true
        RUNTIME = RUNTIME + self._runtime_update_offset
    end
    self.last_x = self.x
    self.last_y = self.y
    self:update()
    if used_timescale then
        DT = last_dt
        DTMULT = last_dt_mult
        RUNTIME = last_runtime
    end
end

function Object:preDraw(dont_transform)
    if not dont_transform then
        local transform = love.graphics.getTransformRef()
        self:applyTransformTo(transform, 1 / CURRENT_SCALE_X, 1 / CURRENT_SCALE_Y)
        love.graphics.replaceTransform(transform)

        self._last_draw_scale_x = CURRENT_SCALE_X
        self._last_draw_scale_y = CURRENT_SCALE_Y

        CURRENT_SCALE_X = CURRENT_SCALE_X * self.scale_x
        CURRENT_SCALE_Y = CURRENT_SCALE_Y * self.scale_y
        if self.camera then
            CURRENT_SCALE_X = CURRENT_SCALE_X * self.camera.zoom_x
            CURRENT_SCALE_Y = CURRENT_SCALE_Y * self.camera.zoom_y
        end
    end

    Draw.setColor(self:getDrawColor())
    Draw.pushScissor()
    self:applyScissor()
end

function Object:postDraw()
    Draw.popScissor()

    CURRENT_SCALE_X = self._last_draw_scale_x or CURRENT_SCALE_X
    CURRENT_SCALE_Y = self._last_draw_scale_y or CURRENT_SCALE_Y

    self._last_draw_scale_x, self._last_draw_scale_y = nil, nil
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
    for _, v in ipairs(self.children) do
        if v.visible and (not min_layer or v.layer >= min_layer) and (not max_layer or v.layer < max_layer) then
            v:fullDraw()
        end
    end
    Draw.setColor(oldr, oldg, oldb, olda)
end

function Object:drawSelf(no_children, dont_transform)
    local last_draw_children = self._dont_draw_children
    if no_children then
        self._dont_draw_children = true
    end
    love.graphics.push()
    self:preDraw(dont_transform)
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
end

function Object:fullDraw(no_children, dont_transform)
    local used_timescale, last_dt, last_dt_mult, last_runtime = false, DT, DTMULT, RUNTIME
    if self.timescale ~= 1 then
        used_timescale = true
        self._runtime_draw_offset = (self._runtime_draw_offset or 0) + (self.timescale - 1) * DT
        DT = DT * self.timescale
        DTMULT = DTMULT * self.timescale
    end
    if self._runtime_draw_offset then
        used_timescale = true
        RUNTIME = RUNTIME + self._runtime_draw_offset
    end
    local processing_fx, fx_transform, fx_screen = self:shouldProcessDrawFX()
    local fx_off_x, fx_off_y = math.floor(SCREEN_WIDTH / 2 - self.width / 2), math.floor(SCREEN_HEIGHT / 2 -
        self.height / 2)
    local canvas = nil
    if processing_fx then
        Draw.pushCanvasLocks()
        canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT, { keep_transform = not fx_transform })
        if fx_transform then
            love.graphics.translate(fx_off_x, fx_off_y)
        end
    end
    self:drawSelf(no_children, fx_transform or dont_transform)
    if processing_fx then
        Draw.popCanvas(true)
        local final_canvas = canvas
        if fx_transform then
            final_canvas = self:processDrawFX(canvas, true)
            love.graphics.push()
            if not dont_transform then
                local current_transform = love.graphics.getTransformRef()
                self:applyTransformTo(current_transform)
                love.graphics.replaceTransform(current_transform)
            end
            if fx_screen then
                local screen_canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT, { keep_transform = true })
                Draw.setColor(1, 1, 1)
                Draw.draw(final_canvas, -fx_off_x, -fx_off_y)
                Draw.popCanvas(true)
                Draw.unlockCanvas(final_canvas)
                final_canvas = screen_canvas
            else
                Draw.setColor(1, 1, 1)
                Draw.draw(final_canvas, -fx_off_x, -fx_off_y)
            end
            love.graphics.pop()
        end
        if fx_screen then
            final_canvas = self:processDrawFX(final_canvas, false)
            love.graphics.push()
            love.graphics.origin()
            Draw.setColor(1, 1, 1)
            Draw.draw(final_canvas)
            love.graphics.pop()
        end
        Draw.popCanvasLocks()
    end
    if used_timescale then
        DT = last_dt
        DTMULT = last_dt_mult
        RUNTIME = last_runtime
    end
end

function Object:shouldProcessDrawFX()
    local any_active, any_transformed, any_screen = false, false, false
    for _, fx in ipairs(self.draw_fx) do
        if fx:isActive(self) then
            any_active = true
            any_transformed = any_transformed or fx.transformed
            any_screen = any_screen or not fx.transformed
        end
    end
    return any_active, any_transformed, any_screen
end

function Object:processDrawFX(canvas, transformed)
    table.stable_sort(self.draw_fx, FXBase.SORTER)

    for _, fx in ipairs(self.draw_fx) do
        if fx:isActive(self) and (transformed == nil or fx.transformed == transformed) then
            local next_canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
            Draw.setColor(1, 1, 1)
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
            physics.speed = math.sqrt(new_speed_x * new_speed_x + new_speed_y * new_speed_y)
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

    if physics.move_target then
        local next_x, next_y = self.x, self.y
        if physics.move_target.speed then
            local angle = Utils.angle(self.x, self.y, physics.move_target.x, physics.move_target.y)
            next_x = Utils.approach(self.x, physics.move_target.x,
                physics.move_target.speed * math.abs(math.cos(angle)) * DTMULT)
            next_y = Utils.approach(self.y, physics.move_target.y,
                physics.move_target.speed * math.abs(math.sin(angle)) * DTMULT)
        elseif physics.move_target.time then
            physics.move_target.timer = Utils.approach(physics.move_target.timer, physics.move_target.time, DT)

            next_x = Utils.ease(physics.move_target.start_x, physics.move_target.x,
                (physics.move_target.timer / physics.move_target.time), physics.move_target.ease)
            next_y = Utils.ease(physics.move_target.start_y, physics.move_target.y,
                (physics.move_target.timer / physics.move_target.time), physics.move_target.ease)
        end
        if physics.move_target.move_func then
            physics.move_target.move_func(self, next_x - self.x, next_y - self.y)
        else
            self:setPosition(next_x, next_y)
        end
        if next_x == physics.move_target.x and next_y == physics.move_target.y then
            local after = physics.move_target.after
            physics.move_target = nil
            if after then after() end
        end
    elseif physics.move_path then
        if physics.move_path.speed then
            physics.move_path.progress = physics.move_path.progress + (physics.move_path.speed * DTMULT)
        elseif physics.move_path.time then
            physics.move_path.timer = physics.move_path.timer + DT
            physics.move_path.progress = (physics.move_path.timer / physics.move_path.time) * physics.move_path.length
        end
        if not physics.move_path.loop then
            physics.move_path.progress = Utils.clamp(physics.move_path.progress, 0, physics.move_path.length)
        else
            physics.move_path.progress = physics.move_path.progress % physics.move_path.length
        end
        local eased_progress = Utils.ease(0, physics.move_path.length,
            (physics.move_path.progress / physics.move_path.length), physics.move_path
            .ease)
        local target_x, target_y = Utils.getPointOnPath(physics.move_path.path, eased_progress)
        if physics.move_path.move_func then
            physics.move_path.move_func(self, target_x - self.x, target_y - self.y)
        else
            self:setPosition(target_x, target_y)
        end
        if not physics.move_path.loop and physics.move_path.progress >= physics.move_path.length then
            local after = physics.move_path.after
            physics.move_path = nil
            if after then after() end
        end
    end
end

function Object:updateGraphicsTransform()
    local graphics = self.graphics

    if not graphics then return end

    if graphics.fade and graphics.fade ~= 0 and self.alpha ~= graphics.fade_to then
        self.alpha = Utils.approach(self.alpha, graphics.fade_to, graphics.fade * DTMULT)
        if self.alpha == graphics.fade_to then
            graphics.fade = 0
            graphics.fade_to = 0
            if graphics.fade_callback then
                graphics.fade_callback(self)
            end
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

    if (graphics.shake_x and graphics.shake_x ~= 0) or (graphics.shake_y and graphics.shake_y ~= 0) then
        graphics.shake_timer = (graphics.shake_timer or 0) + DT
        while graphics.shake_timer >= (graphics.shake_delay or (2 / 30)) do
            graphics.shake_x = (graphics.shake_x or 0) * -1
            graphics.shake_y = (graphics.shake_y or 0) * -1
            graphics.shake_timer = graphics.shake_timer - (graphics.shake_delay or (2 / 30))
        end
        if graphics.shake_friction and graphics.shake_friction ~= 0 then
            graphics.shake_x = Utils.approach(graphics.shake_x or 0, 0, graphics.shake_friction * DTMULT)
            graphics.shake_y = Utils.approach(graphics.shake_y or 0, 0, graphics.shake_friction * DTMULT)
        end
    end
end

function Object:onClone(src)
    if self.parent and self.parent.children and not Utils.containsValue(self.parent.children, self) then
        self.parent = nil
    end
    self.stage = nil
end

function Object:canDeepCopy()
    return true
end

function Object:canDeepCopyKey(key)
    return key ~= "parent"
end

return Object
