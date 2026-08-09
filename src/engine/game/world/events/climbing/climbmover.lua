--- The settings for a ClimbMover.
---@class ClimbMoverSettings
---@field target MarkerRef The identifier of the target event that this ClimbMover leads to.
---@field exit MarkerRef? If set, the player will dismount to this location automatically once they reach the target position.
---@field start_exit MarkerRef? If set, the player will dismount to this location automatically once they reach the starting position.
---@field one_way boolean? If true, the ClimbMover will only move the player in one direction. Defaults to false.

--- A ClimbMover is an area the player can climb onto. Once they're on it, it will move to a pre-set location.
---
--- `ClimbMover` is an [`Event`](lua://Event.init) - naming an object `climbmover` on an `objects` layer in a map creates this object.
---
---@class ClimbMover : ClimbArea
---
---@field target MarkerRef The identifier of the target event that this ClimbMover leads to.
---@field target_x number? The x position that the player will jump to.
---@field target_y number? The y position that the player will jump to.
---@field exit MarkerRef? The identifier of the exit marker that this ClimbMover will dismount the player to.
---@field exit_x number? The x position that the player will be dismounted to.
---@field exit_y number? The y position that the player will be dismounted to.
---@field start_exit MarkerRef? The identifier of the exit marker that this ClimbMover will dismount the player to when returning to the start position.
---@field start_exit_x number? The x position that the player will be dismounted to when returning to the start position.
---@field start_exit_y number? The y position that the player will be dismounted to when returning to the start position.
---
---@overload fun(...) : ClimbMover
local ClimbMover, super = Class(ClimbArea)

---@param x number?
---@param y number?
---@param shape EventShape?
---@param settings ClimbMoverSettings?
function ClimbMover:init(x, y, shape, settings)
    settings = settings or {}
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)

    self:setSprite("world/events/climb_mover")

    self.state = "IDLE"

    self.timer = 0
    self.travel_time = -1
    self.wait_time = 5
    self.reset = 0

    self.one_way = settings.one_way or false

    self.start_x = self.x
    self.start_y = self.y

    self.target = settings.target

    self.target_x = nil
    self.target_y = nil

    self.at_target = false

    self.current_target_x = nil
    self.current_target_y = nil

    if self.target == nil then
        error(string.format("ClimbMover at (%d, %d) requires a target, found none", self.x, self.y))
    end

    self.exit = settings.exit
    self.exit_x = nil
    self.exit_y = nil

    self.start_exit = settings.start_exit
    self.start_exit_x = nil
    self.start_exit_y = nil
end

function ClimbMover:calculateTravelTime()
    self.travel_time = MathUtils.clamp(MathUtils.round(MathUtils.dist(self.start_x, self.start_y, self.target_x, self.target_y) / 12) + 1, 15, 60)
end

function ClimbMover:onLoad()
    super.onLoad(self)

    local target_x, target_y, _ = MapUtils.parseMarkerProperty(self, self.target, "target")
    self.target_x = target_x - TILE_WIDTH / 2
    self.target_y = target_y - TILE_HEIGHT / 2
    self:calculateTravelTime()

    if self.exit ~= nil then
        self.exit_x, self.exit_y, _ = MapUtils.parseMarkerProperty(self, self.exit, "exit")
    end

    if self.start_exit ~= nil then
        self.start_exit_x, self.start_exit_y, _ = MapUtils.parseMarkerProperty(self, self.start_exit, "start_exit")
    end
end

function ClimbMover:onCollide(char)
    if self.state == "IDLE" then
        if char.is_player and char:isMovementEnabled() then
            if char:isClimbing() then
                if char.climb_state:isIdle() then
                    Game.lock_movement = true
                    Assets.playSound("noise")
                    self.timer = 0
                    self.state = "MOVING"
                end
            else
                local world_x, world_y = self:getRelativePos(self.width / 2, self.height / 2, Game.world)

                local target_x, target_y = Game.world:getRelativePos(world_x, world_y, char.parent)

                char:setState("CLIMB_MOUNT", {
                    target_x = target_x,
                    target_y = target_y,
                    post_jump = function() self:postMount() end
                })

                Game.lock_movement = true
                self.state = "WAITING"
                self.timer = 0
            end
        end
    end
