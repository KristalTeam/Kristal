---@class ClimbStateSettings
---@field starting_direction FacingDirection? The direction the player will face when they start climbing.

---@class PlayerClimbState : StateClass
---
---@field player Player
---
---@overload fun(player: Player) : PlayerClimbState
local PlayerClimbState, super = Class(StateClass)

function PlayerClimbState:init(player)
    self.player = player

    self.charge_sound = Assets.newSound("chargeshot_charge")
    self.charge_sound:setLooping(true)

    self.hurtbox = Hitbox(player, 3, 3, 14, 14)
end

function PlayerClimbState:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("update", self.onUpdate)
    self:registerEvent("leave", self.onExit)
    self:registerEvent("drawUnderPlayer", self.drawUnderPlayer)
    self:registerEvent("drawOverPlayer", self.drawOverPlayer)
    self:registerEvent("preDraw", self.preDraw)
    self:registerEvent("postDraw", self.postDraw)
    self:registerEvent("drawDebug", self.drawDebug)
    self:registerEvent("getDebugInfo", self.getDebugInfo)
    self:registerEvent("remove", self.onRemove)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function PlayerClimbState:onRemove()
    self.charge_sound:stop()
end

function PlayerClimbState:getDebugInfo(info)
    table.insert(info, "Force climb: " .. (self.player.force_climb and "True" or "False"))
    table.insert(info, "Can jump: " .. (self.can_jump and "True" or "False"))
    table.insert(info, string.format("Direction: %s, (%s, %s)", self.direction, self.climbing_x_dir, self.climbing_y_dir))
    table.insert(info, "Momentum: " .. self.momentum)
end

function PlayerClimbState:onEnter(old_state, settings)
    settings = settings or {}

    self:resetClimbState()

    self.player.sprite:setSprite("climb/climbing")

    self.player:setSize(20, 20)
    self.player:setOrigin(0.5, 0.5)
    self.player.collider = Hitbox(self.player, 0, 0, 20, 20)

    Game.world:detachFollowers()

    -- If we're entering the climb state, and the followers aren't already invisible, fade them out
    self.player:cancelFollowerTweens()
    for _, follower in ipairs(Game.world.followers) do
        if follower.alpha > 0 then
            table.insert(self.player.follower_tweens, Game.world.timer:tween(7 / 30, follower.color, { [1] = 0.5, [2] = 0.5, [3] = 0.5 }))
            table.insert(self.player.follower_tweens, Game.world.timer:tween(7 / 30, follower, { alpha = 0 }))
        end
    end

    if settings.starting_direction ~= nil then
        self:setDirection(settings.starting_direction)
    end
end

--- *(Called internally)* Sets the climbing direction, used for determining the "default" direction the player will charge a jump to.
---
---@param direction FacingDirection
function PlayerClimbState:setDirection(direction)
    self.climbing_x_dir = 0
    self.climbing_y_dir = 0

    if direction == "up" then
        self.climbing_y_dir = -1
    elseif direction == "left" then
        self.climbing_x_dir = -1
    elseif direction == "right" then
        self.climbing_x_dir = 1
    elseif direction == "down" then
        self.climbing_y_dir = 1
    end
end

--- Returns whether or not the player can move normally -- this means they can start charging a jump, or they can move in the direction they're holding.
---
---@return boolean can_move
function PlayerClimbState:isIdle()
    return self.neutral_state == 1
end

function PlayerClimbState:resetClimbState()

    self.momentum = 0
    self.speed = 1

    -- Input buffers for climbing
    self.up_buffer = 0
    self.down_buffer = 0
    self.left_buffer = 0
    self.right_buffer = 0
    self.jump_buffer = 0
    self.cancel_buffer = 0

    self.direction = "down"
    self.held_direction = nil
    self.recently_bumped = nil
    self.previous_bump = nil

    self.jumping = false
    self.neutral_state = 1 -- 0 = In other state, 1 = Can start moving/start charging
    self.grab_state = 0
    self.bump_state = 0
    self.fall_state = 0
    self.charge_state = 0
    self.recover_state = 0

    self.can_jump = true
    self.can_grab = true
    self.can_recover = true

    self.fall_timer = 0
    self.fall_max_speed = 10
    self.fall_direction = "down"

    self.camera_y_offset = -80

    self.last_x = self.player.x
    self.last_y = self.player.y

    self.last_safe_x = self.player.x
    self.last_safe_y = self.player.y

    self.grab_timer = 0

    self.grab_start_x = self.player.x
    self.grab_start_y = self.player.y

    self.dust_timer = 0
    self.grab_sound_timer = 0

    self.climb_frame = 1

    self.charge_timer = 0
    self.charge_afterimage_timer = 0
    self.charge_amount = 1

    self.charge_time_1 = 10
    self.charge_time_2 = 22

    self.bump_sprite = "climb/slip_left"

    self.bump_timer = 0

    self.state = 0

    self.use_input = nil
    self.cancelled_bump = false

    self.cut_timer = 0

    self.afterimage_timer = 0

    self.exit_queued = false

    -- Initialized to false in DR! Unused, though. (checkdamagefloor)
    self.check_move = true

    self.attack_flash = false
    self.attack_flash_time = 0

    self.climb_exit_settings = {}

    self.timer = 0

    self.climbing_x_dir = 0
    self.climbing_y_dir = -1
end

---@param settings ClimbDismountSettings
function PlayerClimbState:queueExit(settings)
    self.exit_queued = true
    self.exit_settings = settings
    self.neutral_state = -1
    self.state = -1
    self.charge_state = -1
    self.fall_state = -1
    self.grab_state = -1
    self.timer = 0
    self.afterimage_timer = 0
