---@class Camera : Class
---
---@field parent Object|nil
---
---@field x number                            # X position of the camera's center.
---@field y number                            # Y position of the camera's center.
---@field width number                        # Width of the camera (usually `SCREEN_WIDTH`).
---@field height number                       # Height of the camera (usually `SCREEN_HEIGHT`).
---
---@field state string                        # The current camera state.
---@field state_manager StateManager          # Manages the camera state.
---
---@field mods table<string, Camera.modifier> # Camera modifiers (position, offset, bounds - smoothly transitioned between).
---@field mod_order string[]                  # Order camera modifiers are processed in.
---@field updated_mods boolean                # Whether modifiers have been updated this frame.
---
---@field default_approach_speed number       # Default modifier approach speed.
---@field default_approach_time number        # Default modifier approach time.
---@field lerper table                        # Current modifier approach settings.
---
---@field target Object|nil                   # Camera target.
---@field target_getter (fun():Object)|nil    # Optional function to get the camera target, if not set explicitly.
---
---@field attached_x boolean                  # Whether the camera is attached to the target (x-axis).
---@field attached_y boolean                  # Whether the camera is attached to the target (y-axis).
---
---@field ox number                           # Camera offset (x-axis).
---@field oy number                           # Camera offset (y-axis).
---
---@field zoom_x number                       # Camera zoom (x-axis).
---@field zoom_y number                       # Camera zoom (y-axis).
---
---@field rotation number                     # Camera rotation (radians).
---
---@field shake_x number                      # Camera shake (x-axis).
---@field shake_y number                      # Camera shake (y-axis).
---@field shake_friction number               # Camera shake friction (how much the shake decreases).
---@field shake_timer number                  # Camera shake timer (used to invert the shake).
--
---@field bounds table|nil                    # Camera bounds (for clamping).
---@field keep_in_bounds boolean              # Whether the camera should stay in bounds.
---
---@field pan_target table|nil                # Camera pan target (for automatic panning).
---
---@overload fun(parent?:Object, x?:number, y?:number, width?:number, height?:number, keep_in_bounds?:boolean) : Camera
local Camera = Class()

---@class Camera.modifier
---@field value any
---@field state string
---@field x boolean
---@field y boolean

---@private
---@param parent? Object
---@param x? number
---@param y? number
---@param width? number
---@param height? number
---@param keep_in_bounds? boolean
function Camera:init(parent, x, y, width, height, keep_in_bounds)
    self.parent = parent

    self.x = x or 0
    self.y = y or 0
    self.width = width or SCREEN_WIDTH
    self.height = height or SCREEN_HEIGHT

    self.state_manager = StateManager("ATTACHED", self, true)
    self.state_manager:addState("STATIC")
    self.state_manager:addState("ATTACHED", {enter = self.beginAttached, update = self.updateAttached, leave = self.endAttached})
    self.state_manager:addState("PAN", {update = self.updatePanning})

    -- Camera modifiers (position, offset, bounds - smoothly transitioned between)
    self.mods = {
        x =      {value = 0,   state = "INACTIVE", x = true,  y = false},
        y =      {value = 0,   state = "INACTIVE", x = false, y = true },
        ox =     {value = 0,   state = "INACTIVE", x = true,  y = false},
        oy =     {value = 0,   state = "INACTIVE", x = false, y = true },
        bounds = {value = nil, state = "INACTIVE", x = true,  y = true }
    }
    -- Order camera modifiers are processed in
    self.mod_order = {"x", "y", "ox", "oy", "bounds"}
    -- Whether modifiers have been updated this frame
    self.updated_mods = false

    -- Default modifier approach speed and time
    self.default_approach_speed = 16
    self.default_approach_time = 0.25
    -- Current modifier approach settings
    self.lerper = {
        type = "speed",
        speed = self.default_approach_speed,
        time = self.default_approach_time,
        timer = 0, start_x = nil, start_y = nil
    }

    -- Camera target
    self.target = nil
    -- Optional function to get the camera target, if not set explicitly
    self.target_getter = nil

    -- Whether the camera is attached to the target
    self.attached_x = true
    self.attached_y = true

    -- Camera offset
    self.ox = 0
    self.oy = 0

    -- Camera zoom
    self.zoom_x = 1
    self.zoom_y = 1

    -- Camera rotation
    self.rotation = 0

    -- Camera shake
    self.shake_x = 0
    self.shake_y = 0
    -- Camera shake friction (How much the shake decreases)
    self.shake_friction = 0
    -- Camera shake timer (used to invert the shake)
    self.shake_timer = 0

    -- Camera bounds (for clamping)
    self.bounds = nil
    -- Whether the camera should stay in bounds
    self.keep_in_bounds = keep_in_bounds ~= false

    -- Camera pan target (for automatic panning)
    self.pan_target = nil

    -- Update position
    self:keepInBounds()
