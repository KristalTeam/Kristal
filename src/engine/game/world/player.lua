--- The character controlled by the player when in the Overworld.
---@class Player : Character, StateManagedClass
---@overload fun(chara: string|Actor, x?: number, y?: number) : Player
local Player, super = Class(Character)

function Player:init(chara, x, y)
    super.init(self, chara, x, y)

    self.is_player = true

    self.climb_state = PlayerClimbState(self)
    self.slide_state = PlayerSlideState(self)
    self.slide_lock_state = PlayerSlideLockState(self)
    self.slide_free_state = PlayerSlideFreeState(self)

    self.state_manager = StateManager("WALK", self, true)
    self.state_manager:addState("WALK", { update = self.updateWalk, drawDebug = self.drawDebug })
    self.state_manager:addState("SLIDE", self.slide_state)
    self.state_manager:addState("SLIDE_LOCK", self.slide_lock_state)
    self.state_manager:addState("SLIDE_FREE", self.slide_free_state)
    self.state_manager:addState("CLIMB_MOUNT", { postJump = self.postJumpClimbMount, enter = self.beginClimbMount })
    self.state_manager:addState("CLIMB", self.climb_state)
    self.state_manager:addState("CLIMB_DISMOUNT", { update = self.updateClimbDismount, enter = self.beginClimbDismount, leave = self.endClimbDismount })

    self.force_run = false
    self.force_walk = false
    self.run_timer = 0
    self.run_timer_grace = 0

    self.auto_moving = false

    self.hurt_timer = 0

    self.moving_x = 0
    self.moving_y = 0
    self.pressed_up = false
    self.pressed_right = false
    self.pressed_down = false
    self.pressed_left = false
    self.no_press = false

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
    self.climb_facing_direction = nil

    self.climb_mount_target_x = 0
    self.climb_mount_target_y = 0

    self.climb_mount_callback = nil

    self.climb_exit_landing = false
    self.climb_exit_target_x = 0
    self.climb_exit_target_y = 0

    self.climb_exit_timer = 0

    self.follower_tweens = {}
end

function Player:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "State: " .. self.state_manager.state)

    self.state_manager:call("getDebugInfo", info)

    if self.state_manager.state == "WALK" then
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

    self.state_manager:call("remove")

    if parent:includes(World) and parent.player == self then
        parent.player = nil
    end
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
        if obj.onInteract and obj:meetsCollider(col) then
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

    if self.state_manager.state == "CLIMB_DISMOUNT" then
        return false
    end

    if self.state_manager.state == "SLIDE_FREE" then
        return false
    end

    return true
end

--- Whether the player should decrease the invulnerability timer.
---
--- This returns `true` if the state's `shouldDecreaseInvuln` callback returns `true`, or if [`World:shouldBulletsHurt()`](lua://World.shouldBulletsHurt) returns `true`.
---@return boolean? decrease_invuln # `true` if the invulnerability timer should decrease.
function Player:shouldDecreaseInvuln()
    return Game.world:shouldBulletsHurt() or self.state_manager:call("shouldDecreaseInvuln")
end

--- Gets whether the player is currently allowed to move.
---
--- By default, this is `true` if all following conditions are met:
--- - `OVERLAY_OPEN` is `false` (no debug menus are open).
--- - `Game.lock_movement` is `false` (enabled by various things, such as cutscenes).
--- - The Player is not in the `SLIDE_LOCK` state (not inside a movement-locked SlideArea).
--- - The Game is in the `OVERWORLD` state (not in a Battle or a Shop).
--- - The World is in the `GAMEPLAY` state (not in the Menu or transitioning to another map).
--- - The Player's `hurt_timer` is inactive (a short period of movement lock caused by taking damage).
--- - The World's `door_delay` is inactive (per-transition delay after the transition is done).
---@return boolean movement_enabled # `true` if the player is allowed to move, `false` otherwise.
function Player:isMovementEnabled()
    return not OVERLAY_OPEN
        and not Game.lock_movement
        and self.state ~= "SLIDE_LOCK"
        and Game.state == "OVERWORLD"
        and self.world.state == "GAMEPLAY"
        and self.hurt_timer == 0
        and Game.world.door_delay == 0
