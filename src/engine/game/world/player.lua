--- The character controlled by the player when in the Overworld.
---@class Player : Character, StateManagedClass
---@overload fun(chara: string|Actor, x?: number, y?: number) : Player
local Player, super = Class(Character)

function Player:init(chara, x, y)
    super.init(self, chara, x, y)

    self.is_player = true

    self.slide_sound = Assets.newSound("paper_surf")
    self.slide_sound:setLooping(true)

    self.charge_sound = Assets.newSound("chargeshot_charge")
    self.charge_sound:setLooping(true)

    self.state_manager = StateManager("WALK", self, true)
    self.state_manager:addState("WALK", { update = self.updateWalk })
    self.state_manager:addState("SLIDE", { update = self.updateSlide, enter = self.beginSlide, leave = self.endSlide })
    self.state_manager:addState("CLIMB_MOUNT", { postJump = self.postJumpClimbMount, enter = self.beginClimbMount })
    self.state_manager:addState("CLIMB", { update = self.updateClimb, enter = self.beginClimb , leave = self.endClimb })
    self.state_manager:addState("CLIMB_EXIT", { update = self.updateClimbExit, enter = self.beginClimbExit, leave = self.endClimbExit })

    self.force_run = false
    self.force_walk = false
    self.run_timer = 0
    self.run_timer_grace = 0

    self.auto_moving = false

    self.current_slide_area = nil
    self.slide_in_place = false
    self.slide_lock_movement = false
    self.slide_dust_timer = 0
    self.slide_land_timer = 0

    self.hurt_timer = 0

    self.moving_x = 0
    self.moving_y = 0

    self.last_move_x = self.x
    self.last_move_y = self.y

    self.history_time = 0
    self.history = {}

    self.interact_buffer = 0

    self.battle_alpha = 0

    self.persistent = true
    self.noclip = false

    local outlinefx = BattleOutlineFX()
    outlinefx:setAlpha(self.battle_alpha)

    self.outlinefx = self:addFX(outlinefx)

    self.force_climb = false
    self.climb_exit_direction = nil

    self.climb_mount_target_x = 0
    self.climb_mount_target_y = 0

    self:resetClimbState()

    self._draw_reticle = false

    self.climb_hurtbox = Hitbox(self, 3, 3, 14, 14)

    self.climb_exit_landing = false
    self.climb_exit_target_x = 0
    self.climb_exit_target_y = 0

    self.climb_exit_timer = 0

    self.follower_tweens = {}

    self.climbing_x_dir = 0
    self.climbing_y_dir = -1
end

function Player:resetClimbState()

    self.climb_momentum = 0
    self.climb_speed = 1

    -- Input buffers for climbing
    self.climb_up_buffer = 0
    self.climb_down_buffer = 0
    self.climb_left_buffer = 0
    self.climb_right_buffer = 0
    self.climb_jump_buffer = 0
    self.climb_cancel_buffer = 0

    self.climb_direction = "down"
    self.climb_held_direction = nil
    self.climb_recently_bumped = nil
    self.climb_previous_bump = nil

    self.climb_jumping = false
    self.climb_neutral_state = 1 -- 0 = In other state, 1 = Can start moving/start charging
    self.climb_grab_state = 0
    self.climb_bump_state = 0
    self.climb_fall_state = 0
    self.climb_charge_state = 0
    self.climb_recover_state = 0

    self.climb_can_jump = true
    self.climb_can_grab = true
    self.climb_can_recover = true

    self.climb_fall_timer = 0
    self.climb_fall_max_speed = 10
    self.climb_fall_direction = "down"

    self.climb_camera_y_offset = -80

    self.last_climb_x = self.x
    self.last_climb_y = self.y

    self.last_safe_climb_x = self.x
    self.last_safe_climb_y = self.y

    self.climb_grab_timer = 0

    self.climb_grab_start_x = self.x
    self.climb_grab_start_y = self.y

    self.climb_dust_timer = 0
    self.climb_grab_sound_timer = 0

    self.climb_frame = 1

    self.climb_charge_timer = 0
    self.climb_charge_afterimage_timer = 0
    self.climb_charge_amount = 1

    self.climb_charge_time_1 = 10
    self.climb_charge_time_2 = 22

    self.climb_bump_sprite = "climb/slip_left"

    self.climb_bump_timer = 0

    self.climb_state = 0

    self.climb_use_input = nil
    self.cancelled_climb_bump = false

    self.climb_cut_timer = 0

    self.climb_afterimage_timer = 0

    self.climb_exit_landing = false
    self.climb_exit_target_x = 0
    self.climb_exit_target_y = 0

    self.climb_exit_timer = 0
    self.climb_exiting = false

    -- Initialized to false in DR! Unused, though. (checkdamagefloor)
    self.check_climb_move = true

    self.climb_attack_flash = false
    self.climb_attack_flash_time = 0
end

function Player:getBaseWalkSpeed()
    return Game:isLight() and 6 or 4
end

function Player:getCurrentSpeed(running)
    local speed = self:getBaseWalkSpeed()
    if running then
        if self.run_timer > 60 then
            speed = speed + (Game:isLight() and 6 or 5)
        elseif self.run_timer > 10 then
            speed = speed + 4
        else
            speed = speed + 2
        end
    end
    return speed
end

function Player:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "State: " .. self.state_manager.state)

    if self.state_manager.state == "SLIDE" then
        table.insert(info, "Slide in place: " .. (self.slide_in_place and "True" or "False"))
    elseif self.state_manager.state == "CLIMB" then
        table.insert(info, "Force climb: " .. (self.force_climb and "True" or "False"))
        table.insert(info, "Can jump: " .. (self.climb_can_jump and "True" or "False"))
        table.insert(info, string.format("Direction: %s, (%s, %s)", self.climb_direction, self.climbing_x_dir, self.climbing_y_dir))
        table.insert(info, "Momentum: " .. self.climb_momentum)
    elseif self.state_manager.state == "WALK" then
        table.insert(info, "Walk speed: " .. self:getBaseWalkSpeed())
        table.insert(info, "Current walk speed: " .. self:getCurrentSpeed(false))
        table.insert(info, "Current run speed: " .. self:getCurrentSpeed(true))
        table.insert(info, "Run timer: " .. self.run_timer)
        table.insert(info, "Hurt timer: " .. self.hurt_timer)
        table.insert(info, "Force run: " .. (self.force_run and "True" or "False"))
        table.insert(info, "Force walk: " .. (self.force_walk and "True" or "False"))
    end

    return info
end

function Player:getDebugOptions(context)
    context = super.getDebugOptions(self, context)

    if self.state_manager.state == "WALK" then
        context:addMenuItem(
            "Toggle force run", "Toggle if the player is forced to run or not",
            function() self.force_run = not self.force_run end
        )
        context:addMenuItem(
            "Toggle force walk", "Toggle if the player is forced to walk or not",
            function() self.force_walk = not self.force_walk end
        )
    elseif self.state_manager.state == "CLIMB" then
        context:addMenuItem(
            "Toggle force climb", "Toggle if the player is forced to climb or not",
            function() self.force_climb = not self.force_climb end
        )
    end

    if self.state_manager.state ~= "CLIMB" then
        context:addMenuItem(
            "Start climbing", "Start climbing where the player currently is.",
            function() self:setState("CLIMB") end
        )
    end

    if self.state_manager.state ~= "WALK" then
        context:addMenuItem(
            "Start walking", "Start walking where the player currently is.",
            function() self:setState("WALK") end
        )
    end

    if self.state_manager.state ~= "SLIDE" then
        context:addMenuItem(
            "Start sliding", "Start sliding where the player currently is.",
            function() self:setState("SLIDE") end
        )
    end

    return context
end

---@param parent World
function Player:onAdd(parent)
    super.onAdd(self, parent)

    if parent:includes(World) and not parent.player then
        parent.player = self
    end
end

---@param parent World
function Player:onRemove(parent)
    super.onRemove(self, parent)

    self.slide_sound:stop()
    self.charge_sound:stop()
    if parent:includes(World) and parent.player == self then
        parent.player = nil
    end
end

function Player:onRemoveFromStage(stage)
    super.onRemoveFromStage(self, stage)
    self.slide_sound:stop()
    self.charge_sound:stop()
end

function Player:setActor(actor)
    super.setActor(self, actor)

    local hx, hy, hw, hh = self.collider.x, self.collider.y, self.collider.width, self.collider.height

    self.interact_collider = {
        ["left"] = Hitbox(self, hx - 13, hy, hw / 2 + 13, hh),
        ["right"] = Hitbox(self, hx + hw / 2, hy, hw / 2 + 13, hh),
        ["up"] = Hitbox(self, hx, hy - 19, hw, hh / 2 + 19),
        ["down"] = Hitbox(self, hx, hy + hh / 2, hw, hh / 2 + 14)
    }
end