end

---@param state string
function Camera:setState(state)
    self.state_manager:setState(state)
end

---@return number x, number y, number width, number height
function Camera:getBounds()
    if not self.bounds then
        if self.parent then
            return 0, 0, self.parent.width, self.parent.height
        else
            return 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT
        end
    else
        return self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height
    end
end

---@param x number
---@param y number
---@param width number
---@param height number
---@overload fun()
function Camera:setBounds(x, y, width, height)
    if x then
        self.bounds = {x = x, y = y, width = width, height = height}
    else
        self.bounds = nil
    end
end

---@param scaled? boolean
---@return number x, number y, number width, number height
function Camera:getRect(scaled)
    local x, y = self:getOffsetPos()

    if scaled ~= false then
        return x - (self.width / self.zoom_x / 2), y - (self.height / self.zoom_y / 2), self.width / self.zoom_x, self.height / self.zoom_y
    else
        return x - (self.width / 2), y - (self.height / 2), self.width, self.height
    end
end

---@return number x, number y
function Camera:getPosition() return self.x, self.y end

---@param x number
---@param y number
function Camera:setPosition(x, y)
    self.x = x
    self.y = y
    self:keepInBounds()
end

---@return number x, number y
function Camera:getOffset() return self.ox, self.oy end

---@param ox number
---@param oy number
function Camera:setOffset(ox, oy)
    self.ox = ox
    self.oy = oy
end

---@return number x, number y
function Camera:getOffsetPos()
    local shake_x, shake_y = math.ceil(self.shake_x), math.ceil(self.shake_y)
    if Kristal.Config["simplifyVFX"] then
        shake_x, shake_y = 0, 0
    end
    return self.x + self.ox + shake_x, self.y + self.oy + shake_y
end

---@return number zoom_x, number zoom_y
function Camera:getZoom() return self.zoom_x, self.zoom_y end

---@param x number
---@param y number
function Camera:setZoom(x, y)
    self.zoom_x = x or 1
    self.zoom_y = y or x or 1
    self:keepInBounds()
end

---@param x number
---@param y number
---@param amount number
function Camera:approach(x, y, amount)
    local angle = Utils.angle(self.x, self.y, x, y)
    self.x = Utils.approach(self.x, x, math.abs(math.cos(angle)) * amount)
    self.y = Utils.approach(self.y, y, math.abs(math.sin(angle)) * amount)
    self:keepInBounds()
end

---@param x number
---@param y number
---@param amount number
function Camera:approachDirect(x, y, amount)
    self.x = Utils.approach(self.x, x, amount)
    self.y = Utils.approach(self.y, y, amount)
    self:keepInBounds()
end

---@param x? number
---@param y? number
---@param friction? number
function Camera:shake(x, y, friction)
    self.shake_x = x or 4
    self.shake_y = y or x or 4
    self.shake_friction = friction or 1
    self.shake_timer = 0
end

function Camera:stopShake()
    self.shake_x = 0
    self.shake_y = 0
end

---@param x number
---@param y number
---@param time number
---@param ease? easetype
---@param after? fun()
---@return boolean
---@overload fun(self, marker:string, time:number, ease?:easetype, after?:fun()) : boolean
function Camera:panTo(x, y, time, ease, after)
    if type(x) == "string" then
        after = ease --[[@as fun()]]
        ease = time --[[@as easetype]]
        time = y
        x, y = Game.world.map:getMarker(x)
    end

    local min_x, min_y = self:getMinPosition()
    local max_x, max_y = self:getMaxPosition()

    if x then
        x = Utils.clamp(x, min_x, max_x)
    end
    if y then
        y = Utils.clamp(y, min_y, max_y)
    end

    if time == 0 then
        self:setPosition(x or self.x, y or self.y)
        self:setState("STATIC")
        if after then
            after()
        end
        return false
    end

    if (x and self.x ~= x) or (y and self.y ~= y) then
        self.pan_target = {x = x, y = y, time = time, timer = 0, start_x = self.x, start_y = self.y, ease = ease or "linear", after = after}
        self:setState("PAN")
        return true
    else
        self:setState("STATIC")
        if after then
            after()
        end
        return false
    end
end