end

function ClimbMover:postMount()
    Game.lock_movement = true
    self.state = "MOVING"
end

function ClimbMover:onRemove(parent)
    super.onRemove(self, parent)

    if self.unsafe_area then
        self.unsafe_area:remove()
        self.unsafe_area = nil
    end
end

function ClimbMover:update()
    super.update(self)

    local done_move = false

    if self.state == "MOVING" then
        local old_timer = self.timer
        self.timer = self.timer + DTMULT

        local target_time = self.wait_time + 1
        if (old_timer < target_time) and (self.timer >= target_time) then
            self.current_target_x = self.target_x
            self.current_target_y = self.target_y

            if self.at_target then
                self.current_target_x = self.start_x
                self.current_target_y = self.start_y
            end

            Game.world.timer:tween(self.travel_time / 30, self, { x = self.current_target_x }, "out-quad")
            Game.world.timer:tween(self.travel_time / 30, self, { y = self.current_target_y }, "in-back")
        end

        target_time = 1 + self.travel_time + 1
        if old_timer < target_time and self.timer >= target_time then
            Assets.playSound("impact", 0.6, 1.2)
            Assets.playSound("noise", 0.7, 0.9)
        end

        target_time = 1 + self.travel_time + (self.wait_time * 2)
        if old_timer < target_time and self.timer >= target_time then
            self.timer = 0
            done_move = true
        end
    end

    if done_move then
        self.timer = 0

        Game.world.player.x = self.x + self.width / 2
        Game.world.player.y = self.y + self.height / 2

        local exit, exit_x, exit_y = self.exit, self.exit_x, self.exit_y
        if self.at_target then
            exit, exit_x, exit_y = self.start_exit, self.start_exit_x, self.start_exit_y
        end

        self.x = self.current_target_x
        self.y = self.current_target_y
        self.at_target = not self.at_target

        if exit ~= nil then
            Game.world.player:queueClimbDismount({
                x = exit_x,
                y = exit_y,
                facing = Utils.facingFromAngle(Utils.angle(self.x, self.y, exit_x, exit_y))
            })
            self.state = "RESETTING"
        else
            self.state = "WAITING_FOR_DISMOUNT"
            Game.lock_movement = false
        end
    end

    if self.state == "WAITING_FOR_DISMOUNT" then
        -- We gotta wait for the player to dismount...
        if not Game.world.player:collidesWith(self) then
            self.state = "RESETTING"
            self.timer = 0
            self:setClimbable(false)
        elseif Input.pressed("cancel") and not self.one_way then
            self.state = "IDLE"
        end
    end

    if self.state == "RESETTING" then
        local old_timer = self.timer
        self.timer = self.timer + DTMULT

        if self.one_way then
            local target_time = 1 + self.wait_time * 2
            if old_timer < target_time and self.timer >= target_time then
                self.current_target_x = self.start_x
                self.current_target_y = self.start_y

                if not self.at_target then
                    self.current_target_x = self.target_x
                    self.current_target_y = self.target_y
                end

                Game.world.timer:tween(self.travel_time / 30, self, { x = self.current_target_x, y = self.current_target_y })
            end

            target_time = 1 + (self.wait_time * 2) + self.travel_time
            if old_timer < target_time and self.timer >= target_time then
                self:setClimbable(true)
                self.state = "IDLE"
                self.timer = 0
                self.at_target = not self.at_target
                self.x = self.current_target_x
                self.y = self.current_target_y
            end
        else
            self:setClimbable(true)
            self.state = "IDLE"
            self.timer = 0
            self.x = self.current_target_x
            self.y = self.current_target_y
        end
    end

    if self.state == "MOVING" then
        local player = Game.world.player
        if player ~= nil then
            player.x = self.x + self.width / 2
            player.y = self.y + self.height / 2
        end
    end
end

return ClimbMover
