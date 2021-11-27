local Player, super = Class(Character)

function Player:init(chara, x, y)
    super:init(self, chara, x, y)

    local hx, hy, hw, hh = self.collider.x, self.collider.y, self.collider.width, self.collider.height

    self.interact_collider = {
        ["left"] = Hitbox(self, hx - hw/2, hy, hw, hh),
        ["right"] = Hitbox(self, hx + hw/2, hy, hw, hh),
        ["up"] = Hitbox(self, hx, hy - hh/2, hw, hh),
        ["down"] = Hitbox(self, hx, hy + hh/2, hw, hh)
    }

    self.force_run = false
    self.run_timer = 0

    self.hurt_timer = 0

    self.walk_speed = 4

    self.history_time = 0
    self.history = {}

    self.battle_canvas = love.graphics.newCanvas(320, 240)
    self.battle_alpha = 0

    self.persistent = true
    self.noclip = false
end

function Player:onAdd(parent)
    super:onAdd(self, parent)

    if parent:includes(World) and not parent.player then
        parent.player = self
    end
end

function Player:onRemove(parent)
    super:onRemove(self, parent)

    if parent:includes(World) and parent.player == self then
        parent.player = nil
    end
end

function Player:interact()
    local col = self.interact_collider[self.facing]

    for _,obj in ipairs(self.world.children) do
        if obj.onInteract and obj:collidesWith(col) and obj:onInteract(self, self.facing) then
            return true
        end
    end

    return false
end

function Player:alignFollowers(facing, x, y, dist)
    local ex, ey = self:getExactPosition()

    facing = facing or self.facing
    x, y = x or ex, y or ey

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

    self.history = {{x = ex, y = ey, time = self.history_time}}
    for i = 1, Game.max_followers do
        local idist = dist and (i * dist) or (((i * FOLLOW_DELAY) / (1/30)) * 4)
        table.insert(self.history, {x = x + (offset_x * idist), y = y + (offset_y * idist), facing = facing, time = self.history_time - (i * FOLLOW_DELAY)})
    end
end

function Player:keepFollowerPositions()
    local ex, ey = self:getExactPosition()

    self.history = {{x = ex, y = ey, time = self.history_time}}
    for i,follower in ipairs(Game.world.followers) do
        local fex, fey = follower:getExactPosition()
        table.insert(self.history, {x = fex, y = fey, facing = follower.facing, time = self.history_time - (i * FOLLOW_DELAY)})
    end
end

function Player:isMovementEnabled()
    return not Game.lock_input
        and Game.state == "OVERWORLD"
        and self.world.state == "GAMEPLAY"
        and self.hurt_timer == 0
end

function Player:handleMovement()
    local walk_x = 0
    local walk_y = 0

    if Input.down("right") then walk_x = walk_x + 1 end
    if Input.down("left") then walk_x = walk_x - 1 end
    if Input.down("down") then walk_y = walk_y + 1 end
    if Input.down("up") then walk_y = walk_y - 1 end

    local running = Input.down("cancel") or self.force_run
    if Kristal.Config["autoRun"] and not self.force_run then
        running = not running
    end

    if self.force_run then
        self.run_timer = 200
    end

    local speed = self.walk_speed
    if running then
        if self.run_timer > 60 then
            speed = speed + 5
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
        else
            self.run_timer = 0
        end
    end

    if self.world.player == self and self.world.camera_attached and (walk_x ~= 0 or walk_y ~= 0) then
        self.world.camera.x = Utils.approach(self.world.camera.x, self.x, 12 * DTMULT)
        self.world.camera.y = Utils.approach(self.world.camera.y, self.y - (self.height * 2)/2, 12 * DTMULT)
    end
end

function Player:update(dt)
    if self.hurt_timer > 0 then
        self.hurt_timer = Utils.approach(self.hurt_timer, 0, DTMULT)
    end

    if self:isMovementEnabled() then
        self:handleMovement()
    end

    if #self.history == 0 then
        local ex, ey = self:getExactPosition()
        table.insert(self.history, {x = ex, y = ey, time = 0})
    end

    if self.moved > 0 then
        self.history_time = self.history_time + dt

        local ex, ey = self:getExactPosition()

        if self.last_collided_x then
            ex = self.x
        end
        if self.last_collided_y then
            ey = self.y
        end

        table.insert(self.history, 1, {x = ex, y = ey, facing = self.facing, time = self.history_time})
        while (self.history_time - self.history[#self.history].time) > (Game.max_followers * FOLLOW_DELAY) do
            table.remove(self.history, #self.history)
        end

        for _,follower in ipairs(self.world.followers) do
            if follower:getTarget() == self and follower.following then
                follower:interprolate()
            end
        end
    end

    self.world.in_battle = false
    for _,area in ipairs(self.world.map.battle_areas) do
        if area:collidesWith(self.collider) then
            self.world.in_battle = true
            break
        end
    end

    if self.world.in_battle then
        self.battle_alpha = math.min(self.battle_alpha + (0.04 * DTMULT), 0.8)
    else
        self.battle_alpha = math.max(self.battle_alpha - (0.08 * DTMULT), 0)
    end

    super:update(self, dt)
end

function Player:draw()
    -- Draw the player
    super:draw(self)

    -- Now we need to draw their battle mode overlay
    if self.battle_alpha > 0 then
        Draw.pushCanvas(self.battle_canvas)

        -- Let's draw in the middle of the canvas so the left doesnt get cut off
        -- There's more elegant ways to do this but whatever
        -- TODO: make the canvas size fit to the player instead of forcing 320x240
        love.graphics.translate(320 / 2, 240 / 2)

        love.graphics.clear()

        love.graphics.setShader(Kristal.Shaders["AddColor"])

        -- Left
        love.graphics.translate(-1, 0)
        Kristal.Shaders["AddColor"]:send("inputcolor", {1, 0, 0})
        Kristal.Shaders["AddColor"]:send("amount", 1)
        super:draw(self)

        -- Right
        love.graphics.translate(2, 0)
        Kristal.Shaders["AddColor"]:send("inputcolor", {1, 0, 0})
        Kristal.Shaders["AddColor"]:send("amount", 1)
        super:draw(self)

        -- Up
        love.graphics.translate(-1, -1)
        Kristal.Shaders["AddColor"]:send("inputcolor", {1, 0, 0})
        Kristal.Shaders["AddColor"]:send("amount", 1)
        super:draw(self)

        -- Down
        love.graphics.translate(0, 2)
        Kristal.Shaders["AddColor"]:send("inputcolor", {1, 0, 0})
        Kristal.Shaders["AddColor"]:send("amount", 1)
        super:draw(self)

        -- Center
        love.graphics.translate(0, -1)
        Kristal.Shaders["AddColor"]:send("inputcolor", {32/255, 32/255, 32/255})
        Kristal.Shaders["AddColor"]:send("amount", 1)
        super:draw(self)

        love.graphics.setShader()

        Draw.popCanvas()

        love.graphics.setColor(1, 1, 1, self.battle_alpha)
        love.graphics.draw(self.battle_canvas, -320 / 2, -240 / 2)

        love.graphics.setColor(1, 1, 1, 1)
    end

    local col = self.interact_collider[self.facing]
    if DEBUG_RENDER then
        col:draw(1, 0, 0, 0.5)
    end
end

return Player