---@param x number
---@param y number
---@param speed number
---@param after? fun()
---@return boolean
---@overload fun(self, marker:string, speed:number, after?:fun()) : boolean
function Camera:panToSpeed(x, y, speed, after)
    if type(x) == "string" then
        after = speed --[[@as fun()]]
        speed = y
        x, y = Game.world.map:getMarker(x)
    end

    local min_x, min_y = self:getMinPosition()
    local max_x, max_y = self:getMaxPosition()

    if x then
        x = Utils.clamp(x, min_x, max_x)
    end
    if y then
        y = Utils.clamp(y, min_y, max_y)
    end

    if (x and self.x ~= x) or (y and self.y ~= y) then
        self:setState("PAN")
        self.pan_target = {x = x, y = y, speed = speed, after = after}
        return true
    else
        if after then
            after()
        end
        return false
    end
end

---@return Object|nil
function Camera:getTarget()
    if self.target and self.target.stage then
        return self.target
    elseif self.target_getter then
        local target = self.target_getter()
        if target and target.stage then
            return target
        end
    end
end

---@return number x, number y
function Camera:getTargetPosition()
    local x, y = self.x, self.y

    local target = self:getTarget()
    if target and target:isCameraAttachable() then
        local ox, oy = target:getCameraOriginExact()
        x, y = target:getRelativePos(ox, oy, self.parent)
    end

    local min_x, min_y = self:getMinPosition()
    local max_x, max_y = self:getMaxPosition()

    x = Utils.clamp(x, min_x, max_x)
    y = Utils.clamp(y, min_y, max_y)

    return x, y
end

---@param attached_x? boolean
---@param attached_y? boolean
function Camera:setAttached(attached_x, attached_y)
    if attached_y == nil then
        attached_y = attached_x
    end
    self.attached_x = attached_x or false
    self.attached_y = attached_y or false
    if self.attached_x or self.attached_y and self.state_manager.state ~= "ATTACHED" then
        self:setState("ATTACHED")
    elseif not self.attached_x and not self.attached_y and self.state_manager.state == "ATTACHED" then
        self:setState("STATIC")
    end
end

---@param name string
---@param value any
---@param approach_speed? number
---@param approach_type? "time"|"speed"|"instant"
---@overload fun(self, name:string, value:any, approach_type:"instant")
function Camera:setModifier(name, value, approach_speed, approach_type)
    if approach_speed == true or approach_speed == "instant" then
        approach_type = "instant"
    end
    local instant = approach_type == "instant"
    if not instant then
        self.lerper.type = approach_type or "speed"
        if self.lerper.type == "speed" then
            self.lerper.speed = approach_speed or self.default_approach_speed
        elseif self.lerper.type == "time" then
            self.lerper.time = approach_speed or self.default_approach_time
            self.lerper.timer = 0
            self.lerper.start_x = self.x
            self.lerper.start_y = self.y
        end
    end
    if value == nil then
        self.mods[name].value = nil
        if self.mods[name].state ~= "INACTIVE" then
            self.mods[name].state = instant and "INACTIVE" or "OUT"
        end
    else
        self.mods[name].value = value
        self.mods[name].state = instant and "ACTIVE" or "IN"
    end
end

---@param immediate? boolean
function Camera:resetModifiers(immediate)
    for name, mod in pairs(self.mods) do
        mod.value = nil
        if mod.state ~= "INACTIVE" then
            mod.state = immediate and "INACTIVE" or "OUT"
        end
    end
    self.lerper = {
        type = "speed",
        speed = self.default_approach_speed,
        time = self.default_approach_time,
        timer = 0, start_x = nil, start_y = nil
    }
end

---@param bx number
---@param by number
---@param bw number
---@param bh number
---@return number x, number y
---@overload fun() : x:number, y:number
function Camera:getMinPosition(bx, by, bw, bh)
    if not self.keep_in_bounds then
        return -math.huge, -math.huge
    else
        if not bx then
            bx, by, bw, bh = self:getBounds()
        end
        return bx + (self.width / self.zoom_x) / 2, by + (self.height / self.zoom_y) / 2
    end
end

---@param bx number
---@param by number
---@param bw number
---@param bh number
---@return number x, number y
---@overload fun() : x:number, y:number
function Camera:getMaxPosition(bx, by, bw, bh)
    if not self.keep_in_bounds then
        return math.huge, math.huge
    else
        if not bx then
            bx, by, bw, bh = self:getBounds()
        end
        return bx + bw - (self.width / self.zoom_x) / 2, by + bh - (self.height / self.zoom_y) / 2
    end
end