end

--- Gets a list of every world object of the given type currently colliding with the player.
---@generic T : Object
---@param object T The class of object to check for collisions with.
---@param x? number The x position to check for collisions. Defaults to the player's current x position.
---@param y? number The y position to check for collisions. Defaults to the player's current y position.
---@return T[] objects A list of objects that are colliding with the player.
function PlayerClimbState:getOverlappingObjects(object, x, y)
    x = x or self.player.x
    y = y or self.player.y

    local old_x = self.player.x
    local old_y = self.player.y

    self.player.x = x
    self.player.y = y

    local objects = {}

    Object.startCache()
    for _, obj in ipairs(Game.stage:getObjects(object)) do
        if obj.parent == Game.world then
            if obj:collidesWith(self.player) then
                table.insert(objects, obj)
            end
        end
    end
    Object.endCache()

    self.player.x = old_x
    self.player.y = old_y

    return objects
end

--- Checks if any world object of the given type is currently colliding with the player, returning the first one found.
---@generic T : Object
---@param object T The class of object to check for collisions with.
---@param x? number The x position to check for collisions. Defaults to the player's current x position.
---@param y? number The y position to check for collisions. Defaults to the player's current y position.
---@return boolean is_overlapping
---@return T? object The object that the player is colliding with, if any.
function PlayerClimbState:isOverlappingObject(object, x, y)
    x = x or self.player.x
    y = y or self.player.y

    local old_x = self.player.x
    local old_y = self.player.y

    self.player.x = x
    self.player.y = y

    local found_obj = nil

    Object.startCache()
    for _, obj in ipairs(Game.stage:getObjects(object)) do
        if obj.parent == Game.world then
            if obj:collidesWith(self.player) then
                found_obj = obj
                break
            end
        end
    end
    Object.endCache()

    self.player.x = old_x
    self.player.y = old_y

    return found_obj ~= nil, found_obj
end

--- Checks if any ClimbArea, or a given child of ClimbArea, is currently colliding with the player, returning the first one found.
---@generic T : ClimbArea
---@param object T The class of object to check for collisions with.
---@param x? number The x position to check for collisions. Defaults to the player's current x position.
---@param y? number The y position to check for collisions. Defaults to the player's current y position.
---@return boolean is_overlapping
---@return T? object The object that the player is colliding with, if any.
function PlayerClimbState:isOverlappingClimbable(object, x, y)
    x = x or self.player.x
    y = y or self.player.y

    local old_x = self.player.x
    local old_y = self.player.y

    self.player.x = x
    self.player.y = y

    local found_obj = nil

    Object.startCache()
    for _, obj in ipairs(Game.stage:getObjects(object)) do
        if obj.parent == Game.world then
            if obj:isClimbable() and obj:collidesWith(self.player) then
                found_obj = obj
                break
            end
        end
    end
    Object.endCache()

    self.player.x = old_x
    self.player.y = old_y

    return found_obj ~= nil, found_obj
end

---@param time integer The amount of time (in frames) that it takes the player to attempt to re-grab the wall. Defaults to 20. Common values are 10, 15, 20, 24, 30, 34, and 80.
---@param settings ClimbFallSettings? The settings for the climb fall. Optional.
function PlayerClimbState:fall(time, settings)
    settings = settings or {}
    self.fall_state = 1
    self.fall_timer = time or 20
    self.fall_direction = settings.direction or "down"
    self.fall_max_speed = settings.max_speed or 10
    self.can_recover = settings.recover_from_fall ~= false
end

--- *(Called internally)* Cuts a climb bump short if the player changes directions or attempts to jump.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:shortenClimbBump()
    local changing_directions = (self.use_input ~= nil) and (self.last_direction ~= self.use_input)
    local attempting_jump = (self.jump_buffer > 0) and (self.cancel_buffer == 0)

    if self.bump_state == 2 -- If the player is bumping,
        and (self.bump_timer > 2) -- And it's early enough in the bump,
        and (not self.cancelled_bump) -- And the bump hasn't been cancelled,
        and (self.neutral_state ~= 1) -- And we're not in normal movement,
        and (changing_directions or attempting_jump) then -- And we're either changing directions, or attempting to jump,

        -- ...then shorten the bump timer so we can get back to normal movement sooner.
        self.bump_timer = math.min(self.bump_timer, 2)
        self.momentum = 0
        self.speed = 1
    end
end

