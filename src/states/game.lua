local Game = {}

function Game:enter(previous_state)
    self.previous_state = previous_state

    -- states: OVERWORLD, BATTLE, SHOP
    self.state = "OVERWORLD"

    self.stage = Stage()

    self.world = World()
    self.stage:addChild(self.world)

    self.battle = nil

    self.max_followers = MOD["maxFollowers"] or 10
    self.followers = {}

    self.started = true

    self.lock_input = false

    if MOD and MOD.map then
        self.world:loadMap(MOD.map)
        self.world:spawnPlayer("spawn", MOD.party and MOD.party[1] or "kris")

        if MOD.party then
            for i = 2, #MOD.party do
                local follower = Follower(PARTY[MOD.party[i]], self.world.player.x, self.world.player.y)
                self.world:addChild(follower)
            end
        end

        if previous_state == Kristal.States["DarkTransition"] then
            local px, py = self.world.player:getScreenPos()
            local kx, ky = previous_state.kris_sprite:localToScreenPos(previous_state.kris_width / 2, 0)

            previous_state.final_y = py / 2

            self.world.player:setScreenPos(kx, py)
            self.world.player.visible = false

            if not previous_state.kris_only and self.followers[1] then
                local sx, sy = previous_state.susie_sprite:localToScreenPos(previous_state.susie_width / 2, 0)

                self.followers[1]:setScreenPos(sx, py)
                self.followers[1].visible = false
            end

            self.started = false
        end
    end

    Kristal.modCall("Init")
end

function Game:encounter(transition, background, music)
    if transition == nil then transition = true end
    if background == nil then background = true end

    if self.battle then
        error("Attempt to enter battle while already in battle")
    end

    self.state = "BATTLE"

    self.battle = Battle(transition and "TRANSITION" or "INTRO", background, music)

    self.stage:addChild(self.battle)
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
        for _,follower in ipairs(self.followers) do
            follower.visible = true
        end
    end

    if Kristal.modCall("PreUpdate", dt) then
        return
    end

    Cutscene:update(dt)

    if self.world.player and -- If the player exists,
       not self.lock_input -- and input isn't locked,
       and self.state == "OVERWORLD" then -- and we're in the overworld state,
        Game:handleMovement()
    end

    self.stage:update(dt)

    Kristal.modCall("PostUpdate", dt)
end

function Game:handleMovement()
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

function Game:keypressed(key)
    if self.previous_state and self.previous_state.animation_active then return end

    if Kristal.modCall("KeyPressed", key) then
        return
    end

    if self.world.player then
        if key == "z" then
            self.world.player:interact()
        elseif key == "f" then
            print(Utils.dump(self.world.player.history))
        end
    end
    if self.battle then
        if key == "g" then
            self.battle.current_selecting = self.battle.current_selecting + 1
            if self.battle.current_selecting > 3 then
                self.battle.current_selecting = 1
            end
        end
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