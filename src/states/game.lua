local Game = {}

function Game:enter(previous_state)
    self.previous_state = previous_state

    -- states: OVERWORLD, BATTLE, SHOP, GAMEOVER
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

    self.inventory = {}
    for _,id in ipairs(Kristal.getModOption("inventory") or {}) do
        table.insert(self.inventory, Registry.getItem(id))
    end

    self.started = true

    self.lock_input = false

    if Kristal.getModOption("map") then
        self.world:loadMap(Kristal.getModOption("map"))
    end

    self.world:spawnParty()

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

    Game.gold = 0
    Game.xp = 0

    self.fader_alpha = 0
    self.chapter = 2

    self.music = Music()

    Kristal.modCall("init")
end

function Game:gameOver(x, y)
    self.gameover_screenshot = love.graphics.newImage(SCREEN_CANVAS:newImageData())
    self.state = "GAMEOVER"
    if self.battle then
        self.battle:remove()
    end
    if self.world then
        self.world:remove()
    end
    self.soul = Sprite("player/heart")
    self.soul:setOrigin(0.5, 0.5)
    self.soul:setColor(1, 0, 0, 1)
    self.soul.x = x
    self.soul.y = y

    self.stage:addChild(self.soul)

    self.gameover_timer = 0
    self.gameover_stage = 0
    self.fader_alpha = 0
    self.gameover_skipping = 0
end

function Game:updateGameOver(dt)
    self.gameover_timer = self.gameover_timer + DTMULT
    if (self.gameover_timer >= 30) and (self.gameover_stage == 0) then
        self.gameover_screenshot = nil
        self.gameover_stage = 1
    end
    if (self.gameover_timer >= 50) and (self.gameover_stage == 1) then
        Assets.playSound("snd_break1")
        self.soul:setSprite("player/heart_break")
        self.gameover_stage = 2
    end
    if (self.gameover_timer >= 90) and (self.gameover_stage == 2) then
        Assets.playSound("snd_break2")

        local shard_count = 6
        local x_position_table = {-2, 0, 2, 8, 10, 12}
        local y_position_table = {0, 3, 6}

        self.shards = {}
        for i = 1, shard_count do 
            local x_pos = x_position_table[((i - 1) % #x_position_table) + 1]
            local y_pos = y_position_table[((i - 1) % #y_position_table) + 1]
            local shard = Sprite("player/heart_shard", self.soul.x + x_pos, self.soul.y + y_pos)
            local direction = Utils.random(360)
            shard:setColor(self.soul:getColor())
            shard.speed_x = math.cos(direction) * 7
            shard.speed_y = math.sin(direction) * 7
            shard.gravity = 0.2
            shard:play(5/30)
            table.insert(self.shards, shard)
            self.stage:addChild(shard)
        end

        self.soul:remove()
        self.soul = nil
        self.gameover_stage = 3
    end
    if (self.gameover_timer >= 140) and (self.gameover_stage == 3) then
        self.fader_alpha = (self.gameover_timer - 140) / 10
        if self.fader_alpha >= 1 then
            for i = #self.shards, 1, -1 do
                self.shards[i]:remove()
            end
            self.shards = {}
            self.fader_alpha = 0
            self.gameover_stage = 4
        end
    end
    if (self.gameover_timer >= 150) and (self.gameover_stage == 4) then
        self.music:play("AUDIO_DEFEAT")
        self.gameover_text = Sprite("ui/gameover", 0, 20)
        self.gameover_text:setScale(2)
        self.gameover_alpha = 0
        self.stage:addChild(self.gameover_text)
        self.gameover_text:setColor(1, 1, 1, self.gameover_alpha)
        self.gameover_stage = 5
    end
    if (self.gameover_timer >= 180) and (self.gameover_stage == 5) then
        -- Next in 30 frames...
        self.gameover_dialogue = DialogueText("[speed:0.25][voice:susie]  Come on[wait:1],\n  that all you got!?", 50*2, 150*2)
        --   This is not&  your fate...!/
        self.stage:addChild(self.gameover_dialogue)
        self.gameover_stage = 6
    end
    if (self.gameover_stage == 6) and Input.pressed("confirm") and (not self.gameover_dialogue:isTyping()) then
        self.gameover_dialogue:setText("[speed:0.25][voice:susie]  Kris[wait:1],\n  get up...!")
        -- "  Please^1,&  don't give up!/%"
        self.gameover_stage = 7
    end
    if (self.gameover_stage == 7) and Input.pressed("confirm") and (not self.gameover_dialogue:isTyping()) then
        self.gameover_dialogue:remove()
    end

    if ((self.gameover_timer >= 80) and (self.gameover_timer < 150)) then
        if Input.pressed("confirm") then
            self.gameover_skipping = self.gameover_skipping + 1
        end
        if (self.gameover_skipping >= 4) then
            error("TODO: LOAD AFTER GAME OVER")
            --scr_tempload()
        end
    end

    if self.gameover_text then
        self.gameover_alpha = self.gameover_alpha + (0.02 * DTMULT)
        self.gameover_text:setColor(1, 1, 1, self.gameover_alpha)
    end
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

function Game:setVolume(volume)
    MASTER_VOLUME = volume
    love.audio.setVolume(volume)
end

function Game:getVolume()
    return MASTER_VOLUME or 1
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
    BattleScene.update(dt)

    if self.world.player and -- If the player exists,
       not self.lock_input -- and input isn't locked,
       and self.state == "OVERWORLD" -- and we're in the overworld state,
       and self.world.state == "GAMEPLAY" then -- and the world is in the gameplay state,
        Game:handleMovement()
    end

    if self.state == "BATTLE" and self.battle and self.battle:isWorldHidden() then
        self.world.active = false
        self.world.visible = false
    else
        self.world.active = true
        self.world.visible = true
    end

    self.stage:update(dt)

    if self.state == "GAMEOVER" then
        self:updateGameOver(dt)
    end

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

    if self.world.camera_attached and (walk_x ~= 0 or walk_y ~= 0) then
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
    if self.gameover_screenshot then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.gameover_screenshot)
    end

    love.graphics.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.push()
    Kristal.modCall("postDraw")
    love.graphics.pop()

    if self.previous_state and self.previous_state.animation_active then
        self.previous_state:draw(true)
    end
end

return Game