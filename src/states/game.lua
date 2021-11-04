local Game = {}

function Game:enter(previous_state)
    self.previous_state = previous_state

    -- states: OVERWORLD, BATTLE, SHOP
    self.state = "OVERWORLD"

    self.stage = Stage()

    self.world = World()
    self.stage:addChild(self.world)

    self.battle = nil

    self.party = {}
    for _,id in ipairs(Kristal.getModOption("party") or {"kris"}) do
        table.insert(self.party, Registry.getPartyMember(id))
    end

    self.max_followers = Kristal.getModOption("maxFollowers") or 10
    self.followers = {}

    self.started = true

    self.lock_input = false

    if Kristal.getModOption("map") then
        self.world:loadMap(Kristal.getModOption("map"))
    end

    self.world:spawnPlayer("spawn", self.party[1] and self.party[1].actor or "kris")
    for i = 2, #self.party do
        local follower = Follower(Registry.getActor(self.party[i].actor), self.world.player.x, self.world.player.y)
        follower.layer = self.world.layers["objects"]
        table.insert(self.world.followers, follower)
        self.world:addChild(follower)
    end

    if previous_state == Kristal.States["DarkTransition"] then
        self.started = false

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
    elseif Kristal.getModOption("encounter") then
        self:encounter(Kristal.getModOption("encounter"), false)
    end

    Kristal.modCall("init")
end

function Game:encounter(encounter, transition, enemy)
    if transition == nil then transition = true end

    if self.battle then
        error("Attempt to enter battle while already in battle")
    end

    if type(encounter) == "string" then
        local encounter_name = encounter
        encounter = Registry.getEncounter(encounter_name)
        if not encounter then
            error("Attempt to load into non existent encounter \"" .. encounter_name .. "\"")
        end
    end

    self.encounter_enemy = enemy

    self.state = "BATTLE"

    self.battle = Battle()
    self.battle:postInit(transition and "TRANSITION" or "INTRO", encounter)
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
        if Kristal.getModOption("encounter") then
            self:encounter(Kristal.getModOption("encounter"), self.world.player ~= nil)
        end
    end

    if Kristal.modCall("preUpdate", dt) then
        return
    end

    Cutscene.update(dt)

    if self.world.player and -- If the player exists,
       not self.lock_input -- and input isn't locked,
       and self.state == "OVERWORLD" -- and we're in the overworld state,
       and self.world.state == "GAMEPLAY" then -- and the world is in the gameplay state,
        Game:handleMovement()
    end

    if self.state == "BATTLE" and self.battle then
        self.world.active = false
        if self.battle.background_fade_alpha >= 1 then
            self.world.visible = false
        end
    else
        self.world.active = true
        self.world.visible = true
    end

    self.stage:update(dt)

    Kristal.modCall("postUpdate", dt)
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
        self.world.camera.y = Utils.approach(self.world.camera.y, self.world.player.y - (self.world.player.height * 2)/2, 12 * DTMULT)
    end
end

function Game:keypressed(key)
    if self.previous_state and self.previous_state.animation_active then return end

    if Kristal.modCall("onKeyPressed", key) then
        return
    end

    if self.state == "BATTLE" then
        if self.battle then
            self.battle:keypressed(key)
        end
    elseif self.state == "OVERWORLD" then
        if not self.lock_input then
            if self.world.player then -- TODO: move this to function in world.lua
                if Input.isConfirm(key) then
                    self.world.player:interact()
                elseif key == "f" then
                    print(Utils.dump(self.world.player.history))
                elseif key == "v" then
                    self.world.in_battle = not self.world.in_battle
                end
            end
        elseif self.cutscene_active then
            Cutscene.keypressed(key)
        end
    end
end

function Game:draw()
    love.graphics.push()
    if Kristal.modCall("preDraw") then
        love.graphics.pop()
        if self.previous_state and self.previous_state.animation_active then
            self.previous_state:draw()
        end
        return
    end
    love.graphics.pop()

    self.stage:draw()

    love.graphics.push()
    Kristal.modCall("postDraw")
    love.graphics.pop()

    if self.previous_state and self.previous_state.animation_active then
        self.previous_state:draw(true)
    end
end

return Game