local Game = {}

function Game:enter(previous_state)
    self.previous_state = previous_state

    self.stage = Stage()

    self.world = World()
    self.stage:addChild(self.world)

    self.started = true

    self.lock_input = false

    if MOD and MOD.map then
        self.world:loadMap(MOD.map)
        self.world:spawnPlayer("spawn", MOD.party and MOD.party[1] or "kris")

        if previous_state == Kristal.States["DarkTransition"] then
            local px, py = self.world.player:getScreenPos()
            local kx, ky = previous_state.kris_sprite:localToScreenPos(previous_state.kris_width / 2, 0)

            previous_state.final_y = py / 2

            self.world.player:setScreenPos(kx, py)
            self.world.player.visible = false

            self.started = false
        end
    end

    Kristal.modCall("Init")
end

function Game:update(dt)
    if self.previous_state and self.previous_state.animation_active then
        self.previous_state:update(dt)
        self.lock_input = true
    elseif not self.started then
        self.started = true
        self.lock_input = false
        if self.world.player then
            self.world.player.visible = true
        end
    end

    if Kristal.modCall("PreUpdate", dt) then
        return
    end

    Cutscene:update(dt)

    if self.world.player and not self.lock_input then
        local walk_x = 0
        local walk_y = 0

        if love.keyboard.isDown("right") then walk_x = walk_x + 1 end
        if love.keyboard.isDown("left") then walk_x = walk_x - 1 end
        if love.keyboard.isDown("down") then walk_y = walk_y + 1 end
        if love.keyboard.isDown("up") then walk_y = walk_y - 1 end

        self.world.player:walk(walk_x, walk_y, love.keyboard.isDown("lshift") or love.keyboard.isDown("x"))

        if walk_x ~= 0 or walk_y ~= 0 then
            self.world.camera.x = Utils.approach(self.world.camera.x, self.world.player.x, 12 * DTMULT)
            self.world.camera.y = Utils.approach(self.world.camera.y, self.world.player.y, 12 * DTMULT)
        end
    end

    self.stage:update(dt)

    Kristal.modCall("PostUpdate", dt)
end

function Game:keypressed(key)
    if self.previous_state and self.previous_state.animation_active then return end

    if Kristal.modCall("KeyPressed", key) then
        return
    end

    if key == "z" and self.world.player then
        self.world.player:interact()
    end
end

function Game:draw()
    love.graphics.push()
    if Kristal.modCall("PreDraw") then
        love.graphics.pop()
        if self.previous_state and self.previous_state.animation_active then
            self.previous_state:draw()
        end
        return
    end
    love.graphics.pop()

    self.stage:draw()

    love.graphics.push()
    Kristal.modCall("PostDraw")
    love.graphics.pop()

    if self.previous_state and self.previous_state.animation_active then
        self.previous_state:draw(true)
    end
end

return Game