end

--- Checks if any movement inputs are currently pressed.
---@return boolean pressed # `true` if any movement inputs are pressed, `false` otherwise.
function Player:isMovementPressed()
    return self.pressed_right or self.pressed_down or self.pressed_left or self.pressed_up
end

--- Gets the player's base walking speed, used for movement handling.
---
--- By default, this returns `4` in the Dark World and `6` in the Light World.
---@return number walk_speed # The player's base walking speed.
function Player:getBaseWalkSpeed()
    return Game:isLight() and 6 or 4
end

--- Calculates the player's current walking speed, used for movement handling.
---@param running boolean # Whether the player is currently running.
---@return number speed # The player's current walking speed.
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

--- Checks whether the player is currently running, used for movement handling.
---
--- When `force_run` is enabled, this additionally sets the `run_timer` to `200`.
---
--- If the player's state registers a `checkRunningInput` event, this will return the result of that event instead.
---@return boolean running # `true` if the player is currently running, `false` otherwise.
function Player:checkRunningInput()
    if self.state_manager:hasEvent("checkRunningInput") then
        return self.state_manager:call("checkRunningInput")
    end

    if self.force_walk then
        return false
    elseif self.force_run then
        self.run_timer = 200
        return true
    else
        if Kristal.Config["autoRun"] then
            return not Input.down("cancel")
        else
            return Input.down("cancel")
        end
    end
end

--- Checks the direction the player is currently attempting to move in, used for movement handling. This sets the player's `pressed_*` fields accordingly.
---
--- If the player's state registers a `checkWalkInput` event, this will return the result of that event instead.
---@param walk_speed number # The player's current walking speed, used for movement handling.
---@return number walk_x # The amount the player is attempting to move in the X direction.
---@return number walk_y # The amount the player is attempting to move in the Y direction.
---@return FacingDirection? walk_direction # The direction the player is attempting to move in.
function Player:checkWalkInput(walk_speed)
    self.pressed_right = false
    self.pressed_down = false
    self.pressed_left = false
    self.pressed_up = false

    if self.state_manager:hasEvent("checkWalkInput") then
        return self.state_manager:call("checkWalkInput", walk_speed)
    end

    local walk_x = 0 ---@type number
    local walk_y = 0 ---@type number
    local walk_direction = nil ---@type FacingDirection?

    if Input.down("right") then
        self.pressed_right = true
        walk_x = walk_speed * DTMULT
        walk_direction = "right"
    end
    if Input.down("left") then
        self.pressed_left = true
        walk_x = -walk_speed * DTMULT
        walk_direction = "left"
    end
    if Input.down("down") then
        self.pressed_down = true
        walk_y = walk_speed * DTMULT
        walk_direction = "down"
    end
    if Input.down("up") then
        self.pressed_up = true
        walk_y = -walk_speed * DTMULT
        walk_direction = "up"
    end

    return walk_x, walk_y, walk_direction
end

--- Gets the player's next facing direction based on their current movement.
---@param walk_direction FacingDirection? # The priority direction the player is currently moving in, or `nil` if they are not moving.
---@param was_moving boolean? # Whether the player was pressing any movement inputs on the previous frame.
function Player:getFacingFromInput(walk_direction, was_moving)
    local facing = self:getFacing()

    if not was_moving and walk_direction ~= nil then
        facing = walk_direction
    end

    if facing == "up" then
        if self.pressed_down then
            facing = "down"
        end

        if not self.pressed_up and walk_direction ~= nil then
            facing = walk_direction
        end
    end

    if facing == "down" then
        if self.pressed_up then
            facing = "up"
        end

        if not self.pressed_down and walk_direction ~= nil then
            facing = walk_direction
        end
    end

    if facing == "left" then
        if self.pressed_right then
            facing = "right"
        end

        if not self.pressed_left and walk_direction ~= nil then
            facing = walk_direction
        end
    end

    if facing == "right" then
        if self.pressed_left then
            facing = "left"
        end

        if not self.pressed_right and walk_direction ~= nil then
            facing = walk_direction
        end
    end

    return facing