function Player:interact()
    if self.interact_buffer > 0 then
        return true
    end

    local col = self.interact_collider[self:getFacing()]

    Object.startCache()
    local interactables = {}
    for _, obj in ipairs(self.world.children) do
        if obj.onInteract and obj:collidesWith(col) then
            local rx, ry = obj:getRelativePos(obj.width / 2, obj.height / 2, self.parent)
            table.insert(interactables, { obj = obj, dist = MathUtils.dist(self.x, self.y, rx, ry) })
        end
    end
    Object.endCache()

    table.sort(interactables, function(a, b) return a.dist < b.dist end)
    for _, v in ipairs(interactables) do
        if v.obj:onInteract(self, self:getFacing()) then
            self.interact_buffer = v.obj.interact_buffer or 0
            return true
        end
    end

    return false
end

function Player:setState(state, ...)
    self.state_manager:setState(state, ...)
end

function Player:resetFollowerHistory()
    for _, follower in ipairs(Game.world.followers) do
        if follower:getTarget() == self then
            follower:copyHistoryFrom(self)
        end
    end
end

--- Aligns the player's followers' directions and positions.
---@param facing?   string  The direction every character should face (Defaults to player's direction)
---@param x?        number  The x-coordinate of the 'front' of the line. (Defaults to player's x-position)
---@param y?        number  The y-coordinate of the 'front' of the line. (Defaults to player's y-position)
---@param dist?     number  The distance between each follower.
function Player:alignFollowers(facing, x, y, dist)
    facing = facing or self:getFacing()
    x, y = x or self.x, y or self.y

    local offset_x, offset_y = 0, 0
    if facing == "left" then
        offset_x = 1
    elseif facing == "right" then
        offset_x = -1
    elseif facing == "up" then
        offset_y = 1
    elseif facing == "down" then
        offset_y = -1
    end

    self.history = { { x = x, y = y, time = self.history_time } }
    for i = 1, Game.max_followers do
        local idist = dist and (i * dist) or (((i * FOLLOW_DELAY) / (1 / 30)) * 4)
        table.insert(
            self.history,
            {
                x = x + (offset_x * idist),
                y = y + (offset_y * idist),
                facing = facing,
                time = self.history_time - (i * FOLLOW_DELAY)
            }
        )
    end
    self:resetFollowerHistory()
end

--- Adds all followers' current positions to their movement history.
function Player:interpolateFollowers()
    for i, follower in ipairs(Game.world.followers) do
        if follower:getTarget() == self then
            follower:interpolateHistory()
        end
    end
end

function Player:isCameraAttachable()
    if self.state_manager.state == "CLIMB" then
        return false
    end

    if self.state_manager.state == "CLIMB_MOUNT" then
        return false
    end

    if self.state_manager.state == "CLIMB_EXIT" then
        return false
    end

    if self.state_manager.state == "SLIDE" and self.slide_in_place then
        return false
    end

    return true
end

function Player:isMovementEnabled()
    return not OVERLAY_OPEN
        and not Game.lock_movement
        and not self.slide_lock_movement
        and Game.state == "OVERWORLD"
        and self.world.state == "GAMEPLAY"
        and self.hurt_timer == 0
        and Game.world.door_delay == 0
end

function Player:handleMovement()
    local walk_x = 0
    local walk_y = 0

    if Input.down("left") then
        walk_x = walk_x - 1
    elseif Input.down("right") then
        walk_x = walk_x + 1
    end

    if Input.down("up") then
        walk_y = walk_y - 1
    elseif Input.down("down") then
        walk_y = walk_y + 1
    end

    self.moving_x = walk_x
    self.moving_y = walk_y

    local running = (Input.down("cancel") or self.force_run) and not self.force_walk
    if Kristal.Config["autoRun"] and not self.force_run and not self.force_walk then
        running = not running
    end

    if self.force_run and not self.force_walk then
        self.run_timer = 200
    end

    local speed = self:getCurrentSpeed(running)

    self:move(walk_x, walk_y, speed * DTMULT)

    if not running or self.last_collided_x or self.last_collided_y then
        self.run_timer = 0
    elseif running then
        if walk_x ~= 0 or walk_y ~= 0 then
            self.run_timer = self.run_timer + DTMULT
            self.run_timer_grace = 0
        else
            -- Dont reset running until 2 frames after you release the movement keys
            if self.run_timer_grace >= 2 then
                self.run_timer = 0
            end
            self.run_timer_grace = self.run_timer_grace + DTMULT
        end
    end
end

function Player:updateWalk()
    if self:isMovementEnabled() then
        self:handleMovement()
    end
end

function Player:onMapLoad()
    if self:isClimbing() then
        self:cancelFollowerTweens()
        for _, follower in ipairs(Game.world.followers) do
            follower.alpha = 0
            follower.visible = false
        end
    end
end

function Player:isMoving()
    return self.moving_x ~= 0 or self.moving_y ~= 0
end

function Player:isClimbing()
    return self.state_manager.state == "CLIMB"
end

function Player:isClimbJumping()
    return self:isClimbing() and self.climb_jumping and self.climb_state == 2
end

function Player:beginSlide(last_state, in_place, lock_movement)
    self.slide_sound:play()
    self.auto_moving = true
    self.slide_in_place = in_place or false
    self.slide_lock_movement = lock_movement or false
    self.slide_land_timer = 0
    self.sprite:setAnimation("slide")
end

function Player:updateSlideDust()
    self.slide_dust_timer = self.slide_dust_timer - DTMULT

    if self.slide_dust_timer <= 0 then
        self.slide_dust_timer = self.slide_dust_timer + 3

        local dust = Sprite("effects/slide_dust")
        dust:play(1 / 15, false, function() dust:remove() end)
        dust:setOrigin(0.5, 0.5)
        dust:setScale(2, 2)
        dust:setPosition(self.x, self.y)
        dust.layer = self.layer - 0.01
        dust.physics.speed_y = -6
        dust.physics.speed_x = MathUtils.random(-1, 1)
        dust.debug_select = false
        self.world:addChild(dust)
    end
end

function Player:updateSlide()
    local slide_x = 0
    local slide_y = 0

    if self:isMovementEnabled() then
        if Input.down("right") then slide_x = slide_x + 1 end
        if Input.down("left") then slide_x = slide_x - 1 end
        if Input.down("down") then slide_y = slide_y + 1 end
        if Input.down("up") then slide_y = slide_y - 1 end
    end

    if not self.slide_in_place then
        slide_y = 2
    end

    self.run_timer = 50
    local speed = self:getBaseWalkSpeed() + 4

    self:move(slide_x, slide_y, speed * DTMULT)

    self:updateSlideDust()
end

function Player:endSlide(next_state)
    if self.slide_lock_movement then
        self.slide_land_timer = 4
    else
        self.slide_sound:stop()
        self.sprite:resetSprite()
    end
    self.auto_moving = false
end

function Player:cancelFollowerTweens()
    for _, tween in ipairs(self.follower_tweens) do
        Game.world.timer:cancel(tween)
    end
    self.follower_tweens = {}
end

function Player:beginClimbMount(last_state, target_x, target_y, exit_direction)
    Game.lock_movement = true

    Game.world:detachFollowers()

    self.climb_mount_target_x = target_x
    self.climb_mount_target_y = target_y

    self.climb_exit_direction = exit_direction

    self:jumpTo(target_x, target_y + self:getScaledHeight() / 2, 8, 8 / 30, "jump_ball_slow")

    self:cancelFollowerTweens()

    for _, follower in ipairs(Game.world.followers) do
        follower.alpha = 1
        follower.visible = true
        table.insert(self.follower_tweens, Game.world.timer:tween(7 / 30, follower.color, { [1] = 0.5, [2] = 0.5, [3] = 0.5 }))
        table.insert(self.follower_tweens, Game.world.timer:tween(7 / 30, follower, { alpha = 0 }))
    end

    Assets.playSound("wing")

    -- Calculate auto direction based on target position and current position
    local x_diff = target_x - self.x
    local y_diff = target_y - self.y

    local climb_x = MathUtils.sign(x_diff)
    local climb_y = MathUtils.sign(y_diff)

    if climb_x ~= 0 and climb_y ~= 0 then
        -- Figure out which one went further
        if math.abs(x_diff) > math.abs(y_diff) then
            climb_y = 0
        else
            climb_x = 0
        end
    end

    if climb_x == 0 and climb_y == 0 then
        climb_y = -1
    end

    self.climbing_x_dir = climb_x
    self.climbing_y_dir = climb_y
end

function Player:postJumpClimbMount()
    Assets.playSound("noise")

    self.x = self.climb_mount_target_x
    self.y = self.climb_mount_target_y

    Game.lock_movement = false
    self:setState("CLIMB")

    if self.climb_exit_direction ~= nil then
        self.climbing_x_dir = 0
        self.climbing_y_dir = 0

        if self.climb_exit_direction == "up" then
            self.climbing_y_dir = 1
        elseif self.climb_exit_direction == "left" then
            self.climbing_x_dir = 1
        elseif self.climb_exit_direction == "right" then
            self.climbing_x_dir = -1
        elseif self.climb_exit_direction == "down" then
            self.climbing_y_dir = -1
        end
    end
end

function Player:queueClimbExit(settings)
    self.climb_exiting = true
    self.climb_exit_settings = settings
    self.climb_neutral_state = -1
    self.climb_state = -1
    self.climb_charge_state = -1
    self.climb_fall_state = -1
    self.climb_grab_state = -1
    self.climb_timer = 0
    self.climb_afterimage_timer = 0
end

function Player:beginClimb(last_state)
    self.sprite:setSprite("climb/climbing")

    self:setSize(20, 20)
    self:setOrigin(0.5, 0.5)
    self.collider = Hitbox(self, 0, 0, 20, 20)

    self:resetClimbState()

    -- If we're entering the climb state, and the followers aren't already invisible, fade them out
    self:cancelFollowerTweens()
    for _, follower in ipairs(Game.world.followers) do
        if follower.alpha > 0 then
            table.insert(self.follower_tweens, Game.world.timer:tween(7 / 30, follower.color, { [1] = 0.5, [2] = 0.5, [3] = 0.5 }))
            table.insert(self.follower_tweens, Game.world.timer:tween(7 / 30, follower, { alpha = 0 }))
        end
    end
end

--- A (somewhat hacky) method to check if an object is overlapping the player, without counting perfectly overlapping edges.
---
---@param obj Object The class of object to check for overlap with.
---@return boolean is_overlapping
function Player:isOverlappingInstance(obj)
    local obj_left, obj_top = obj:localToScreenPos(0, 0)
    local obj_right, obj_bottom = obj:localToScreenPos(obj.width, obj.height)

    local player_left, player_top = self:localToScreenPos(0, 0)
    local player_right, player_bottom = self:localToScreenPos(self.width, self.height)

    return player_right > obj_left and player_left < obj_right and player_bottom > obj_top and player_top < obj_bottom
end

--- A (somewhat hacky) method to check for any world objects overlapping the player, without counting perfectly overlapping edges.
---
---@generic T : Object
---@param x? number The x position to check for overlap. Defaults to the player's current x position.
---@param y? number The y position to check for overlap. Defaults to the player's current y position.
---@param object T The class of object to check for overlap with.
---@return T[] objects A list of objects that are overlapping the player.
function Player:getOverlappingObjects(x, y, object)
    x = x or self.x
    y = y or self.y

    local old_x = self.x
    local old_y = self.y

    self.x = x
    self.y = y

    local objects = {}

    Object.startCache()
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(object) then
            if self:isOverlappingInstance(obj) then
                table.insert(objects, obj)
            end
        end
    end

    Object.endCache()

    self.x = old_x
    self.y = old_y
    return objects
end

--- A (somewhat hacky) method to check if the player is overlapping a world object's bounds, without counting perfectly overlapping edges.
---
---@generic T : Object
---@param x? number The x position to check for overlap. Defaults to the player's current x position.
---@param y? number The y position to check for overlap. Defaults to the player's current y position.
---@param object T The class of object to check for overlap with.
---@return boolean is_overlapping
---@return T? object The object that the player is overlapping, if any.
---@overload fun(x: number, y: number, object: T): (true, Event)
function Player:isOverlappingObjectBounds(x, y, object)

    local overlapping_objects = self:getOverlappingObjects(x, y, object)
    if #overlapping_objects > 0 then
        return true, overlapping_objects[1]
    else
        return false, nil
    end
end

--- A (somewhat hacky) method to check if the player is overlapping a ClimbArea, or a child of ClimbArea, without counting perfectly overlapping edges.
---
---@generic T : ClimbArea
---@param x? number The x position to check for overlap. Defaults to the player's current x position.
---@param y? number The y position to check for overlap. Defaults to the player's current y position.
---@param object T The class of object to check for overlap with.
---@return boolean is_overlapping
---@return T? object The object that the player is overlapping, if any.
---@overload fun(x: number, y: number, object: T): (true, Event)
function Player:isOverlappingClimbable(x, y, object)

    local overlapping_objects = self:getOverlappingObjects(x, y, object)

    for i, obj in ipairs(overlapping_objects) do
        if obj:isClimbable() then
            return true, obj
        end
    end

    return false, nil
end

---@class ClimbFallSettings
---@field direction "up"|"down"|"left"|"right"? The direction the player falls. Defaults to "down".
---@field recover_from_fall boolean? Whether the player should be teleported back to the last safe position after falling. Defaults to true.
---@field max_speed number? The maximum speed the player can reach while falling. Defaults to 10.

---@param time integer The amount of time (in frames) that it takes the player to attempt to re-grab the wall. Defaults to 20. Common values are 10, 15, 20, 24, 30, 34, and 80.
---@param settings ClimbFallSettings? The settings for the climb fall. Optional.
function Player:climbFall(time, settings)
    settings = settings or {}
    self.climb_fall_state = 1
    self.climb_fall_timer = time or 20
    self.climb_fall_direction = settings.direction or "down"
    self.climb_fall_max_speed = settings.max_speed or 10
    self.climb_can_recover = settings.recover_from_fall ~= false
end

--- *(Called internally)* Cuts a climb bump short if the player changes directions or attempts to jump.
---
--- This should not be called by user code.
---@private
function Player:shortenClimbBump()
    local changing_directions = (self.climb_use_input ~= nil) and (self.last_climb_direction ~= self.climb_use_input)
    local attempting_jump = (self.climb_jump_buffer > 0) and (self.climb_cancel_buffer == 0)

    if self.climb_bump_state == 2 -- If the player is bumping,
        and (self.climb_bump_timer > 2) -- And it's early enough in the bump,
        and (not self.cancelled_climb_bump) -- And the bump hasn't been cancelled,
        and (self.climb_neutral_state ~= 1) -- And we're not in normal movement,
        and (changing_directions or attempting_jump) then -- And we're either changing directions, or attempting to jump,

        -- ...then shorten the bump timer so we can get back to normal movement sooner.
        self.climb_bump_timer = math.min(self.climb_bump_timer, 2)
        self.climb_momentum = 0
        self.climb_speed = 1
    end
end

function Player:handleClimbInput()
    local directions = {}
    local buffer_length = math.min(math.ceil(5 - (self.climb_momentum * 2)), 4)

    self.climb_afterimage_timer = self.climb_afterimage_timer + DTMULT

    if ((self:isMovementEnabled() and (Input.down("up") or self.climb_up_buffer > 0)) or self.force_climb) then
        if (Input.down("up") and (self.climb_direction ~= "up")) then
            self.climb_up_buffer = buffer_length
            self.climb_left_buffer = 0
            self.climb_right_buffer = 0
            self.climb_down_buffer = 0
        end
        table.insert(directions, "up")
    end

    if ((self:isMovementEnabled() and (Input.down("down") or self.climb_down_buffer > 0)) and (not self.force_climb)) then
        if (Input.down("down") and (self.climb_direction ~= "down")) then
            self.climb_up_buffer = 0
            self.climb_left_buffer = 0
            self.climb_right_buffer = 0
            self.climb_down_buffer = buffer_length
        end
        table.insert(directions, "down")
    end

    if ((self:isMovementEnabled() and (Input.down("right") or self.climb_right_buffer > 0)) and (not self.force_climb)) then
        if (Input.down("right") and (self.climb_direction ~= "right")) then
            self.climb_up_buffer = 0
            self.climb_left_buffer = 0
            self.climb_right_buffer = buffer_length
            self.climb_down_buffer = 0
        end
        table.insert(directions, "right")
    end

    if ((self:isMovementEnabled() and (Input.down("left") or self.climb_left_buffer > 0)) and (not self.force_climb)) then
        if (Input.down("left") and (self.climb_direction ~= "left")) then
            self.climb_up_buffer = 0
            self.climb_left_buffer = buffer_length
            self.climb_right_buffer = 0
            self.climb_down_buffer = 0
        end
        table.insert(directions, "left")
    end

    local num_inputs = #directions
    self.climb_use_input = nil
    self.cancelled_climb_bump = false

    if num_inputs == 0 then
        self.climb_held_direction = nil
    elseif (num_inputs == 1) or (self.climb_held_direction == nil) then
        self.climb_held_direction = directions[1]
        self.climb_use_input = self.climb_held_direction
    else
        for i = 1, #directions do
            local dir = directions[i]
            if (dir == self.climb_held_direction) or (dir == self.climb_recently_bumped) then
                self.cancelled_climb_bump = self.cancelled_climb_bump or (dir == self.climb_recently_bumped)
                table.remove(directions, i)
                i = i - 1
            end
        end

        if (#directions > 0) then
            self.climb_use_input = directions[1]
            self.cancelled_climb_bump = self.climb_use_input == self.climb_previous_bump
        elseif ((self.climb_held_direction ~= self.climb_previous_bump) and (self.climb_held_direction ~= self.climb_recently_bumped)) then
            self.climb_use_input = self.climb_held_direction
            self.cancelled_climb_bump = false
        else
            self.climb_use_input = self.climb_held_direction
            self.cancelled_climb_bump = true
        end
    end

    self.last_climb_direction = self.climb_direction

    if (not self.climb_jumping) then
        if (self.climb_use_input ~= nil) and ((self.climb_neutral_state == 1) or (self.climb_grab_state > 0) or (self.climb_bump_state == 2) or (self.climb_charge_state > 0)) then
            self.climb_direction = self.climb_use_input
        end
    end

    if (self.climb_can_jump) then
        if (Input.down("confirm") and (not self.force_climb) and (not self.climb_force_release_jump)) then
            if (self.climb_jump_buffer < 2) then
                self.climb_jump_buffer = 2
            end
        end

        if Input.pressed("confirm") and (not self.force_climb) then
            if (self.climb_jump_buffer < 3) then
                self.climb_jump_buffer = 3
                self.climb_cancel_buffer = 0
            end
        end

        if not Input.down("confirm") then
            self.climb_force_release_jump = false
        end
    else
        self.climb_jump_buffer = 0
        self.climb_cancel_buffer = 0
    end
end

--- *(Called internally)* Initializes the climb charge state.
---
--- To enter the climb charging state, set `self.climb_charge_state` to 1.
---
--- This should not be called by user code.
---@private
function Player:initClimbCharge()
    -- Reset climb momentum
    self.climb_momentum = 0

    -- Save our last X and Y
    self.x = self.last_climb_x
    self.y = self.last_climb_y

    self.charge_sound:seek(0)
    self.charge_sound:setPitch(0.4)
    self.charge_sound:setVolume(0.3)
    self.charge_sound:play()
    self.sprite:setSprite("climb/charge")
    self.sprite:setFrame(0)

    self.climb_charge_timer = 0
    self.climb_charge_afterimage_timer = 0
    self.climb_charge_amount = 1
    self.climb_charge_state = 2
end

--- *(Called internally)* Cancels the climb charge state.
---
--- This should not be called by user code.
---@private
function Player:cancelClimbCharge()
    -- We're trying to cancel the jump
    Assets.playSound("voice/toriel", 0.7, 0.4)
    Assets.playSound("voice/alphys", 0.7, 0.4)
    Assets.playSound("dtrans_heavypassing", 0.2, 1.8)

    self.climb_cancel_buffer = 10
    self.climb_charge_state = 0
    self.climb_charge_timer = 0
    self.climb_neutral_state = 1
    self:setColor(COLORS.white)
    self.charge_sound:stop()
end

--- *(Called internally)* Updates the climb charge state, charging the jump.
---
--- This happens every frame while `climb_charge_state` is 2 and the user is holding Z.
---
--- This should not be called by user code.
---@private
function Player:chargeClimbCharge()
    if self.climb_direction == "up" or self.climb_direction == "down" then
        self.sprite:setSprite("climb/charge")
    elseif self.climb_direction == "right" then
        self.sprite:setSprite("climb/charge_right")
    elseif self.climb_direction == "left" then
        self.sprite:setSprite("climb/charge_left")
    end

    self.climb_charge_timer = self.climb_charge_timer + DTMULT
    self.climb_charge_afterimage_timer = self.climb_charge_afterimage_timer + DTMULT

    if self.climb_charge_timer >= self.climb_charge_time_1 then
        self.sprite:setFrame(2)
        self.charge_sound:setPitch(0.5)
        self.climb_charge_amount = 2
        self:setColor(ColorUtils.mergeColor(COLORS.white, COLORS.teal, 0.2 + (math.floor(math.sin(self.climb_charge_timer / 2)) * 0.2)))
    end

    if self.climb_charge_timer >= self.climb_charge_time_2 then
        self.sprite:setFrame(3)
        self.charge_sound:setPitch(0.7)
        self.climb_charge_amount = 3
        self:setColor(ColorUtils.mergeColor(COLORS.white, COLORS.teal, 0.4 + (math.floor(math.sin(self.climb_charge_timer)) * 0.4)))

        if self.climb_charge_afterimage_timer >= 8 then
            local afterimage = self.parent:addChild(Sprite(self.sprite:getTexture(), self.x, self.y))
            afterimage.alpha = 0.3
            afterimage:setScale(2)
            afterimage:fadeOutSpeedAndRemove(0.1)
            afterimage:setOrigin(0.5)
            afterimage.layer = self.layer + 20
            local scale_x, scale_y = self:getScale()
            afterimage.graphics.grow_x = 0.2 / scale_x
            afterimage.graphics.grow_y = 0.2 / scale_y
        end
    end

    if self.climb_charge_afterimage_timer >= 8 then
        self.climb_charge_afterimage_timer = self.climb_charge_afterimage_timer - 8
    end
end

--- *(Called internally)* Finishes the climb charge state, performing the jump.
---
--- This should not be called by user code.
---@private
function Player:finishClimbCharge()
    self.climb_charge_state = 0
    self.climb_jumping = true
    self.climb_state = 1
    self:setColor(COLORS.white)
    self.charge_sound:stop()
end

--- *(Called internally)* Updates the climb charge state.
---
--- This function calls every frame while `climb_charge_state` is 2.
---
--- This should not be called by user code.
---@private
function Player:updateClimbCharge()
    if Input.pressed("cancel") then
        self:cancelClimbCharge()
    elseif self.climb_jump_buffer >= 2 or self.climb_charge_timer < 3 then
        self:chargeClimbCharge()
    else
        -- Not holding jump anymore, so let's actually jump
        self:finishClimbCharge()
    end
end

--- *(Called internally)* Handles climb charging logic.
---
--- This should not be called by user code.
---@private
function Player:handleClimbCharge()
    if self.climb_charge_state > 0 then
        if self.climb_charge_state == 1 then
            self:initClimbCharge()
        end

        if self.climb_charge_state == 2 then
            self:updateClimbCharge()
        end
    end
end

--- *(Called internally)* Checks the player's hurtbox against all bullets, and applies damage if necessary.
---
--- This should not be called by user code.
---@private
function Player:checkClimbBullets()
    if Game.world.soul ~= nil and Game.world.soul.inv_timer <= 0 and self:isMovementEnabled() then
        Object.startCache()
        for _, bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
            if bullet:collidesWith(self.climb_hurtbox) then
                if bullet:includes(ClimbEnemy) then
                    ---@cast bullet ClimbEnemy
                    if bullet:isActive() and not self:isClimbJumping() then
                        Game.world.soul:onCollide(bullet)
                    end
                else
                    Game.world.soul:onCollide(bullet)
                end
            end
        end
        Object.endCache()
    end
end

--- *(Called internally)* Checks the player's climb hitbox against any collidable objects.
---
--- If a ClimbEnemy is found, and the player is jumping, the enemy will be attacked.
---
--- This should not be called by user code.
---@private
function Player:checkClimbCollisions()
    if self:isMovementEnabled() then
        local collided = {}
        local exited = {}

        Object.startCache()
        for _, obj in ipairs(Game.world.children) do
            if obj:collidesWith(self) then
                if obj:includes(ClimbEnemy) then
                    ---@cast obj ClimbEnemy
                    if obj:isActive() and self:isClimbJumping() then
                        Assets.playSound("noise")
                        self.climb_state = 10
                        self.climb_cut_timer = 0
                        obj:onJumpAttack(self)
                    end
                else
                    if not obj:includes(OverworldSoul) then
                        table.insert(collided, obj)
                    end
                end
            elseif obj.player_colliding then
                table.insert(exited, obj)
            end
        end
        Object.endCache()

        for _, obj in ipairs(collided) do
            if obj.onCollide then
                obj:onCollide(self)
            end

            if not obj.player_colliding then
                if obj.onEnter then
                    obj:onEnter(self)
                end
                obj.player_colliding = true
            end
        end
        for _, v in ipairs(exited) do
            if v.onExit then
                v:onExit(self)
            end
            v.player_colliding = false
        end
    end
end

--- *(Called internally)* Initializes the climb falling state.
---
--- To enter the climb falling state, call `self:climbFall()` with the desired settings.
---
--- This should not be called by user code.
---@private
---@see Player.climbFall
function Player:initClimbFall()
    self.sprite:setSprite("climb/fall")
    self.sprite:setFrame(1)
    self.climb_fall_speed = 0
    self.climb_fall_state = 2
    self.climb_neutral_state = 0

    self.charge_sound:stop()

    self:setColor(1, 1, 1)
    self.climb_jumping = false
    self.climb_charge_state = 0
    self.climb_state = 0
    self.climb_momentum = 0
end

--- *(Called internally)* Checks for climb landings, and queues a climb exit if one is found.
---
--- This should not be called by user code.
---@private
function Player:checkClimbLandings()
    Object.startCache()
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(ClimbLanding) and self:collidesWith(obj) then
            self:queueClimbExit({ landing = true, obj = obj })
            break
        end
    end
    Object.endCache()
end

--- *(Called internally)* Updates the climb falling state.
---
--- This should not be called by user code.
---@private
function Player:updateClimbFall()
    self.climb_fall_speed = self.climb_fall_speed + 0.5 * DTMULT

    if (self.climb_fall_speed >= self.climb_fall_max_speed) then
        self.climb_fall_speed = self.climb_fall_max_speed
    end

    if (self.climb_fall_speed >= 20) and (self.climb_fall_direction == "down") then
        self.climb_camera_y_offset = math.min(self.climb_camera_y_offset + 2, 80)
    end

    if (self.climb_fall_direction == "down") then
        self.y = self.y + math.ceil(self.climb_fall_speed) * DTMULT
    elseif (self.climb_fall_direction == "right") then
        self.x = self.x + math.ceil(self.climb_fall_speed) * DTMULT
    elseif (self.climb_fall_direction == "up") then
        self.y = self.y - math.ceil(self.climb_fall_speed) * DTMULT
    elseif (self.climb_fall_direction == "left") then
        self.x = self.x - math.ceil(self.climb_fall_speed) * DTMULT
    end

    self.climb_fall_timer = self.climb_fall_timer - DTMULT

    if (self.climb_fall_timer <= 0) then
        if (self.climb_can_grab) then
            self.climb_grab_x = self.last_climb_x + (MathUtils.round((self.x - self.last_climb_x) / 40) * 40)
            self.climb_grab_y = self.last_climb_y + (MathUtils.round((self.y - self.last_climb_y) / 40) * 40)

            if self:isOverlappingClimbable(self.climb_grab_x, self.climb_grab_y, ClimbArea) then
                self.climb_grab_state = 1
                self.climb_direction = "down"
                self.climb_fall_state = 0
            end
        end

        local howlongfall = 660

        if self.climb_can_recover then
            if Game.world.camera then
                local x, y, w, h = Game.world.camera:getRect()

                if self.climb_fall_direction == "down" then
                    if (self.y >= y + h + howlongfall) then
                        self.climb_fall_state = 0
                        self.climb_recover_state = 1
                    end
                elseif self.climb_fall_direction == "up" then
                    if (self.y <= y - howlongfall) then
                        self.climb_fall_state = 0
                        self.climb_recover_state = 1
                    end
                elseif self.climb_fall_direction == "right" then
                    if self.x >= x + w + howlongfall then
                        self.climb_fall_state = 0
                        self.climb_recover_state = 1
                    end
                elseif self.climb_fall_direction == "left" then
                    if self.x <= x - howlongfall then
                        self.climb_fall_state = 0
                        self.climb_recover_state = 1
                    end
                end
            end
        end
    end
end

--- *(Called internally)* Handles climb falling logic.
---
--- This should not be called by user code.
---@private
function Player:handleClimbFall()
    if self.climb_fall_state > 0 then
        if self.climb_fall_state == 1 then
            self:initClimbFall()
        end

        if self.climb_fall_state == 2 then
            self:checkClimbLandings()
            self:updateClimbFall()
        end
    end
end

--- *(Called internally)* Initializes the climb grab state.
---
--- This should not be called by user code.
---@private
function Player:initClimbGrab()
    self.sprite:setSprite("climb/charge")
    self.sprite:setFrame(3)
    self.climb_grab_state = 2
    self.climb_grab_sound_timer = 0
    self.climb_dust_timer = 0
end

--- *(Called internally)* Updates the climb grab state.
---
--- In this state, the player just grabbed onto the wall, and are sliding down slowly until they stop.
---
--- This should not be called by user code.
---@private
function Player:updateClimbGrab()
    self.climb_grab_sound_timer = self.climb_grab_sound_timer + DTMULT
    self.climb_dust_timer = self.climb_dust_timer + DTMULT

    if self.climb_grab_sound_timer >= 1 then
        self.climb_grab_sound_timer = self.climb_grab_sound_timer - 1
        Assets.stopAndPlaySound("wing", 0.7, 0.6 + MathUtils.random(0.3))
    end

    if (self.climb_dust_timer >= 2) then
        self.climb_dust_timer = self.climb_dust_timer - 2

        local dust = Sprite("effects/slide_dust")
        dust:play(1 / 15, false, function() dust:remove() end)
        dust:setOrigin(0.5, 0.5)
        dust:setScale(2, 2)
        dust:setPosition(self.x, self.y)
        dust.layer = self.layer - 0.01
        dust.physics.speed_y = -3
        dust.physics.speed_x = MathUtils.random(-1, 1)
        dust.debug_select = false
        self.world:addChild(dust)
    end

    -- Cap climb speed to 7
    if (self.climb_fall_speed > 7) then
        self.climb_fall_speed = 7
    end

    self.climb_fall_speed = self.climb_fall_speed - DTMULT

    if self.climb_fall_direction == "down" then
        self.y = self.y + math.ceil(self.climb_fall_speed) * DTMULT
    elseif self.climb_fall_direction == "right" then
        self.x = self.x + math.ceil(self.climb_fall_speed) * DTMULT
    elseif self.climb_fall_direction == "up" then
        self.y = self.y - math.ceil(self.climb_fall_speed) * DTMULT
    elseif self.climb_fall_direction == "left" then
        self.x = self.x - math.ceil(self.climb_fall_speed) * DTMULT
    end

    if (self.climb_fall_speed <= 0) then
        self.climb_grab_timer = 0
        self.climb_grab_state = 3
        self.climb_grab_start_y = self.y
        self.climb_grab_start_x = self.x
    end
end

--- *(Called internally)* Updates the climb grab state.
---
--- In this state, the player has finished sliding down, and is easing back into position (on the grid).
---
--- This should not be called by user code.
---@private
function Player:updateClimbGrabEnd()
    self.climb_grab_timer = self.climb_grab_timer + DTMULT
    local initwait = 7
    local waittime = 8

    if self.climb_grab_timer >= initwait then
        local progress = (self.climb_grab_timer / waittime) - (initwait / waittime)
        self.y = Utils.ease(self.climb_grab_start_y, self.climb_grab_y, progress, "inOutCubic")
        self.x = Utils.ease(self.climb_grab_start_x, self.climb_grab_x, progress, "inOutCubic")
    end

    if self.climb_grab_timer >= (initwait + waittime) then
        self.x = MathUtils.round(self.x / 10) * 10
        self.y = MathUtils.round(self.y / 10) * 10

        self.climb_grab_state = 0
        self.climb_neutral_state = 1
        self.check_climb_move = true
    end
end

--- *(Called internally)* Handles climb grabbing logic.
---
--- This should not be called by user code.
---@private
function Player:handleClimbGrab()
    if self.climb_grab_state > 0 then
        if self.climb_grab_state == 1 then
            self:initClimbGrab()
        end

        if self.climb_grab_state == 2 then
            self:updateClimbGrab()
        end

        if self.climb_grab_state == 3 then
            self:updateClimbGrabEnd()
        end
    end
end

--- *(Called internally)* Updates the climb recover state, recovering the player back to the last safe position if they fell too far.
---
--- This should not be called by user code.
---@private
function Player:handleClimbRecover()
    if self.climb_recover_state > 0 then
        if self.climb_recover_state == 1 then
            Game.world:hurtParty(30)
        end

        if self.climb_recover_state >= 20 then
            self.x = self.last_safe_climb_x
            self.y = self.last_safe_climb_y
            self.climb_neutral_state = 1

            self.climb_recover_state = 0
        else
            self.climb_recover_state = self.climb_recover_state + DTMULT
        end
    end
end

--- *(Called internally)* Checks if the player is still in a climb area, and if not, initiates a climb fall.
---
--- This is not present in DELTARUNE, and is solely Kristal QOL.
---
--- This should not be called by user code.
---@private
function Player:checkClimbAreaExists()
    if self.climb_neutral_state == 1 and (not NOCLIP) then
        local found, obj = self:isOverlappingClimbable(self.x, self.y, ClimbArea)
        if not found then
            self:climbFall(20)
        end
    end
end

--- *(Called internally)* Handles "neutral" movement.
--- 
--- This function is responsible for:
--- - Updating the "last climb position"
--- - Updating the "last safe climb position"
--- - Starting a climb (by pressing a direction key)
--- - Starting a jump charge (by pressing Z)
--- - Slowing the player's momentum if nothing is being pressed,
--- - And checking for climb exits, and queuing them up if the player is pressing the exit direction.
---
--- This should not be called by user code.
---@private
function Player:handleClimbIdle()
    if self.climb_neutral_state == 1 then
        self.sprite:setSprite("climb/climbing")
        self.sprite:setFrame(self.climb_frame)
        self.last_climb_x = self.x
        self.last_climb_y = self.y

        if not self:isOverlappingObjectBounds(nil, nil, ClimbUnsafe) then
            self.last_safe_climb_x = self.x
            self.last_safe_climb_y = self.y
        end

        if self:isMovementEnabled() then
            if self.climb_jump_buffer > 0 and self.climb_cancel_buffer <= 0 then
                -- We're trying to start a jump!
                self.climb_momentum = 0
                self.climb_jump_buffer = 4
                self.climb_neutral_state = 0
                self.climb_charge_state = 1

                if self.climbing_x_dir > 0 then
                    self.climb_direction = "right"
                elseif self.climbing_x_dir < 0 then
                    self.climb_direction = "left"
                elseif self.climbing_y_dir < 0 then
                    self.climb_direction = "up"
                else
                    self.climb_direction = "down"
                end
            elseif self.climb_held_direction ~= nil then
                -- We're pressing a key! Climb in that direction.
                self.climb_state = 1
                self.climb_neutral_state = 0
            else
                -- We're not doing anything, slow down the climb momentum.
                self.climb_momentum = self.climb_momentum * (0.5 ^ DTMULT)
            end

            local found_exit, exit = self:isOverlappingObjectBounds(nil, nil, ClimbExit)
            if found_exit and exit:canExit() then
                ---@cast exit ClimbExit

                if self.climb_use_input == exit:getExitDirection() then
                    self:queueClimbExit({ obj = exit })
                end
            end
        end
    end
end

--- *(Called internally)* Checks if exiting the climb is queued up, and if so, sets the player's state to "CLIMB_EXIT" with the appropriate settings.
---
--- This should not be called by user code.
---@private
function Player:checkClimbExiting()
    if self.climb_exiting then
        self:setState("CLIMB_EXIT", self.climb_exit_settings)
    end
end

--- *(Called internally)* Initializes the climb bump state.
---
--- This should not be called by user code.
---@private
function Player:initClimbBump()
    if self.climb_recently_bumped ~= self.climb_direction then
        self.climb_previous_bump = self.climb_recently_bumped
        self.climb_recently_bumped = self.climb_direction
    end

    Assets.playSound("bump")

    if (self.climbing_x_dir > 0) then
        self.climb_bump_sprite = "climb/slip_right"
    elseif (self.climbing_x_dir < 0) then
        self.climb_bump_sprite = "climb/slip_left"
    end

    self.sprite:setSprite(self.climb_bump_sprite)
    self.sprite:setFrame(2)
    self.climb_bump_state = 2
end

--- *(Called internally)* Updates the climb bump state.
---
--- This should not be called by user code.
---@private
function Player:updateClimbBump()
    self.climb_bump_timer = self.climb_bump_timer - DTMULT

    if self.climb_bump_timer >= 3 then
        self.sprite:setFrame(2)
    else
        self.sprite:setFrame(1)
    end

    if self.climb_bump_timer <= 0 then
        self.climb_bump_state = 0

        if self.climb_fall_state <= 0 then
            self.climb_neutral_state = 1
        end
    end
end

--- *(Called internally)* Handles bumping while climbing.
---
--- This should not be called by user code.
---@private
function Player:handleClimbBump()
    if self.climb_bump_state > 0 then
        if self.climb_bump_state == 1 then
            self:initClimbBump()
        end

        if self.climb_bump_state == 2 then
            self:updateClimbBump()
        end
    end
end

--- *(Called internally)* Initializes the climb move state.
---
--- This should not be called by user code.
---@private
function Player:initClimbMove()
    self.climbing_x_dir = 0
    self.climbing_y_dir = 0

    if self.climb_direction == "up" then
        self.climbing_y_dir = -40
    elseif self.climb_direction == "left" then
        self.climbing_x_dir = -40
    elseif self.climb_direction == "right" then
        self.climbing_x_dir = 40
    else
        self.climbing_y_dir = 40
    end

    local checkamount = 1

    if self.climb_jumping and self.climb_charge_amount > 1 then
        checkamount = self.climb_charge_amount
    end

    for i = checkamount, 1, -1 do
        local testxclimb = self.climbing_x_dir * i
        local testyclimb = self.climbing_y_dir * i
        local finalclimbx = self.x + testxclimb
        local finalclimbx2 = (self.x + testxclimb) - self.climbing_x_dir

        local found_exit, exit = self:isOverlappingObjectBounds(finalclimbx2, (self.y + testyclimb) - self.climbing_y_dir, ClimbExit)
        if found_exit and exit:canExit() then
            ---@cast exit ClimbExit

            if self.climb_direction == exit:getExitDirection() then
                self.climbing_x_dir = testxclimb
                self.climbing_y_dir = testyclimb
                Assets.playSound("wing", 0.6, 1.1 + MathUtils.random(0.1))
                self.sprite:setSprite("climb/climbing")

                if self.climb_frame == 1 then
                    self.climb_frame = 3
                else
                    self.climb_frame = 1
                end

                self.climb_state = 2
                self.climb_timer = 0
            end
        end

        if self.climb_state == 2 then
            break
        end

        if self:isOverlappingClimbable(finalclimbx, self.y + testyclimb, ClimbArea) or NOCLIP then
            self.climbing_x_dir = testxclimb
            self.climbing_y_dir = testyclimb
            Assets.playSound("wing", 0.6, 1.1 + MathUtils.random(0.1))
            self.sprite:setSprite("climb/climbing")

            if self.climb_frame == 1 then
                self.climb_frame = 3
            else
                self.climb_frame = 1
            end

            self.climb_state = 2
            self.climb_timer = 0

            break
        end
    end

    if self.climb_state ~= 2 then
        self.climb_bump_timer = 8 + self.climb_momentum * 4

        if self.climb_jumping then
            self.climb_bump_timer = 8 + self.climb_charge_amount * 3
        end

        self.climb_state = 0
        self.climb_bump_state = 1
        self.climb_jumping = false
    end
end

--- *(Called internally)* Updates the climb move state.
---
--- This should not be called by user code.
---@private
function Player:updateClimbMove()
    if self.climbing_x_dir > 0 then
        self.climb_bump_sprite = "climb/slip_right"
    elseif self.climbing_x_dir < 0 then
        self.climb_bump_sprite = "climb/slip_left"
    end

    self.climb_recently_bumped = nil
    self.climb_previous_bump = nil

    if self.climb_timer == 0 then
        local dust_amount = self.climb_jumping and 5 or 1

        for i = 1, dust_amount do
            local dust = Sprite("effects/climb_dust_small")
            dust:setOrigin(0.5, 0)
            dust:setPosition(self.x, self.y)
            dust.layer = self.layer - 0.01

            if self.climb_jumping then
                dust.x = dust.x + MathUtils.random(-10, 10)
                dust.y = dust.y + MathUtils.random(-10, 10)
            elseif self.climbing_y_dir < 0 then
                dust.x = (dust.x - 10) + (10 * (self.climb_frame - 1))
            elseif self.climbing_y_dir > 0 then
                dust.x = (dust.x - 15) + (15 * (self.climb_frame - 1))
            else
                dust.y = dust.y + 10
            end

            dust:setScale(2, 2)
            dust:play(1 / 15, false, function() dust:remove() end)
            dust.physics.speed_y = -1
            dust.debug_select = false
            self.world:addChild(dust)
        end
    end

    self.sprite.y = 0

    local new_x
    local new_y
    local climbrate

    if not self.climb_jumping then
        if self.climb_speed < 1 then
            self.climb_speed = 1
        end
        self.climb_timer = self.climb_timer + (self.climb_speed + self.climb_momentum) * DTMULT
        climbrate = 10

        if self.climb_timer >= climbrate then
            self.climb_timer = climbrate
        end

        new_x = Utils.ease(self.last_climb_x, self.last_climb_x + self.climbing_x_dir, self.climb_timer / climbrate, "inOutCubic")
        new_y = Utils.ease(self.last_climb_y, self.last_climb_y + self.climbing_y_dir, self.climb_timer / climbrate, "inOutCubic")
        self.sprite:setFrame(self.climb_frame)

        if math.abs(new_x - self.last_climb_x) > 3 or math.abs(new_y - self.last_climb_y) > 3 then
            self.sprite:setFrame(self.climb_frame + 1)
        end
    else
        self.climb_timer = self.climb_timer + DTMULT
        climbrate = 6 + (self.climb_charge_amount * 2)
        local clipamount = 4

        if (self.climb_charge_amount >= 2) then
            clipamount = 2
        end

        if self.climb_timer >= climbrate then
            self.climb_timer = climbrate
        end

        if self.climb_timer >= climbrate - clipamount then
            self.climb_timer = climbrate
        end

        new_x = Utils.ease(self.last_climb_x, self.last_climb_x + self.climbing_x_dir, self.climb_timer / climbrate, "outSine")
        new_y = Utils.ease(self.last_climb_y, self.last_climb_y + self.climbing_y_dir, self.climb_timer / climbrate, "outSine")
        self.sprite.y = (-math.sin((self.climb_timer / climbrate) * math.pi) * (2 * (self.climb_charge_amount - 1))) / 2

        if self.climb_direction == "up" or self.climb_direction == "down" then
            self.sprite:setSprite("climb/jump_up")
            self.sprite:setFrame((self.climb_timer / 2) + 1)
        elseif self.climb_direction == "right" then
            if (self.climb_timer / climbrate) > 0.5 then
                self.sprite:setSprite("climb/land_right")
            else
                self.sprite:setSprite("climb/slip_right")
                self.sprite:setFrame(1)
            end
        elseif (self.climb_timer / climbrate) > 0.5 then
                self.sprite:setSprite("climb/land_left")
        else
            self.sprite:setSprite("climb/slip_left")
            self.sprite:setFrame(1)
        end

        if self.climb_afterimage_timer >= 1 then
            local afterimage = self.parent:addChild(Sprite(self.sprite:getTexture(), self.x, self.y + self.sprite.y * 2))
            afterimage:setScale(2)
            afterimage:setOrigin(0.5)
            afterimage.alpha = 0.2
            afterimage.layer = self.layer - 0.01
            afterimage:fadeOutSpeedAndRemove(0.04)
            self.parent:addChild(afterimage)
        end

        local check_x = self.x - MathUtils.clamp(self.climbing_x_dir, -40, 40)
        local check_y = self.y - MathUtils.clamp(self.climbing_y_dir, -40, 40)

        local found_exit, exit = self:isOverlappingObjectBounds(check_x, check_y, ClimbExit)

        local use_exit = nil

        if found_exit and exit:canExit() then
            ---@cast exit ClimbExit

            local exit_dir = exit:getExitDirection()
            if self.climbing_y_dir > 0 and exit_dir == "down" then
                use_exit = exit
            elseif self.climbing_y_dir < 0 and exit_dir == "up" then
                use_exit = exit
            elseif self.climbing_x_dir > 0 and exit_dir == "right" then
                use_exit = exit
            elseif self.climbing_x_dir < 0 and exit_dir == "left" then
                use_exit = exit
            end
        end

        if use_exit ~= nil then
            self:queueClimbExit({ obj = use_exit })
            return
        end
    end

    self.x = new_x
    self.y = new_y

    if self.climb_timer >= climbrate then
        if self.climb_jumping then
            self.climb_momentum = self.climb_charge_amount / 2
        end

        self.climb_jumping = false
        self.climb_state = 0
        self.climb_charge_amount = 0
        self.x = self.last_climb_x + self.climbing_x_dir
        self.y = self.last_climb_y + self.climbing_y_dir
        self.climb_neutral_state = 1
        self.check_climb_move = true
    end
end

--- *(Called internally)* Handles climb attacking logic.
---
--- This should not be called by user code.
---@private
function Player:handleClimbAttack()
    if self.climb_state == 10 then
        self.sprite:setSprite("climb/charge")
        self.sprite:setFrame(3)

        local old_cuttimer = self.climb_cut_timer
        self.climb_cut_timer = self.climb_cut_timer + DTMULT
        if old_cuttimer < 1 and self.climb_cut_timer >= 1 then
            self.climb_attack_flash = true
            self.climb_attack_flash_time = 0
        end
        if self.climb_cut_timer >= 5 then
            self.climb_state = 2
        end
    end
end

--- *(Called internally)* Checks if the player has moved into a new grid space while climbing.
---
--- This ends up calling [`onClimbMove`](lua://ClimbArea.onClimbMove) on the current climb area the player is on.
---
--- This should not be called by user code.
---@private
function Player:checkClimbMove()
    if self.check_climb_move then
        local found, obj = self:isOverlappingClimbable(nil, nil, ClimbArea)

        if found then
            ---@cast obj ClimbArea
            obj:onClimbMove(self)
        end

        self.check_climb_move = false
    end
end

--- *(Called internally)* Handles climb movement logic (moving normally or jumping).
---
--- This should not be called by user code.
---@private
function Player:handleClimbMovement()
    if self.climb_state == 1 then
        self:initClimbMove()
    end

    if self.climb_state == 2 then
        self:updateClimbMove()
    end
end

--- *(Called internally)* Updates climb timers and buffers.
---
--- This should not be called by user code.
---@private
function Player:updateClimbTimers()
    self.climb_up_buffer = MathUtils.approach(self.climb_up_buffer, 0, DTMULT)
    self.climb_down_buffer = MathUtils.approach(self.climb_down_buffer, 0, DTMULT)
    self.climb_left_buffer = MathUtils.approach(self.climb_left_buffer, 0, DTMULT)
    self.climb_right_buffer = MathUtils.approach(self.climb_right_buffer, 0, DTMULT)
    self.climb_jump_buffer = MathUtils.approach(self.climb_jump_buffer, 0, DTMULT)

    self.climb_momentum = self.climb_momentum - (0.03 * DTMULT)

    if self.climb_momentum <= 0 then
        self.climb_momentum = 0
    end

    if self.climb_afterimage_timer >= 1 then
        self.climb_afterimage_timer = self.climb_afterimage_timer - 1
    end
end

--- *(Called internally)* Updates the camera in the climb state.
---
--- This should not be called by user code.
---@private
function Player:updateClimbCamera()
    local camera = Game.world.camera
    if camera == nil then
        return
    end

    local camera_lerp_speed = 0.16

    local camera_min_x, camera_min_y = camera:getMinPosition()
    local camera_max_x, camera_max_y = camera:getMaxPosition()

    local camera_x = MathUtils.clamp(self.x, camera_min_x, camera_max_x)
    local camera_y = MathUtils.clamp(self.y + self.climb_camera_y_offset, camera_min_y, camera_max_y)

    local t = 1 - (1 - camera_lerp_speed) ^ DTMULT

    local ideal_x = MathUtils.lerp(camera.x, camera_x, t)
    local ideal_y = MathUtils.lerp(camera.y, camera_y, t)

    camera:setPosition(ideal_x, ideal_y)
end

function Player:updateClimb()
    -- Input
    self:handleClimbInput()
    self:shortenClimbBump()

    -- Collisions
    self:checkClimbBullets()
    self:checkClimbCollisions()

    -- Falling
    self:handleClimbFall()
    self:handleClimbGrab()
    self:handleClimbRecover()

    -- Normal climbing
    self:checkClimbAreaExists()
    self:handleClimbIdle()

    -- Exiting a climb
    self:checkClimbExiting()

    -- Charging a jump
    self:handleClimbCharge()

    -- Climb bumping
    self:handleClimbBump()

    -- Climb movement (moving normally or jumping)
    self:handleClimbMovement()

    -- Climb attack (jumping into an enemy)
    self:handleClimbAttack()

    -- Callback function for moving into a new grid space
    self:checkClimbMove()

    -- Update timers and buffers
    self:updateClimbTimers()

    -- Move the camera
    self:updateClimbCamera()
end

function Player:endClimb(next_state)
    self:setFacing(self.climb_direction)

    self:resetSprite()
    self:setSize(self.actor:getSize())
    self:setHitbox(self.actor:getHitbox())
    self:setOrigin(0.5, 1)

    self.sprite.y = 0

    self.charge_sound:stop()

    Game.world:setCameraAttached(true, true)

    if next_state ~= "CLIMB_EXIT" then
        self:cancelFollowerTweens()
        local blend_time = self.climb_exit_landing and 12 or 8

        for _, follower in ipairs(Game.world.followers) do
            follower.alpha = 0
            follower.visible = true
            table.insert(self.follower_tweens, Game.world.timer:tween(blend_time / 30, follower.color, { [1] = 1, [2] = 1, [3] = 1 }))
            table.insert(self.follower_tweens, Game.world.timer:tween(blend_time / 30, follower, { alpha = 1 }))
        end
    end
end

---@class ClimbExitStateSettings
---@field obj ClimbExit|ClimbLanding?
---@field landing boolean?
---@field x number?
---@field y number?

function Player:beginClimbExit(last_state, settings)
    Game.lock_movement = true
    self:setFacing(self.climb_direction)

    local landing = settings.landing

    local target_x = settings.x
    local target_y = settings.y

    if landing then
        local landing_strip = settings.obj --[[@as ClimbLanding]]

        target_x, target_y = self.x, landing_strip.y
    else
        local exit = settings.obj --[[@as ClimbExit]]

        target_x, target_y = exit:getExitPosition()
    end

    if target_x == nil or target_y == nil then
        target_x, target_y = self.x, self.y
    end

    self.climb_exit_landing = landing
    self.climb_exit_target_x = target_x
    self.climb_exit_target_y = target_y

    self.climb_exit_timer = 0


    if landing then
        Assets.playSound("noise")
        self:shake(5, 0, 1)
        self.sprite:setSprite("landed")
        self.sprite:setFrame(1)
        self:setFacing("down")

        self.x = target_x
        self.y = target_y

        -- TODO: Look into multiple party members, one party member, etc
        -- Susie prefers left, Ralsei prefers right

        local positions = {
            { self.x - 40, self.y - 10 },
            { self.x + 40, self.y - 10 }
        }

        for i, follower in ipairs(Game.world.followers) do
            local pos = positions[i]
            if pos then
                follower.x = pos[1]
                follower.y = pos[2]
            else
                follower.x = self.x
                follower.y = self.y - 20
            end
            follower:interpolateHistory()
        end
    else
        Assets.playSound("wing")
        self.auto_moving = true
    end

    if Game.world.camera ~= nil then

        local old_x, old_y = self.x, self.y
        self.x, self.y = target_x, target_y

        local ox, oy = self:getCameraOriginExact()
        local camera_x, camera_y = self:getRelativePos(ox, oy, Game.world)

        Game.world.camera:panTo(camera_x, camera_y, 15 / 30, "linear")

        self.x, self.y = old_x, old_y
    end

    if not landing then
        local jump_strength = 8
        if self:getFacing() == "up" then
            jump_strength = 12
        end

        self:jumpTo(target_x, target_y, jump_strength, 16 / 30, "jump_ball_slow")


        -- TODO: Look into multiple party members, one party member, etc
        -- Susie prefers left, Ralsei prefers right

        local facing = self:getFacing()

        for i, follower in ipairs(Game.world.followers) do
            if facing == "down" then
                if i == 1 then
                    follower.x = target_x - 20
                    follower.y = target_y - 10
                elseif i == 2 then
                    follower.x = target_x + 20
                    follower.y = target_y - 10
                else
                    follower.x = target_x
                    follower.y = target_y - 20
                end
            elseif facing == "up" then
                if i == 1 then
                    follower.x = target_x - 20
                    follower.y = target_y + 10
                elseif i == 2 then
                    follower.x = target_x + 20
                    follower.y = target_y + 10
                else
                    follower.x = target_x
                    follower.y = target_y + 20
                end
            elseif facing == "left" then
                follower.x = target_x + 20 * i
                follower.y = target_y
            elseif facing == "right" then
                follower.x = target_x - 20 * i
                follower.y = target_y
            end

            follower:interpolateHistory()
        end
    end
end

function Player:updateClimbExit()
    self.climb_exit_timer = self.climb_exit_timer + DTMULT

    if self.climb_exit_timer >= 16 then
        local blend_time = 12
        if not self.climb_exit_landing then
            blend_time = 8

            Assets.playSound("noise")
        end

        self:cancelFollowerTweens()

        for _, follower in ipairs(Game.world.followers) do
            follower.alpha = 0
            follower.visible = true
            table.insert(self.follower_tweens, Game.world.timer:tween(blend_time / 30, follower.color, { [1] = 1, [2] = 1, [3] = 1 }))
            table.insert(self.follower_tweens, Game.world.timer:tween(blend_time / 30, follower, { alpha = 1 }))
        end

        self:interpolateFollowers()
        Game.world:attachFollowersImmediate()

        for _, follower in ipairs(Game.world.followers) do
            for _, history in ipairs(follower.history) do
                history.facing = self:getFacing()
            end
            follower:setFacing(self:getFacing())
        end

        self:setState("WALK")
    end
end

function Player:endClimbExit()
    self.auto_moving = false
    Game.lock_movement = false
    Game.world.camera:setAttached(true, true)
    self:resetSprite()

    if self.climb_exit_timer < 16 then
        -- IF the end state was interrupted, forcibly show followers

        local blend_time = self.climb_exit_landing and 12 or 8

        self:cancelFollowerTweens()

        for _, follower in ipairs(Game.world.followers) do
            follower.alpha = 0
            follower.visible = true
            table.insert(self.follower_tweens, Game.world.timer:tween(blend_time / 30, follower.color, { [1] = 1, [2] = 1, [3] = 1 }))
            table.insert(self.follower_tweens, Game.world.timer:tween(blend_time / 30, follower, { alpha = 1 }))
        end

        self:interpolateFollowers()
        Game.world:attachFollowersImmediate()

        for _, follower in ipairs(Game.world.followers) do
            for _, history in ipairs(follower.history) do
                history.facing = self:getFacing()
            end
            follower:setFacing(self:getFacing())
        end
    end
end

function Player:getSoulOffset()
    if self.state == "CLIMB" then
        return self.width / 2, self.height / 2
    else
        return self.actor:getSoulOffset()
    end
end

function Player:updateHistory()
    if #self.history == 0 then
        table.insert(self.history, { x = self.x, y = self.y, time = 0 })
    end

    local moved = self.x ~= self.last_move_x or self.y ~= self.last_move_y

    local auto = self.auto_moving

    if moved then
        self.history_time = self.history_time + DT

        table.insert(
            self.history,
            1,
            {
                x = self.x,
                y = self.y,
                facing = self:getFacing(),
                time = self.history_time,
                state = self.state_manager.state,
                state_args = self.state_manager.args,
                auto = auto
            }
        )

        while (self.history_time - self.history[#self.history].time) > (Game.max_followers * FOLLOW_DELAY) do
            table.remove(self.history, #self.history)
        end
    end

    for _, follower in ipairs(self.world.followers) do
        follower:updateHistory(moved, auto)
    end

    self.last_move_x = self.x
    self.last_move_y = self.y
end

function Player:processJump()
    super.processJump(self)

    if (self.jump_progress == 3) and (not self.jumping) then
        -- A jump was just finished. Slightly hardcoded behavior for now...
        self.state_manager:call("postJump")
    end
end

function Player:update()
    if self.hurt_timer > 0 then
        self.hurt_timer = MathUtils.approach(self.hurt_timer, 0, DTMULT)
    end

    if self.slide_land_timer > 0 and self.state_manager.state ~= "SLIDE" then
        self.slide_land_timer = MathUtils.approach(self.slide_land_timer, 0, DTMULT)
        if self.slide_land_timer == 0 then
            self.slide_sound:stop()
            self.sprite:resetSprite()
            self.slide_lock_movement = false
        end
    end

    self.state_manager:update()

    self:updateHistory()

    if not Game.world.cutscene and not Game.world.menu then
        self.interact_buffer = MathUtils.approach(self.interact_buffer, 0, DT)
    end

    self.world.in_battle_area = false
    for _, area in ipairs(self.world.map.battle_areas) do
        if area:collidesWith(self.collider) then
            if not self.world.in_battle_area then
                self.world.in_battle_area = true
            end
            break
        end
    end

    if self.world:inBattle() then
        self.battle_alpha = math.min(self.battle_alpha + (0.04 * DTMULT), 0.8)
    else
        self.battle_alpha = math.max(self.battle_alpha - (0.08 * DTMULT), 0)
    end

    local outlinefx = self.outlinefx --[[@as BattleOutlineFX]]
    outlinefx:setAlpha(self.battle_alpha)

    super.update(self)
end

function Player:preDraw(dont_transform)
    super.preDraw(self, dont_transform)
    self._draw_reticle = true
end

function Player:drawReticleHint()
    if not self._draw_reticle then
        return 0, 0
    end

    local found = 0
    local alpha = 0

    if self.climb_charge_state > 0 then
        local count = 1
        if self.climb_charge_timer >= self.climb_charge_time_1 then
            count = 2
        end
        if self.climb_charge_timer >= self.climb_charge_time_2 then
            count = 3
        end

        local px = self.x
        local py = self.y

        for i = 1, count do
            local found_exit, exit = self:isOverlappingObjectBounds(px, py, ClimbExit)
            if found_exit and exit:canExit() then
                ---@cast exit ClimbExit
                if exit:getExitDirection() == self.climb_direction then
                    found = i
                    break
                end
            end

            if self.climb_direction == "down" then
                py = self.y + (40 * i)
            elseif self.climb_direction == "right" then
                px = self.x + (40 * i)
            elseif self.climb_direction == "up" then
                py = self.y - (40 * i)
            elseif self.climb_direction == "left" then
                px = self.x - (40 * i)
            end

            if self:isOverlappingClimbable(px, py, ClimbArea) or NOCLIP then
                found = i
            end
        end

        alpha = MathUtils.clamp(self.climb_charge_timer / 14, 0.1, 0.8)
        local angle = 0
        local xoff = 0
        local yoff = 0

        if self.climb_direction == "down" then
            angle = 0
            xoff = -22
            yoff = 18
        elseif self.climb_direction == "right" then
            angle = 90
            xoff = 18
            yoff = 22
        elseif self.climb_direction == "up" then
            angle = 180
            xoff = 22
            yoff = -18
        elseif self.climb_direction == "left" then
            angle = 270
            xoff = -18
            yoff = -22
        end

        local col = { 200 / 255, 200 / 255, 200 / 255, 0.85 }
        if found > 0 then
            col = { 1, 200 / 255, 132 / 255, 0.85 };
        end

        local origin_x = 11

        -- The offset of 1 is (most likely) due to GameMaker rounding being different from ours.
        local origin_y = -10 + 1


        local frames = Assets.getFrames("player/climb_reticle_hint")

        -- This index is very weird in DR and ends up being kinda broken at higher FPSes.
        -- So, quantize the time to 30 FPS intervals
        local target_fps = 1 / 30
        local target_seconds = math.floor(Kristal.getTime() / target_fps) * target_fps
        local index = (math.floor(target_seconds * 1000 / 2) % #frames) + 1

        Draw.setColor(col)
        Draw.drawPart(frames[index], (self.width / 2) + xoff, (self.height / 2) + yoff, 0, 0, 22, math.min(self.climb_charge_timer / self.climb_charge_time_2, 1) * 62, math.rad(-angle), 1, 1, -origin_x, -origin_y)
        Draw.setColor(COLORS.white)
    end

    return found, alpha
end

function Player:drawReticle(found, alpha)
    if not self._draw_reticle then
        return
    end

    if self.climb_charge_state > 0 then
        if found > 0 then
            local px = (self.width / 2) - 10
            local py = (self.height / 2) - 10

            if self.climb_direction == "down" then
                py = py + 20 * found
            elseif self.climb_direction == "right" then
                px = px + 20 * found
            elseif self.climb_direction == "up" then
                py = py - 20 * found
            elseif self.climb_direction == "left" then
                px = px - 20 * found
            end

            local col = ColorUtils.mergeColor(COLORS.yellow, COLORS.white, 0.4 + (math.sin(self.climb_charge_timer / 3) * 0.4))
            col[4] = col[4] * alpha

            Draw.setColor(col)
            Draw.draw(Assets.getTexture("player/climb_reticle"), px, py, 0, 1, 1, 2, 2)
        end
    end
end

function Player:draw()

    local found, alpha = self:drawReticleHint()

    local r, g, b, a = self:getColor()
    local use_alpha = a

    if self.state == "CLIMB" and Game.world.soul and Game.world.soul.inv_timer > 0 then
        use_alpha = a * 0.5
    end

    self:setColor(r, g, b, use_alpha)

    -- Draw the player
    super.draw(self)

    self:setColor(r, g, b, a)

    self:drawReticle(found, alpha)

    if DEBUG_RENDER then
        if self.state == "CLIMB" then
            self.climb_hurtbox:draw(1, 0, 0, 0.5)
        else
            local col = self.interact_collider[self:getFacing()]
            col:draw(1, 1, 0, 0.5)
        end
    end
end

function Player:postDraw()
    super.postDraw(self)
    self._draw_reticle = false
end

return Player
