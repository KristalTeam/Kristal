---@class Player : Character
---@overload fun(...) : Player
local Player, super = Class(Character)

function Player:init(chara, x, y)
    super.init(self, chara, x, y)

    self.is_player = true

    self.slide_sound = Assets.newSound("paper_surf")
    self.slide_sound:setLooping(true)

    self.state_manager = StateManager("WALK", self, true)
    self.state_manager:addState("WALK", { update = self.updateWalk })
    self.state_manager:addState("SLIDE", { update = self.updateSlide, enter = self.beginSlide, leave = self.endSlide })

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
    self.walk_speed = Game:isLight() and 6 or 4

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
end

function Player:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "State: " .. self.state_manager.state)
    table.insert(info, "Walk speed: " .. self.walk_speed)
    table.insert(info, "Run timer: " .. self.run_timer)
    table.insert(info, "Hurt timer: " .. self.hurt_timer)
    table.insert(info, "Slide in place: " .. (self.slide_in_place and "True" or "False"))
    return info
end

function Player:getDebugOptions(context)
    context = super.getDebugOptions(self, context)
    context:addMenuItem("Toggle force run", "Toggle if the player is forced to run or not",
        function () self.force_run = not self.force_run end)
    context:addMenuItem("Toggle force walk", "Toggle if the player is forced to walk or not",
        function () self.force_walk = not self.force_walk end)
    return context
end

function Player:onAdd(parent)
    super.onAdd(self, parent)

    if parent:includes(World) and not parent.player then
        parent.player = self
    end
end

function Player:onRemove(parent)
    super.onRemove(self, parent)

    self.slide_sound:stop()
    if parent:includes(World) and parent.player == self then
        parent.player = nil
    end
end

function Player:onRemoveFromStage(stage)
    super.onRemoveFromStage(self, stage)
    self.slide_sound:stop()
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

    local col = self.interact_collider[self.facing]

    local interactables = {}
    for _, obj in ipairs(self.world.children) do
        if obj.onInteract and obj:collidesWith(col) then
            local rx, ry = obj:getRelativePos(obj.width / 2, obj.height / 2, self.parent)
            table.insert(interactables, { obj = obj, dist = Utils.dist(self.x, self.y, rx, ry) })
        end
    end
    table.sort(interactables, function (a, b) return a.dist < b.dist end)
    for _, v in ipairs(interactables) do
        if v.obj:onInteract(self, self.facing) then
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
    facing = facing or self.facing
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
        table.insert(self.history,
            { x = x + (offset_x * idist), y = y + (offset_y * idist), facing = facing,
                time = self.history_time - (i * FOLLOW_DELAY) })
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
    return not (self.state_manager.state == "SLIDE" and self.slide_in_place)
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

    if     Input.down("left")  then walk_x = walk_x - 1
    elseif Input.down("right") then walk_x = walk_x + 1 end
    if     Input.down("up")    then walk_y = walk_y - 1
    elseif Input.down("down")  then walk_y = walk_y + 1 end

    self.moving_x = walk_x
    self.moving_y = walk_y

    local running = (Input.down("cancel") or self.force_run) and not self.force_walk
    if Kristal.Config["autoRun"] and not self.force_run and not self.force_walk then
        running = not running
    end

    if self.force_run and not self.force_walk then
        self.run_timer = 200
    end

    local speed = self.walk_speed
    if running then
        if self.run_timer > 60 then
            speed = speed + (Game:isLight() and 6 or 5)
        elseif self.run_timer > 10 then
            speed = speed + 4
        else
            speed = speed + 2
        end
    end

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

function Player:isMoving()
    return self.moving_x ~= 0 or self.moving_y ~= 0
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
    self.slide_dust_timer = Utils.approach(self.slide_dust_timer, 0, DTMULT)

    if self.slide_dust_timer == 0 then
        self.slide_dust_timer = 3

        local dust = Sprite("effects/slide_dust")
        dust:play(1 / 15, false, function () dust:remove() end)
        dust:setOrigin(0.5, 0.5)
        dust:setScale(2, 2)
        dust:setPosition(self.x, self.y)
        dust.layer = self.layer - 0.01
        dust.physics.speed_y = -6
        dust.physics.speed_x = Utils.random(-1, 1)
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
    local speed = self.walk_speed + 4

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

function Player:updateHistory()
    if #self.history == 0 then
        table.insert(self.history, { x = self.x, y = self.y, time = 0 })
    end

    local moved = self.x ~= self.last_move_x or self.y ~= self.last_move_y

    local auto = self.auto_moving

    if moved then
        self.history_time = self.history_time + DT

        table.insert(self.history, 1,
            { x = self.x, y = self.y, facing = self.facing, time = self.history_time, state = self.state_manager.state,
                state_args = self.state_manager.args, auto = auto })
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

function Player:update()
    if self.hurt_timer > 0 then
        self.hurt_timer = Utils.approach(self.hurt_timer, 0, DTMULT)
    end

    if self.slide_land_timer > 0 and self.state_manager.state ~= "SLIDE" then
        self.slide_land_timer = Utils.approach(self.slide_land_timer, 0, DTMULT)
        if self.slide_land_timer == 0 then
            self.slide_sound:stop()
            self.sprite:resetSprite()
            self.slide_lock_movement = false
        end
    end

    self.state_manager:update()

    self:updateHistory()

    if not Game.world.cutscene and not Game.world.menu then
        self.interact_buffer = Utils.approach(self.interact_buffer, 0, DT)
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

function Player:draw()
    -- Draw the player
    super.draw(self)

    local col = self.interact_collider[self.facing]
    if DEBUG_RENDER then
        col:draw(1, 0, 0, 0.5)
    end
end

return Player