end

--- Gets whether the player should currently collide with solids (e.g. noclip is not active).
---
--- If the player's state registers a `shouldCollideWithSolids` event, this will return the result of that event instead.
---@return boolean should_collide # `true` if the player should collide with solids, `false` otherwise.
function Player:shouldCollideWithSolids()
    if self.state_manager:hasEvent("shouldCollideWithSolids") then
        return self.state_manager:call("shouldCollideWithSolids")
    end

    return not (self.noclip or NOCLIP)
end

--- *(Called internally)* Checks for collisions with solid objects at a given position.
---@param x number # The X position to check for collisions at.
---@param y number # The Y position to check for collisions at.
---@param solids Collider[]? # A list of solid colliders to check for collisions with. Defaults to `Game.world:getCollision()`.
---@return Collider? hit # The solid collider that the player collided with, or `nil` if no collision occurred.
function Player:checkSolidCollisionAt(x, y, solids)
    if solids == nil then
        solids = Game.world:getCollision()
    end

    Object.uncache(self)

    local last_x, last_y = self:getPosition()
    self:setPosition(x, y)

    Object.startCache()

    local hit ---@type Collider?

    for _, solid in ipairs(solids) do
        if self:meetsCollider(solid) then
            hit = solid
            break
        end
    end

    Object.endCache()

    Object.uncache(self)

    self:setPosition(last_x, last_y)

    return hit
end

--- *(Called internally)* Gets all solid colliders in the area the player is moving through.
---@param collider Collider # The sweep collider that covers the area the player is moving through.
---@return Collider[] solids # A list of solid colliders that are in the area the player is moving through.
function Player:sweepSolidCollision(collider)
    local solids = {}

    local all_solids = Game.world:getCollision()

    for _, solid in ipairs(all_solids) do
        if solid:meetsCollider(collider) then
            table.insert(solids, solid)
        end
    end

    return solids
end