function PlayerClimbState:handleClimbInput()
    local directions = {}
    local buffer_length = math.min(math.ceil(5 - (self.momentum * 2)), 4)

    self.afterimage_timer = self.afterimage_timer + DTMULT

    if ((self.player:isMovementEnabled() and (Input.down("up") or self.up_buffer > 0)) or self.player.force_climb) then
        if (Input.down("up") and (self.direction ~= "up")) then
            self.up_buffer = buffer_length
            self.left_buffer = 0
            self.right_buffer = 0
            self.down_buffer = 0
        end
        table.insert(directions, "up")
    end

    if ((self.player:isMovementEnabled() and (Input.down("down") or self.down_buffer > 0)) and (not self.player.force_climb)) then
        if (Input.down("down") and (self.direction ~= "down")) then
            self.up_buffer = 0
            self.left_buffer = 0
            self.right_buffer = 0
            self.down_buffer = buffer_length
        end
        table.insert(directions, "down")
    end

    if ((self.player:isMovementEnabled() and (Input.down("right") or self.right_buffer > 0)) and (not self.player.force_climb)) then
        if (Input.down("right") and (self.direction ~= "right")) then
            self.up_buffer = 0
            self.left_buffer = 0
            self.right_buffer = buffer_length
            self.down_buffer = 0
        end
        table.insert(directions, "right")
    end

    if ((self.player:isMovementEnabled() and (Input.down("left") or self.left_buffer > 0)) and (not self.player.force_climb)) then
        if (Input.down("left") and (self.direction ~= "left")) then
            self.up_buffer = 0
            self.left_buffer = buffer_length
            self.right_buffer = 0
            self.down_buffer = 0
        end
        table.insert(directions, "left")
    end

    local num_inputs = #directions
    self.use_input = nil
    self.cancelled_bump = false

    if num_inputs == 0 then
        self.held_direction = nil
    elseif (num_inputs == 1) or (self.held_direction == nil) then
        self.held_direction = directions[1]
        self.use_input = self.held_direction
    else
        for i = 1, #directions do
            local dir = directions[i]
            if (dir == self.held_direction) or (dir == self.recently_bumped) then
                self.cancelled_bump = self.cancelled_bump or (dir == self.recently_bumped)
                table.remove(directions, i)
                i = i - 1
            end
        end

        if (#directions > 0) then
            self.use_input = directions[1]
            self.cancelled_bump = self.use_input == self.previous_bump
        elseif ((self.held_direction ~= self.previous_bump) and (self.held_direction ~= self.recently_bumped)) then
            self.use_input = self.held_direction
            self.cancelled_bump = false
        else
            self.use_input = self.held_direction
            self.cancelled_bump = true
        end
    end

    self.last_direction = self.direction

    if (not self.jumping) then
        if (self.use_input ~= nil) and ((self.neutral_state == 1) or (self.grab_state > 0) or (self.bump_state == 2) or (self.charge_state > 0)) then
            self.direction = self.use_input
        end
    end

    if (self.can_jump) then
        if (Input.down("confirm") and (not self.player.force_climb) and (not self.climb_force_release_jump)) then
            if (self.jump_buffer < 2) then
                self.jump_buffer = 2
            end
        end

        if Input.pressed("confirm") and (not self.player.force_climb) then
            if (self.jump_buffer < 3) then
                self.jump_buffer = 3
                self.cancel_buffer = 0
            end
        end

        if not Input.down("confirm") then
            self.climb_force_release_jump = false
        end
    else
        self.jump_buffer = 0
        self.cancel_buffer = 0
    end
end

--- *(Called internally)* Initializes the climb charge state.
---
--- To enter the climb charging state, set `self.charge_state` to 1.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:initClimbCharge()
    -- Reset climb momentum
    self.momentum = 0

    -- Save our last X and Y
    self.player.x = self.last_x
    self.player.y = self.last_y

    self.charge_sound:seek(0)
    self.charge_sound:setPitch(0.4)
    self.charge_sound:setVolume(0.3)
    self.charge_sound:play()
    self.player.sprite:setSprite("climb/charge")
    self.player.sprite:setFrame(0)

    self.charge_timer = 0
    self.charge_afterimage_timer = 0
    self.charge_amount = 1
    self.charge_state = 2
end

--- *(Called internally)* Cancels the climb charge state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:cancelClimbCharge()
    -- We're trying to cancel the jump
    Assets.playSound("voice/toriel", 0.7, 0.4)
    Assets.playSound("voice/alphys", 0.7, 0.4)
    Assets.playSound("dtrans_heavypassing", 0.2, 1.8)

    self.cancel_buffer = 10
    self.charge_state = 0
    self.charge_timer = 0
    self.neutral_state = 1
    self.player:setColor(COLORS.white)
    self.charge_sound:stop()
end

--- *(Called internally)* Updates the climb charge state, charging the jump.
---
--- This happens every frame while `charge_state` is 2 and the user is holding Z.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:chargeClimbCharge()
    if self.direction == "up" or self.direction == "down" then
        self.player.sprite:setSprite("climb/charge")
    elseif self.direction == "right" then
        self.player.sprite:setSprite("climb/charge_right")
    elseif self.direction == "left" then
        self.player.sprite:setSprite("climb/charge_left")
    end

    self.charge_timer = self.charge_timer + DTMULT
    self.charge_afterimage_timer = self.charge_afterimage_timer + DTMULT

    if self.charge_timer >= self.charge_time_1 then
        self.player.sprite:setFrame(2)
        self.charge_sound:setPitch(0.5)
        self.charge_amount = 2
        self.player:setColor(ColorUtils.mergeColor(COLORS.white, COLORS.teal, 0.2 + (math.floor(math.sin(self.charge_timer / 2)) * 0.2)))
    end

    if self.charge_timer >= self.charge_time_2 then
        self.player.sprite:setFrame(3)
        self.charge_sound:setPitch(0.7)
        self.charge_amount = 3
        self.player:setColor(ColorUtils.mergeColor(COLORS.white, COLORS.teal, 0.4 + (math.floor(math.sin(self.charge_timer)) * 0.4)))

        if self.charge_afterimage_timer >= 8 then
            local afterimage = Sprite(self.player.sprite:getTexture(), self.player.x, self.player.y)
            afterimage.alpha = 0.3
            afterimage:setScale(2)
            afterimage:fadeOutSpeedAndRemove(0.1)
            afterimage:setOrigin(0.5)
            afterimage.debug_select = false
            afterimage.layer = self.player.layer + 20
            local scale_x, scale_y = self.player:getScale()
            afterimage.graphics.grow_x = 0.2 / scale_x
            afterimage.graphics.grow_y = 0.2 / scale_y
            self.player.parent:addChild(afterimage)
        end
    end

    if self.charge_afterimage_timer >= 8 then
        self.charge_afterimage_timer = self.charge_afterimage_timer - 8
    end
end

--- *(Called internally)* Finishes the climb charge state, performing the jump.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:finishClimbCharge()
    self.charge_state = 0
    self.jumping = true
    self.state = 1
    self.player:setColor(COLORS.white)
    self.charge_sound:stop()
end

--- *(Called internally)* Updates the climb charge state.
---
--- This function calls every frame while `charge_state` is 2.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbCharge()
    if Input.pressed("cancel") then
        self:cancelClimbCharge()
    elseif self.jump_buffer >= 2 or self.charge_timer < 3 then
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
function PlayerClimbState:handleClimbCharge()
    if self.charge_state > 0 then
        if self.charge_state == 1 then
            self:initClimbCharge()
        end

        if self.charge_state == 2 then
            self:updateClimbCharge()
        end
    end
end

--- *(Called internally)* Checks the player's hurtbox against all bullets, and applies damage if necessary.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:checkClimbBullets()
    if Game.world.soul ~= nil and Game.inv_frames <= 0 and self.player:isMovementEnabled() then
        Object.startCache()
        for _, bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
            if bullet:collidesWith(self.hurtbox) then
                if bullet:includes(ClimbEnemy) then
                    ---@cast bullet ClimbEnemy
                    if bullet:isActive() and not self.player:isClimbJumping() then
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
function PlayerClimbState:checkClimbCollisions()
    if self.player:isMovementEnabled() then
        local collided = {}
        local exited = {}

        Object.startCache()
        for _, obj in ipairs(Game.world.children) do
            if obj:collidesWith(self.player) then
                if obj:includes(ClimbEnemy) then
                    ---@cast obj ClimbEnemy
                    if obj:isActive() and self.player:isClimbJumping() then
                        Assets.playSound("noise")
                        self.state = 10
                        self.cut_timer = 0
                        obj:onJumpAttack(self.player)
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
                obj:onCollide(self.player)
            end

            if not obj.player_colliding then
                if obj.onEnter then
                    obj:onEnter(self.player)
                end
                obj.player_colliding = true
            end
        end
        for _, v in ipairs(exited) do
            if v.onExit then
                v:onExit(self.player)
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
function PlayerClimbState:initClimbFall()
    self.player.sprite:setSprite("climb/fall")
    self.player.sprite:setFrame(1)
    self.fall_speed = 0
    self.fall_state = 2
    self.neutral_state = 0

    self.charge_sound:stop()

    self.player:setColor(1, 1, 1)
    self.jumping = false
    self.charge_state = 0
    self.state = 0
    self.momentum = 0
end

--- *(Called internally)* Checks for climb landings, and queues a climb exit if one is found.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:checkClimbLandings()
    Object.startCache()
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(ClimbLanding) and self.player:collidesWith(obj) then
            self:queueExit({ landing = true, obj = obj })
            break
        end
    end
    Object.endCache()
end

--- *(Called internally)* Updates the climb falling state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbFall()
    self.fall_speed = self.fall_speed + 0.5 * DTMULT

    if (self.fall_speed >= self.fall_max_speed) then
        self.fall_speed = self.fall_max_speed
    end

    if (self.fall_speed >= 20) and (self.fall_direction == "down") then
        self.camera_y_offset = math.min(self.camera_y_offset + 2, 80)
    end

    if (self.fall_direction == "down") then
        self.player.y = self.player.y + math.ceil(self.fall_speed) * DTMULT
    elseif (self.fall_direction == "right") then
        self.player.x = self.player.x + math.ceil(self.fall_speed) * DTMULT
    elseif (self.fall_direction == "up") then
        self.player.y = self.player.y - math.ceil(self.fall_speed) * DTMULT
    elseif (self.fall_direction == "left") then
        self.player.x = self.player.x - math.ceil(self.fall_speed) * DTMULT
    end

    self.fall_timer = self.fall_timer - DTMULT

    if (self.fall_timer <= 0) then
        if (self.can_grab) then
            self.grab_x = self.last_x + (MathUtils.round((self.player.x - self.last_x) / 40) * 40)
            self.grab_y = self.last_y + (MathUtils.round((self.player.y - self.last_y) / 40) * 40)

            if self:isOverlappingClimbable(ClimbArea, self.grab_x, self.grab_y) then
                self.grab_state = 1
                self.direction = "down"
                self.fall_state = 0
            end
        end

        local howlongfall = 660

        if self.can_recover then
            if Game.world.camera then
                local x, y, w, h = Game.world.camera:getRect()

                if self.fall_direction == "down" then
                    if (self.player.y >= y + h + howlongfall) then
                        self.fall_state = 0
                        self.recover_state = 1
                    end
                elseif self.fall_direction == "up" then
                    if (self.player.y <= y - howlongfall) then
                        self.fall_state = 0
                        self.recover_state = 1
                    end
                elseif self.fall_direction == "right" then
                    if self.player.x >= x + w + howlongfall then
                        self.fall_state = 0
                        self.recover_state = 1
                    end
                elseif self.fall_direction == "left" then
                    if self.player.x <= x - howlongfall then
                        self.fall_state = 0
                        self.recover_state = 1
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
function PlayerClimbState:handleClimbFall()
    if self.fall_state > 0 then
        if self.fall_state == 1 then
            self:initClimbFall()
        end

        if self.fall_state == 2 then
            self:checkClimbLandings()
            self:updateClimbFall()
        end
    end
end

--- *(Called internally)* Initializes the climb grab state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:initClimbGrab()
    self.player.sprite:setSprite("climb/charge")
    self.player.sprite:setFrame(3)
    self.grab_state = 2
    self.grab_sound_timer = 0
    self.dust_timer = 0
end

--- *(Called internally)* Updates the climb grab state.
---
--- In this state, the player just grabbed onto the wall, and are sliding down slowly until they stop.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbGrab()
    self.grab_sound_timer = self.grab_sound_timer + DTMULT
    self.dust_timer = self.dust_timer + DTMULT

    if self.grab_sound_timer >= 1 then
        self.grab_sound_timer = self.grab_sound_timer - 1
        Assets.stopAndPlaySound("wing", 0.7, 0.6 + MathUtils.random(0.3))
    end

    if (self.dust_timer >= 2) then
        self.dust_timer = self.dust_timer - 2

        local dust = Sprite("effects/slide_dust")
        dust:play(1 / 15, false, function() dust:remove() end)
        dust:setOrigin(0.5, 0.5)
        dust:setScale(2, 2)
        dust:setPosition(self.player.x, self.player.y)
        dust.layer = self.player.layer - 0.01
        dust.physics.speed_y = -3
        dust.physics.speed_x = MathUtils.random(-1, 1)
        dust.debug_select = false
        self.player.world:addChild(dust)
    end

    -- Cap climb speed to 7
    if (self.fall_speed > 7) then
        self.fall_speed = 7
    end

    self.fall_speed = self.fall_speed - DTMULT

    if self.fall_direction == "down" then
        self.player.y = self.player.y + math.ceil(self.fall_speed) * DTMULT
    elseif self.fall_direction == "right" then
        self.player.x = self.player.x + math.ceil(self.fall_speed) * DTMULT
    elseif self.fall_direction == "up" then
        self.player.y = self.player.y - math.ceil(self.fall_speed) * DTMULT
    elseif self.fall_direction == "left" then
        self.player.x = self.player.x - math.ceil(self.fall_speed) * DTMULT
    end

    if (self.fall_speed <= 0) then
        self.grab_timer = 0
        self.grab_state = 3
        self.grab_start_y = self.player.y
        self.grab_start_x = self.player.x
    end
end

--- *(Called internally)* Updates the climb grab state.
---
--- In this state, the player has finished sliding down, and is easing back into position (on the grid).
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbGrabEnd()
    self.grab_timer = self.grab_timer + DTMULT
    local initwait = 7
    local waittime = 8

    if self.grab_timer >= initwait then
        local progress = (self.grab_timer / waittime) - (initwait / waittime)
        self.player.y = Utils.ease(self.grab_start_y, self.grab_y, progress, "inOutQuart")
        self.player.x = Utils.ease(self.grab_start_x, self.grab_x, progress, "inOutQuart")
    end

    if self.grab_timer >= (initwait + waittime) then
        self.player.x = MathUtils.round(self.player.x / 10) * 10
        self.player.y = MathUtils.round(self.player.y / 10) * 10

        self.grab_state = 0
        self.neutral_state = 1
        self.check_move = true
    end
end

--- *(Called internally)* Handles climb grabbing logic.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:handleClimbGrab()
    if self.grab_state > 0 then
        if self.grab_state == 1 then
            self:initClimbGrab()
        end

        if self.grab_state == 2 then
            self:updateClimbGrab()
        end

        if self.grab_state == 3 then
            self:updateClimbGrabEnd()
        end
    end
end

--- *(Called internally)* Updates the climb recover state, recovering the player back to the last safe position if they fell too far.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:handleClimbRecover()
    if self.recover_state > 0 then
        if self.recover_state == 1 then
            Game.world:hurtParty(30)
        end

        if self.recover_state >= 20 then
            self.player.x = self.last_safe_x
            self.player.y = self.last_safe_y
            self.neutral_state = 1

            self.recover_state = 0
        else
            self.recover_state = self.recover_state + DTMULT
        end
    end
end

--- *(Called internally)* Checks if the player is still in a climb area, and if not, initiates a climb fall.
---
--- This is not present in DELTARUNE, and is solely Kristal QOL.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:checkClimbAreaExists()
    if self.neutral_state == 1 and (not NOCLIP) then
        local found, obj = self:isOverlappingClimbable(ClimbArea, self.player.x, self.player.y)
        if not found then
            self:fall(20)
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
function PlayerClimbState:handleClimbIdle()
    if self.neutral_state == 1 then
        self.player.sprite:setSprite("climb/climbing")
        self.player.sprite:setFrame(self.climb_frame)
        self.last_x = self.player.x
        self.last_y = self.player.y

        if not self:isOverlappingObject(ClimbUnsafe) then
            self.last_safe_x = self.player.x
            self.last_safe_y = self.player.y
        end

        if self.player:isMovementEnabled() then
            if self.jump_buffer > 0 and self.cancel_buffer <= 0 then
                -- We're trying to start a jump!
                self.momentum = 0
                self.jump_buffer = 4
                self.neutral_state = 0
                self.charge_state = 1

                if self.climbing_x_dir > 0 then
                    self.direction = "right"
                elseif self.climbing_x_dir < 0 then
                    self.direction = "left"
                elseif self.climbing_y_dir < 0 then
                    self.direction = "up"
                else
                    self.direction = "down"
                end
            elseif self.held_direction ~= nil then
                -- We're pressing a key! Climb in that direction.
                self.state = 1
                self.neutral_state = 0
            else
                -- We're not doing anything, slow down the climb momentum.
                self.momentum = self.momentum * (0.5 ^ DTMULT)
            end

            local found_exit, exit = self:isOverlappingObject(ClimbExit)
            if found_exit and exit:canExit() then
                ---@cast exit ClimbExit

                if self.use_input == exit:getExitDirection() then
                    self:queueExit({ obj = exit })
                end
            end
        end
    end
end

--- *(Called internally)* Checks if exiting the climb is queued up, and if so, sets the player's state to "CLIMB_DISMOUNT" with the appropriate settings.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:checkClimbExiting()
    if self.exit_queued then
        self.player:setState("CLIMB_DISMOUNT", self.exit_settings)
    end
end

--- *(Called internally)* Initializes the climb bump state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:initClimbBump()
    if self.recently_bumped ~= self.direction then
        self.previous_bump = self.recently_bumped
        self.recently_bumped = self.direction
    end

    Assets.playSound("bump")

    if (self.climbing_x_dir > 0) then
        self.bump_sprite = "climb/slip_right"
    elseif (self.climbing_x_dir < 0) then
        self.bump_sprite = "climb/slip_left"
    end

    self.player.sprite:setSprite(self.bump_sprite)
    self.player.sprite:setFrame(2)
    self.bump_state = 2
end

--- *(Called internally)* Updates the climb bump state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbBump()
    self.bump_timer = self.bump_timer - DTMULT

    if self.bump_timer >= 3 then
        self.player.sprite:setFrame(2)
    else
        self.player.sprite:setFrame(1)
    end

    if self.bump_timer <= 0 then
        self.bump_state = 0

        if self.fall_state <= 0 then
            self.neutral_state = 1
        end
    end
end

--- *(Called internally)* Handles bumping while climbing.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:handleClimbBump()
    if self.bump_state > 0 then
        if self.bump_state == 1 then
            self:initClimbBump()
        end

        if self.bump_state == 2 then
            self:updateClimbBump()
        end
    end
end

--- *(Called internally)* Initializes the climb move state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:initClimbMove()
    self.climbing_x_dir = 0
    self.climbing_y_dir = 0

    if self.direction == "up" then
        self.climbing_y_dir = -40
    elseif self.direction == "left" then
        self.climbing_x_dir = -40
    elseif self.direction == "right" then
        self.climbing_x_dir = 40
    else
        self.climbing_y_dir = 40
    end

    local checkamount = 1

    if self.jumping and self.charge_amount > 1 then
        checkamount = self.charge_amount
    end

    for i = checkamount, 1, -1 do
        local testxclimb = self.climbing_x_dir * i
        local testyclimb = self.climbing_y_dir * i
        local finalclimbx = self.player.x + testxclimb
        local finalclimbx2 = (self.player.x + testxclimb) - self.climbing_x_dir

        local found_exit, exit = self:isOverlappingObject(ClimbExit, finalclimbx2, (self.player.y + testyclimb) - self.climbing_y_dir)
        if found_exit and exit:canExit() then
            ---@cast exit ClimbExit

            if self.direction == exit:getExitDirection() then
                self.climbing_x_dir = testxclimb
                self.climbing_y_dir = testyclimb
                Assets.playSound("wing", 0.6, 1.1 + MathUtils.random(0.1))
                self.player.sprite:setSprite("climb/climbing")

                if self.climb_frame == 1 then
                    self.climb_frame = 3
                else
                    self.climb_frame = 1
                end

                self.state = 2
                self.timer = 0
            end
        end

        if self.state == 2 then
            break
        end

        if self:isOverlappingClimbable(ClimbArea, finalclimbx, self.player.y + testyclimb) or NOCLIP then
            self.climbing_x_dir = testxclimb
            self.climbing_y_dir = testyclimb
            Assets.playSound("wing", 0.6, 1.1 + MathUtils.random(0.1))
            self.player.sprite:setSprite("climb/climbing")

            if self.climb_frame == 1 then
                self.climb_frame = 3
            else
                self.climb_frame = 1
            end

            self.state = 2
            self.timer = 0

            break
        end
    end

    if self.state ~= 2 then
        self.bump_timer = 8 + self.momentum * 4

        if self.jumping then
            self.bump_timer = 8 + self.charge_amount * 3
        end

        self.state = 0
        self.bump_state = 1
        self.jumping = false
    end
end

--- *(Called internally)* Updates the climb move state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbMove()
    if self.climbing_x_dir > 0 then
        self.bump_sprite = "climb/slip_right"
    elseif self.climbing_x_dir < 0 then
        self.bump_sprite = "climb/slip_left"
    end

    self.recently_bumped = nil
    self.previous_bump = nil

    if self.timer == 0 then
        local dust_amount = self.jumping and 5 or 1

        for i = 1, dust_amount do
            local dust = Sprite("effects/climb_dust_small")
            dust:setOrigin(0.5, 0)
            dust:setPosition(self.player.x, self.player.y)
            dust.layer = self.player.layer - 0.01

            if self.jumping then
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
            self.player.world:addChild(dust)
        end
    end

    self.player.sprite.y = 0

    local new_x
    local new_y
    local climbrate

    if not self.jumping then
        if self.speed < 1 then
            self.speed = 1
        end
        self.timer = self.timer + (self.speed + self.momentum) * DTMULT
        climbrate = 10

        if self.timer >= climbrate then
            self.timer = climbrate
        end

        new_x = Utils.ease(self.last_x, self.last_x + self.climbing_x_dir, self.timer / climbrate, "inOutQuad")
        new_y = Utils.ease(self.last_y, self.last_y + self.climbing_y_dir, self.timer / climbrate, "inOutQuad")
        self.player.sprite:setFrame(self.climb_frame)

        if math.abs(new_x - self.last_x) > 3 or math.abs(new_y - self.last_y) > 3 then
            self.player.sprite:setFrame(self.climb_frame + 1)
        end
    else
        self.timer = self.timer + DTMULT
        climbrate = 6 + (self.charge_amount * 2)
        local clipamount = 4

        if (self.charge_amount >= 2) then
            clipamount = 2
        end

        if self.timer >= climbrate then
            self.timer = climbrate
        end

        if self.timer >= climbrate - clipamount then
            self.timer = climbrate
        end

        new_x = Utils.ease(self.last_x, self.last_x + self.climbing_x_dir, self.timer / climbrate, "outSine")
        new_y = Utils.ease(self.last_y, self.last_y + self.climbing_y_dir, self.timer / climbrate, "outSine")
        self.player.sprite.y = (-math.sin((self.timer / climbrate) * math.pi) * (2 * (self.charge_amount - 1))) / 2

        if self.direction == "up" or self.direction == "down" then
            self.player.sprite:setSprite("climb/jump_up")
            self.player.sprite:setFrame((self.timer / 2) + 1)
        elseif self.direction == "right" then
            if (self.timer / climbrate) > 0.5 then
                self.player.sprite:setSprite("climb/land_right")
            else
                self.player.sprite:setSprite("climb/slip_right")
                self.player.sprite:setFrame(1)
            end
        elseif (self.timer / climbrate) > 0.5 then
                self.player.sprite:setSprite("climb/land_left")
        else
            self.player.sprite:setSprite("climb/slip_left")
            self.player.sprite:setFrame(1)
        end

        if self.afterimage_timer >= 1 then
            local afterimage = Sprite(self.player.sprite:getTexture(), self.player.x, self.player.y + self.player.sprite.y * 2)
            afterimage:setScale(2)
            afterimage:setOrigin(0.5)
            afterimage.alpha = 0.2
            afterimage.layer = self.player.layer - 0.01
            afterimage.debug_select = false
            afterimage:fadeOutSpeedAndRemove(0.04)
            self.player.parent:addChild(afterimage)
        end

        local check_x = self.player.x - MathUtils.clamp(self.climbing_x_dir, -40, 40)
        local check_y = self.player.y - MathUtils.clamp(self.climbing_y_dir, -40, 40)

        local found_exit, exit = self:isOverlappingObject(ClimbExit, check_x, check_y)

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
            self:queueExit({ obj = use_exit })
            return
        end
    end

    self.player.x = new_x
    self.player.y = new_y

    if self.timer >= climbrate then
        if self.jumping then
            self.momentum = self.charge_amount / 2
        end

        self.jumping = false
        self.state = 0
        self.charge_amount = 0
        self.player.x = self.last_x + self.climbing_x_dir
        self.player.y = self.last_y + self.climbing_y_dir
        self.neutral_state = 1
        self.check_move = true
    end
end

--- *(Called internally)* Handles climb attacking logic.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:handleClimbAttack()
    if self.state == 10 then
        self.player.sprite:setSprite("climb/charge")
        self.player.sprite:setFrame(3)

        local old_cuttimer = self.cut_timer
        self.cut_timer = self.cut_timer + DTMULT
        if old_cuttimer < 1 and self.cut_timer >= 1 then
            self.attack_flash = true
            self.attack_flash_time = 0
        end
        if self.cut_timer >= 5 then
            self.state = 2
        end
    end
end

--- *(Called internally)* Checks if the player has moved into a new grid space while climbing.
---
--- This ends up calling [`onClimbMove`](lua://ClimbArea.onClimbMove) on the current climb area the player is on.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:checkClimbMove()
    if self.check_move then
        local found, obj = self:isOverlappingClimbable(ClimbArea)

        if found then
            ---@cast obj ClimbArea
            obj:onClimbMove(self.player)
        end

        self.check_move = false
    end
end

--- *(Called internally)* Handles climb movement logic (moving normally or jumping).
---
--- This should not be called by user code.
---@private
function PlayerClimbState:handleClimbMovement()
    if self.state == 1 then
        self:initClimbMove()
    end

    if self.state == 2 then
        self:updateClimbMove()
    end
end

--- *(Called internally)* Updates climb timers and buffers.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbTimers()
    self.up_buffer = MathUtils.approach(self.up_buffer, 0, DTMULT)
    self.down_buffer = MathUtils.approach(self.down_buffer, 0, DTMULT)
    self.left_buffer = MathUtils.approach(self.left_buffer, 0, DTMULT)
    self.right_buffer = MathUtils.approach(self.right_buffer, 0, DTMULT)
    self.jump_buffer = MathUtils.approach(self.jump_buffer, 0, DTMULT)

    self.momentum = self.momentum - (0.03 * DTMULT)

    if self.momentum <= 0 then
        self.momentum = 0
    end

    if self.afterimage_timer >= 1 then
        self.afterimage_timer = self.afterimage_timer - 1
    end
end

--- *(Called internally)* Updates the camera in the climb state.
---
--- This should not be called by user code.
---@private
function PlayerClimbState:updateClimbCamera()
    local camera = Game.world.camera
    if camera == nil then
        return
    end

    local camera_lerp_speed = 0.16

    local camera_min_x, camera_min_y = camera:getMinPosition()
    local camera_max_x, camera_max_y = camera:getMaxPosition()

    local camera_x = MathUtils.clamp(self.player.x, camera_min_x, camera_max_x)
    local camera_y = MathUtils.clamp(self.player.y + self.camera_y_offset, camera_min_y, camera_max_y)

    local t = 1 - (1 - camera_lerp_speed) ^ DTMULT

    local ideal_x = MathUtils.lerp(camera.x, camera_x, t)
    local ideal_y = MathUtils.lerp(camera.y, camera_y, t)

    camera:setPosition(ideal_x, ideal_y)
end

function PlayerClimbState:onUpdate()
    -- Input
    self:handleClimbInput()
    self:shortenClimbBump()

    -- Collisions
    self:checkClimbBullets()
    self:checkClimbCollisions()

    -- Check if we're still in a climb area (Kristal-specific)
    self:checkClimbAreaExists()

    -- Falling
    self:handleClimbFall()
    self:handleClimbGrab()
    self:handleClimbRecover()

    -- Idle movement (also handles starting certain actions)
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

function PlayerClimbState:onExit(next_state)
    self.player:setFacing(self.direction)

    self.player:resetSprite()
    self.player:setSize(self.player.actor:getSize())
    self.player:setHitbox(self.player.actor:getHitbox())
    self.player:setOrigin(0.5, 1)

    self.player.sprite.y = 0

    self.charge_sound:stop()

    Game.world:setCameraAttached(true, true)

    if next_state ~= "CLIMB_DISMOUNT" then
        self.player:cancelFollowerTweens()
        local blend_time = self.player.climb_exit_landing and 12 or 8

        for _, follower in ipairs(Game.world.followers) do
            follower.alpha = 0
            follower.visible = true
            table.insert(self.player.follower_tweens, Game.world.timer:tween(blend_time / 30, follower.color, { [1] = 1, [2] = 1, [3] = 1 }))
            table.insert(self.player.follower_tweens, Game.world.timer:tween(blend_time / 30, follower, { alpha = 1 }))
        end
    end
end

function PlayerClimbState:drawReticleHint()
    if not self._draw_reticle then
        return 0, 0
    end

    local found = 0
    local alpha = 0

    if self.charge_state > 0 then
        local count = 1
        if self.charge_timer >= self.charge_time_1 then
            count = 2
        end
        if self.charge_timer >= self.charge_time_2 then
            count = 3
        end

        local px = self.player.x
        local py = self.player.y

        for i = 1, count do
            local found_exit, exit = self:isOverlappingObject(ClimbExit, px, py)
            if found_exit and exit:canExit() then
                ---@cast exit ClimbExit
                if exit:getExitDirection() == self.direction then
                    found = i
                    break
                end
            end

            if self.direction == "down" then
                py = self.player.y + (40 * i)
            elseif self.direction == "right" then
                px = self.player.x + (40 * i)
            elseif self.direction == "up" then
                py = self.player.y - (40 * i)
            elseif self.direction == "left" then
                px = self.player.x - (40 * i)
            end

            if self:isOverlappingClimbable(ClimbArea, px, py) or NOCLIP then
                found = i
            end
        end

        alpha = MathUtils.clamp(self.charge_timer / 14, 0.1, 0.8)
        local angle = 0
        local xoff = 0
        local yoff = 0

        if self.direction == "down" then
            angle = 0
            xoff = -22
            yoff = 18
        elseif self.direction == "right" then
            angle = 90
            xoff = 18
            yoff = 22
        elseif self.direction == "up" then
            angle = 180
            xoff = 22
            yoff = -18
        elseif self.direction == "left" then
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
        Draw.drawPart(frames[index], (self.player.width / 2) + xoff, (self.player.height / 2) + yoff, 0, 0, 22, math.min(self.charge_timer / self.charge_time_2, 1) * 62, math.rad(-angle), 1, 1, -origin_x, -origin_y)
        Draw.setColor(COLORS.white)
    end

    return found, alpha
end

function PlayerClimbState:drawReticle(found, alpha)
    if not self._draw_reticle then
        return
    end

    if self.charge_state > 0 then
        if found > 0 then
            local px = (self.player.width / 2) - 10
            local py = (self.player.height / 2) - 10

            if self.direction == "down" then
                py = py + 20 * found
            elseif self.direction == "right" then
                px = px + 20 * found
            elseif self.direction == "up" then
                py = py - 20 * found
            elseif self.direction == "left" then
                px = px - 20 * found
            end

            local col = ColorUtils.mergeColor(COLORS.yellow, COLORS.white, 0.4 + (math.sin(self.charge_timer / 3) * 0.4))
            col[4] = col[4] * alpha

            Draw.setColor(col)
            Draw.draw(Assets.getTexture("player/climb_reticle"), px, py, 0, 1, 1, 2, 2)
        end
    end
end

function PlayerClimbState:drawUnderPlayer()
    self.reticle_found, self.reticle_alpha = self:drawReticleHint()
end

function PlayerClimbState:drawOverPlayer()
    self:drawReticle(self.reticle_found, self.reticle_alpha)
end

function PlayerClimbState:preDraw()
    self._draw_reticle = true
end

function PlayerClimbState:postDraw()
    self._draw_reticle = false
end

function PlayerClimbState:drawDebug()
    self.hurtbox:draw(1, 0, 0, 0.5)
end

return PlayerClimbState