function Camera:keepInBounds()
    if self.keep_in_bounds then
        local min_x, min_y = self:getMinPosition()
        local max_x, max_y = self:getMaxPosition()

        self.x = Utils.clamp(self.x, min_x, max_x)
        self.y = Utils.clamp(self.y, min_y, max_y)
    end
end

---@private
---@param x number
---@param y number
---@return boolean static_x, boolean static_y
function Camera:moveTo(x, y)
    local target_x, target_y = x, y
    if self.keep_in_bounds then
        local min_x, min_y = self:getMinPosition()
        local max_x, max_y = self:getMaxPosition()
        target_x = Utils.clamp(target_x, min_x, max_x)
        target_y = Utils.clamp(target_y, min_y, max_y)
    end

    --local approach_speed = Utils.dist(self.x, self.y, x, y)
    --approach_speed = math.max(min_speed or 12, approach_speed * 1.5)

    local approach_x, approach_y = false, false

    self.updated_mods = true

    for _,v in ipairs(self.mod_order) do
        local mod = self.mods[v]
        if mod.state == "IN" or mod.state == "ACTIVE" then
            local mod_x, mod_y = self:processMod(v, self.mods[v], target_x, target_y)
            target_x = mod_x or target_x
            target_y = mod_y or target_y
        end
        if mod.state == "IN" or mod.state == "OUT" then
            approach_x = approach_x or mod.x
            approach_y = approach_y or mod.y
        end
    end

    if self.keep_in_bounds then
        local min_x, min_y = self:getMinPosition()
        local max_x, max_y = self:getMaxPosition()
        target_x = Utils.clamp(target_x, min_x, max_x)
        target_y = Utils.clamp(target_y, min_y, max_y)
    end

    if self.lerper.type == "time" then
        if not self.lerper.start_x then
            self.lerper.start_x = self.x
        end
        if not self.lerper.start_y then
            self.lerper.start_y = self.y
        end
        self.lerper.timer = Utils.approach(self.lerper.timer, self.lerper.time, DT)

        if approach_x and approach_y then
            self.x, self.y = Utils.lerpPoint(
                self.lerper.start_x, self.lerper.start_y,
                target_x, target_y,
                self.lerper.timer / self.lerper.time)
        elseif approach_x then
            self.x = Utils.lerp(self.lerper.start_x, target_x, self.lerper.timer / self.lerper.time)
            self.y = target_y
        elseif approach_y then
            self.x = target_x
            self.y = Utils.lerp(self.lerper.start_y, target_y, self.lerper.timer / self.lerper.time)
        else
            self.x = target_x
            self.y = target_y
        end
    elseif self.lerper.type == "speed" then
        if approach_x and approach_y then
            self:approach(target_x, target_y, self.lerper.speed * DTMULT)
        elseif approach_x then
            self.x = Utils.approach(self.x, target_x, self.lerper.speed * DTMULT)
            self.y = target_y
        elseif approach_y then
            self.x = target_x
            self.y = Utils.approach(self.y, target_y, self.lerper.speed * DTMULT)
        else
            self.x = target_x
            self.y = target_y
        end
    elseif self.lerper.type == "instant" then
        self.x = target_x
        self.y = target_y
    end

    for k,v in pairs(self.mods) do
        if (not v.x or self.x == target_x) and (not v.y or self.y == target_y) then
            if v.state == "IN" then
                v.state = "ACTIVE"
            elseif v.state == "OUT" then
                v.state = "INACTIVE"
            end
        end
    end

    return not approach_x, not approach_y
end

---@param name string
---@param mod Camera.modifier
---@param x number
---@param y number
---@return number? x, number? y
function Camera:processMod(name, mod, x, y)
    if name == "x" then
        return mod.value, y
    elseif name == "y" then
        return x, mod.value
    elseif name == "ox" then
        return x + mod.value, y
    elseif name == "oy" then
        return x, y + mod.value
    elseif name == "bounds" then
        local bx, by, bw, bh = self:getBounds()

        local temp_bx, temp_by = mod.value[1], mod.value[2]
        local temp_bw, temp_bh = mod.value[3], mod.value[4]

        local bx2, by2 = bx + bw, by + bh
        local temp_bx2, temp_by2 = temp_bx + temp_bw, temp_by + temp_bh

        local target_bx, target_by = math.max(bx, temp_bx), math.max(by, temp_by)
        local target_bw, target_bh = math.min(bx2, temp_bx2) - target_bx, math.min(by2, temp_by2) - target_by

        local min_x, min_y = self:getMinPosition(target_bx, target_by, target_bw, target_bh)
        local max_x, max_y = self:getMaxPosition(target_bx, target_by, target_bw, target_bh)

        return Utils.clamp(x, min_x, max_x), Utils.clamp(y, min_y, max_y)
    end