--- Moves the player by a given amount, checking for collisions with solids (unless noclip is enabled).
---
--- This additionally sets the following fields:
--- - `moved` is set to the `walk_speed` if they moved, or `0` if they did not.
--- - `last_collided_x` and `last_collided_y` are set to whether the player collided with a solid on the X or Y axis respectively (even if they bumped).
--- - `moving_x` and `moving_y` are set to the amount the player moved on the X and Y axes respectively (not including bump movement).
---@param walk_x number # The amount to move the player in the X direction.
---@param walk_y number # The amount to move the player in the Y direction.
---@param walk_speed number # The player's current walking speed, used for collision bumping.
---@return boolean moved # Whether the player moved at all.
---@return boolean collided # Whether the player collided with a solid object (even if they were bumped).
function Player:moveAndCollide(walk_x, walk_y, walk_speed)
    self.last_collided_x = false
    self.last_collided_y = false

    if self:shouldCollideWithSolids() then
        -- Begin collision checks

        Object.startCache()

        -- Optimization: Calculate a quick "sweep" box that covers all potential distance
        -- We're going to be repeatedly checking collision for bumping so we want to minimize the number of solids we check against

        local max_bump = walk_speed

        local sweep_dist_x = math.max(math.abs(walk_x), max_bump)
        local sweep_dist_y = math.max(math.abs(walk_y), max_bump)

        local sweep = CollisionUtils.getSweepHitbox(self,
            sweep_dist_x,
            sweep_dist_x,
            sweep_dist_y,
            sweep_dist_y
        )

        local solids = self:sweepSolidCollision(sweep)

        -- Horizontal movement collision

        if self:checkSolidCollisionAt(self.x + walk_x, self.y, solids) then
            self.last_collided_x = true

            -- Try to bump up/down if we're colliding with something in the way of our horizontal movement

            local shifted_y = false

            -- We attempt to bump to the side by up to `walk_speed` pixels
            -- Note: Bump starts from max distance, meaning small slopes may bump more than expected
            for i = walk_speed, 0, -1 do
                -- Bump up if we're not holding down
                if not self.pressed_down and not self:checkSolidCollisionAt(self.x + walk_x, self.y - i, solids) then
                    self.y = self.y - i
                    walk_y = 0
                    shifted_y = true
                    break
                end

                -- Bump down if we're not holding up
                if not self.pressed_up and not self:checkSolidCollisionAt(self.x + walk_x, self.y + i, solids) then
                    self.y = self.y + i
                    walk_y = 0
                    shifted_y = true
                    break
                end
            end

            -- Try to move as far as possible

            -- We only need to re-check initial collision if our position changed
            if not shifted_y or self:checkSolidCollisionAt(self.x + walk_x, self.y, solids) then
                -- Decrease walk distance until we find a non-colliding position, or reach 0
                while walk_x ~= 0 do
                    walk_x = MathUtils.approach(walk_x, 0, 1)

                    if not self:checkSolidCollisionAt(self.x + walk_x, self.y, solids) then
                        break
                    end
                end
            end
        end

        -- Vertical movement collision

        if self:checkSolidCollisionAt(self.x, self.y + walk_y, solids) then
            self.last_collided_y = true

            -- Try to bump left/right if we're colliding with something in the way of our vertical movement

            local shifted_x = false

            -- We attempt to bump to the side by up to `walk_speed` pixels
            -- Note: Bump starts from max distance, meaning small slopes may bump more than expected
            for i = walk_speed, 0, -1 do
                -- Bump left if we're not holding right
                if not self.pressed_right and not self:checkSolidCollisionAt(self.x - i, self.y + walk_y, solids) then
                    self.x = self.x - i
                    walk_x = 0
                    shifted_x = true
                    break
                end

                -- Bump right if we're not holding left
                if not self.pressed_left and not self:checkSolidCollisionAt(self.x + i, self.y + walk_y, solids) then
                    self.x = self.x + i
                    walk_x = 0
                    shifted_x = true
                    break
                end
            end

            -- Try to move as far as possible

            -- We only need to re-check initial collision if our position changed
            if not shifted_x or self:checkSolidCollisionAt(self.x, self.y + walk_y, solids) then
                -- Decrease walk distance until we find a non-colliding position, or reach 0
                while walk_y ~= 0 do
                    walk_y = MathUtils.approach(walk_y, 0, 1)

                    if not self:checkSolidCollisionAt(self.x, self.y + walk_y, solids) then
                        break
                    end
                end
            end
        end

        -- Final combined-axis movement collision

        if self:checkSolidCollisionAt(self.x + walk_x, self.y + walk_y, solids) then
            self.last_collided_x = true
            self.last_collided_y = true

            -- Try to move as far as possible

            -- Decrease walk distance on both axes until we find a non-colliding position, or reach 0
            while walk_x ~= 0 or walk_y ~= 0 do
                walk_x = MathUtils.approach(walk_x, 0, 1)
                walk_y = MathUtils.approach(walk_y, 0, 1)

                if not self:checkSolidCollisionAt(self.x + walk_x, self.y + walk_y, solids) then
                    break
                end
            end
        end

        Object.endCache()
    end

    -- Apply movement and return

    self.x = self.x + walk_x
    self.y = self.y + walk_y

    self.moving_x = walk_x
    self.moving_y = walk_y

    local moved = math.abs(walk_x) > 0 or math.abs(walk_y) > 0

    if moved then
        self.moved = walk_speed
    else
        self.moved = 0
    end

    -- Uncache again just incase a cache is already active
    Object.uncache(self)

    return moved, self.last_collided_x or self.last_collided_y
end

function Player:handleMovement()
    -- Check inputs

    local running = self:checkRunningInput()
    local walk_speed = self:getCurrentSpeed(running)
    local walk_x, walk_y, walk_direction = self:checkWalkInput(walk_speed)

    -- Update facing direction

    local new_facing = self:getFacingFromInput(walk_direction, not self.no_press)
    self:setFacing(new_facing)

    -- Do movement

    local moved, collided = self:moveAndCollide(walk_x, walk_y, walk_speed)

    -- Update run timer

    if running and moved and not collided then
        -- In Deltarune: `runmove` is set to true here and false otherwise, which causes the running animation speed
        self.run_timer = self.run_timer + DTMULT
        self.run_timer_grace = 0
    elseif self.run_timer > 0 then
        -- ~1 frame of grace time to change direction without stopping at higher framerates
        -- (this should have no effect at 30 fps)
        if self.run_timer_grace > 0.95 then
            self.run_timer = 0
            self.run_timer_grace = 0
        else
            self.run_timer_grace = self.run_timer_grace + DTMULT
        end
    end

    self.no_press = false
end

function Player:updateWalk()
    if self:isMovementEnabled() then
        self:handleMovement()
    end
end

function Player:onMapLoad()
    if self:isClimbing() then
        Game.world:detachFollowers()
        self:cancelFollowerTweens()
        for _, follower in ipairs(Game.world.followers) do
            follower.alpha = 0
            follower.visible = false
        end

        self.climb_state:setDirection(self:getFacing())
    end
end

--- Checks if the player's position has changed since the last frame.
---@return boolean moving # `true` if the player has moved, `false` otherwise.
function Player:isMoving()
    return self.x ~= self.last_x or self.y ~= self.last_y
end

function Player:isClimbing()
    return self.state_manager.state == "CLIMB"
end

function Player:isClimbJumping()
    return self:isClimbing() and self.climb_state.jumping and self.climb_state.state == 2
end

function Player:isSliding()
    local state = self.state_manager.state
    return state == "SLIDE" or state == "SLIDE_LOCK" or state == "SLIDE_FREE"
end

function Player:checkSlideStop()
    if not self:shouldCollideWithSolids() then
        return false
    end

    return self:checkSolidCollisionAt(self.x, self.y + 20) ~= nil
end

function Player:cancelFollowerTweens()
    for _, tween in ipairs(self.follower_tweens) do
        Game.world.timer:cancel(tween)
    end
    self.follower_tweens = {}
end

---@class ClimbMountSettings
---@field target_x number? The x position that the player will jump to.
---@field target_y number? The y position that the player will jump to.
---@field facing_direction FacingDirection? The climb direction the player will face after mounting.
---@field post_jump fun():nil? A function that will be called after the player finishes the jump, before they enter the CLIMB state.

function Player:beginClimbMount(last_state, settings)
    settings = settings or {}

    Game.lock_movement = true

    Game.world:detachFollowers()

    self.climb_mount_target_x = settings.target_x or self.x
    self.climb_mount_target_y = settings.target_y or self.y

    self.climb_facing_direction = settings.facing_direction

    if self.climb_facing_direction == nil then
        -- If a facing direction isn't supplied, let's try to guess one...
        self.climb_facing_direction = Utils.facingFromAngle(MathUtils.angle(self.x, self.y, self.climb_mount_target_x, self.climb_mount_target_y))
    end

    self:jumpTo(self.climb_mount_target_x, self.climb_mount_target_y + self:getScaledHeight() / 2, 8, 8 / 30, "jump_ball_slow")

    self:cancelFollowerTweens()

    for _, follower in ipairs(Game.world.followers) do
        follower.alpha = 1
        follower.visible = true
        table.insert(self.follower_tweens, Game.world.timer:tween(7 / 30, follower.color, { [1] = 0.5, [2] = 0.5, [3] = 0.5 }))
        table.insert(self.follower_tweens, Game.world.timer:tween(7 / 30, follower, { alpha = 0 }))
    end

    Assets.playSound("wing")

    self.climb_mount_callback = settings.post_jump