end

function Camera:update()
    if self.shake_x ~= 0 or self.shake_y ~= 0 then
        self.shake_timer = self.shake_timer + DTMULT
        if self.shake_timer >= 1 then
            self.shake_x = self.shake_x * -1
            self.shake_y = self.shake_y * -1
            self.shake_timer = self.shake_timer - 1
        end
        if self.shake_friction then
            self.shake_x = Utils.approach(self.shake_x, 0, self.shake_friction * DTMULT)
            self.shake_y = Utils.approach(self.shake_y, 0, self.shake_friction * DTMULT)
        end
    end

    self.updated_mods = false

    self.state_manager:update()

    if not self.updated_mods then
        for k,v in pairs(self.mods) do
            if v.state == "ACTIVE" then
                v.state = "IN"
            end
        end
        self.lerper.timer = 0
        self.lerper.start_x = nil
        self.lerper.start_y = nil
    end

    self:keepInBounds()
end

--[[ State Callbacks ]]--

---@private
---@param last_state string
---@param attach_x? boolean
---@param attach_y? boolean
function Camera:beginAttached(last_state, attach_x, attach_y)
    if attach_x ~= nil then self.attached_x = attach_x else self.attached_x = true end
    if attach_y ~= nil then self.attached_y = attach_y else self.attached_y = true end
end

---@private
function Camera:updateAttached()
    local target_x, target_y = self:getTargetPosition()

    if not self.attached_x then target_x = self.x end
    if not self.attached_y then target_y = self.y end

    self:moveTo(target_x, target_y)
end

---@private
function Camera:endAttached()
    self.attached_x = false
    self.attached_y = false
end

---@private
function Camera:updatePanning()
    if not self.pan_target then
        self:setState("STATIC")
        return
    end

    local min_x, min_y = self:getMinPosition()
    local max_x, max_y = self:getMaxPosition()

    local pan_x = self.pan_target.x and Utils.clamp(self.pan_target.x, min_x, max_x) or self.x
    local pan_y = self.pan_target.y and Utils.clamp(self.pan_target.y, min_y, max_y) or self.y

    if self.pan_target.time then
        self.pan_target.timer = Utils.approach(self.pan_target.timer, self.pan_target.time, DT)

        if self.pan_target.x then
            self.x = Utils.ease(self.pan_target.start_x, pan_x, self.pan_target.timer / self.pan_target.time, self.pan_target.ease)
        end
        if self.pan_target.y then
            self.y = Utils.ease(self.pan_target.start_y, pan_y, self.pan_target.timer / self.pan_target.time, self.pan_target.ease)
        end
    else
        self:approach(pan_x, pan_y, self.pan_target.speed * DTMULT)
    end

    if self.x == pan_x and self.y == pan_y then
        local after = self.pan_target.after

        self.pan_target = nil

        self:setState("STATIC")

        if after then
            after()
        end
    end
end

---@param px number
---@param py number
---@param ox? number
---@param oy? number
---@return number x, number y
function Camera:getParallax(px, py, ox, oy)
    local x, y, w, h = self:getRect(false)

    local parallax_x, parallax_y

    if ox then
        parallax_x = (x - (ox - w/2)) * (1 - px)
    else
        parallax_x = x * (1 - px)
    end

    if oy then
        parallax_y = (y - (oy - h/2)) * (1 - py)
    else
        parallax_y = y * (1 - py)
    end

    return parallax_x, parallax_y
end

---@param transform love.Transform
---@param ceil_x? number
---@param ceil_y? number
function Camera:applyTo(transform, ceil_x, ceil_y)
    if self.rotation ~= 0 then
        transform:translate(self.width/2, self.height/2)
        transform:rotate(self.rotation)
        transform:translate(-self.width/2, -self.height/2)
    end

    transform:scale(self.zoom_x, self.zoom_y)

    local x, y = self:getOffsetPos()

    local tw = self.width / self.zoom_x / 2
    local th = self.height / self.zoom_y / 2

    local tx = -x + tw
    local ty = -y + th

    if ceil_x then
        tx = Utils.ceil(tx, ceil_x / self.zoom_x)
        ty = Utils.ceil(ty, ceil_y / self.zoom_y)
    end

    transform:translate(tx, ty)
end

---@return love.Transform
function Camera:getTransform()
    local transform = love.math.newTransform()
    self:applyTo(transform)
    return transform
end

function Camera:canDeepCopy()
    return true
end
function Camera:canDeepCopyKey(key)
    return key ~= "parent"
end

return Camera