end

function Player:postJumpClimbMount()
    Assets.playSound("noise")

    self.x = self.climb_mount_target_x
    self.y = self.climb_mount_target_y

    Game.lock_movement = false
    self:setState("CLIMB", { starting_direction = self.climb_facing_direction })

    if self.climb_mount_callback then
        self.climb_mount_callback()
        self.climb_mount_callback = nil
    end
end

---@class ClimbFallSettings
---@field direction "up"|"down"|"left"|"right"? The direction the player falls. Defaults to "down".
---@field recover_from_fall boolean? Whether the player should be teleported back to the last safe position after falling. Defaults to true.
---@field max_speed number? The maximum speed the player can reach while falling. Defaults to 10.

--- Make the player fall while in the climb state. Does nothing if the player is not climbing.
---@param time integer The amount of time (in frames) that it takes the player to attempt to re-grab the wall. Defaults to 20. Common values are 10, 15, 20, 24, 30, 34, and 80.
---@param settings ClimbFallSettings? The settings for the climb fall. Optional.
function Player:climbFall(time, settings)
    if not self:isClimbing() then
        return
    end

    self.climb_state:fall(time, settings)
end

--- Requests that the player exits the climb state, jumping to a defined location.
---@param settings ClimbDismountSettings The settings for the climb dismount.
function Player:queueClimbDismount(settings)
    if not self:isClimbing() then
        return
    end

    self.climb_state:queueExit(settings)
end

---@class ClimbDismountSettings
---@field obj ClimbExit|ClimbLanding?
---@field landing boolean?
---@field x number?
---@field y number?
---@field facing FacingDirection?

function Player:beginClimbDismount(last_state, settings)
    Game.lock_movement = true

    local landing = settings.landing

    local target_x = settings.x
    local target_y = settings.y

    if settings.facing ~= nil then
        self:setFacing(settings.facing)
    end

    if settings.obj ~= nil then
        if landing then
            local landing_strip = settings.obj --[[@as ClimbLanding]]

            target_x, target_y = self.x, landing_strip.y
        else
            local exit = settings.obj --[[@as ClimbExit]]

            target_x, target_y = exit:getExitPosition()
        end
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

function Player:updateClimbDismount()
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

function Player:endClimbDismount()
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

    if not self:isMovementPressed() then
        self.no_press = true
    end

    self.pressed_right = false
    self.pressed_down = false
    self.pressed_left = false
    self.pressed_up = false

    self.state_manager:update()

    self:updateHistory()

    if not Game.world.cutscene and not Game.world.menu then
        self.interact_buffer = MathUtils.approach(self.interact_buffer, 0, DT)
    end

    self.world.in_battle_area = false
    for _, area in ipairs(self.world.map.battle_areas) do
        if area:meetsCollider(self.collider) then
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

    self.state_manager:call("preDraw", dont_transform)
end

function Player:drawDebug()
    local col = self.interact_collider[self:getFacing()]
    col:draw(1, 1, 0, 0.5)
end

function Player:draw()
    self.state_manager:call("drawUnderPlayer")

    local r, g, b, a = self:getColor()
    local use_alpha = a

    if self.state == "CLIMB" and Game.inv_frames > 0 then
        use_alpha = a * 0.5
    end

    self:setColor(r, g, b, use_alpha)

    -- Draw the player
    super.draw(self)

    self:setColor(r, g, b, a)

    self.state_manager:call("drawOverPlayer")

    if DEBUG_RENDER then
        self.state_manager:call("drawDebug")
    end
end

function Player:postDraw()
    super.postDraw(self)

    self.state_manager:call("postDraw")
end

return Player
