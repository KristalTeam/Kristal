local Game = {}

function Game:clear()
    if self.world and self.world.music then
        self.world.music:stop()
    end
    if self.battle and self.battle.music then
        self.battle.music:stop()
    end
    self.stage = nil
    self.world = nil
    self.battle = nil
    self.shop = nil
    self.inventory = nil
    self.fader_alpha = 0
    self.quick_save = nil
    self.lock_input = false
    --self.console = nil
end

function Game:enter(previous_state, save_id, save_name)
    self.previous_state = previous_state

    self.font = Assets.getFont("main")
    self.soul_blur = Assets.getTexture("player/heart_blur")

    self.music = Music()

    self.quick_save = nil

    Kristal.callEvent("init")

    if save_id then
        Kristal.loadGame(save_id)
    else
        self:load()
    end

    if save_name then
        self.save_name = save_name
    end

    self.started = true
    self.lock_input = false

    self.world.map:onEnter()

    if previous_state == Kristal.States["DarkTransition"] then
        self.started = false

        local px, py = self.world.player:getScreenPos()
        local kx, ky = previous_state.kris_sprite:localToScreenPos(previous_state.kris_width / 2, 0)

        previous_state.final_y = py / 2

        self.world.player:setScreenPos(kx, py)
        self.world.player.visible = false

        if not previous_state.kris_only and self.world.followers[1] then
            local sx, sy = previous_state.susie_sprite:localToScreenPos(previous_state.susie_width / 2, 0)

            self.world.followers[1]:setScreenPos(sx, py)
            self.world.followers[1].visible = false
        end
    elseif Kristal.getModOption("encounter") then
        self:encounter(Kristal.getModOption("encounter"), false)
    end

    Kristal.callEvent("postInit", self.is_new_file)
end


function Game:leave()
    self:clear()
    self.console = nil
    self.quick_save = nil
end

function Game:returnToMenu()
    self.fader:fadeOut(Kristal.returnToMenu, {speed = 0.5, music = 10/30})
    self.state = "EXIT"
end

function Game:getActiveMusic()
    if self.state == "OVERWORLD" then
        return self.world.music
    elseif self.state == "BATTLE" then
        return self.battle.music
    elseif self.state == "SHOP" then
        return self.shop.music
    else
        return self.music
    end
end

function Game:getSavePreview()
    return {
        name = self.save_name,
        level = self.save_level,
        playtime = self.playtime,
        room_name = self.world and self.world.map and self.world.map.name or "???",
    }
end

function Game:save(x, y)
    local data = {
        chapter = self.chapter,

        name = self.save_name,
        level = self.save_level,
        playtime = self.playtime,

        room_name = self.world and self.world.map and self.world.map.name or "???",
        room_id = self.world and self.world.map and self.world.map.id,

        gold = self.gold,
        xp = self.xp,

        level_up_count = self.level_up_count,

        temp_followers = self.temp_followers,

        flags = self.flags
    }

    if x then
        if type(x) == "string" then
            data.spawn_marker = x
        elseif type(x) == "table" then
            data.spawn_position = x
        elseif x and y then
            data.spawn_position = {x, y}
        end
    end

    data.party = {}
    for _,party in ipairs(self.party) do
        table.insert(data.party, party.id)
    end

    data.inventory = self.inventory:save()

    data.party_data = {}
    for k,v in pairs(self.party_data) do
        data.party_data[k] = v:save()
    end

    Kristal.callEvent("save", data)

    return data
end

function Game:load(data, index)
    self.is_new_file = data == nil

    data = data or {}

    self:clear()

    -- states: OVERWORLD, BATTLE, SHOP, GAMEOVER
    self.state = "OVERWORLD"

    self.stage = Stage()

    self.world = World()
    self.stage:addChild(self.world)

    if not self.console then
        self.console = Console()
        self.stage:addChild(self.console)
    else
        self.console:setParent(self.stage)
    end

    self.fader = Fader()
    self.fader:fadeIn(nil, {alpha = 1, speed = 0.5})
    self.fader.layer = 1000
    self.stage:addChild(self.fader)

    self.battle = nil

    self.shop = nil

    self.max_followers = Kristal.getModOption("maxFollowers") or 10

    -- BEGIN SAVE FILE VARIABLES --

    self.chapter = data.chapter or Kristal.getModOption("chapter") or 2

    self.save_name = data.name or "PLAYER"
    self.save_level = data.level or self.chapter
    self.save_id = index or self.save_id or 1

    self.playtime = data.playtime or 0

    self.flags = data.flags or {}

    self:initPartyMembers()
    if data.party_data then
        for k,v in pairs(data.party_data) do
            if self.party_data[k] then
                self.party_data[k]:load(v)
            end
        end
    end

    self.party = {}
    for _,id in ipairs(data.party or Kristal.getModOption("party") or {"kris"}) do
        table.insert(self.party, self:getPartyMember(id))
    end

    self.inventory = Inventory()
    if data.inventory then
        self.inventory:load(data.inventory)
    else
        for storage,items in pairs(Kristal.getModOption("inventory") or {}) do
            for i,item in ipairs(items) do
                self.inventory:addItemTo(storage, item, i)
            end
        end
    end

    self.temp_followers = data.temp_followers or {}

    self.level_up_count = data.level_up_count or 0

    self.gold = data.gold or 0
    self.xp = data.xp or 0

    local room_id = data.room_id or Kristal.getModOption("map")
    if room_id then
        self.world:loadMap(room_id)
    end

    -- END SAVE FILE VARIABLES --

    self.world:spawnParty(data.spawn_marker or data.spawn_position)

    Kristal.callEvent("load", data, self.is_new_file, index)
end

function Game:isLight()
    return self.world and self.world.light or false
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
    self.soul:setColor(self:getSoulColor())
    self.soul.x = x
    self.soul.y = y

    self.stage:addChild(self.soul)

    self.gameover_timer = 0
    self.gameover_stage = 0
    self.fader_alpha = 0
    self.gameover_skipping = 0
    self.fade_white = false
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
            shard:setColor(self.soul:getColor())
            shard.physics.direction = math.rad(Utils.random(360))
            shard.physics.speed = 7
            shard.physics.gravity = 0.2
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
        self.gameover_text = Sprite("ui/gameover", 0, 40)
        self.gameover_text:setScale(2)
        self.gameover_alpha = 0
        self.stage:addChild(self.gameover_text)
        self.gameover_text:setColor(1, 1, 1, self.gameover_alpha)
        self.gameover_stage = 5
    end
    if (self.gameover_timer >= 180) and (self.gameover_stage == 5) then
        local options = {}
        local main_chara = self:getSoulPartyMember()
        for _, member in ipairs(self.party) do
            if member ~= main_chara and member:getGameOverMessage(main_chara) then
                table.insert(options, member)
            end
        end
        if #options == 0 then
            self.gameover_stage = 7
        else
            local member = Utils.pick(options)
            local voice = member:getActor().voice or "default"
            self.gameover_lines = {}
            for _,dialogue in ipairs(member:getGameOverMessage(main_chara)) do
                local full_line = "[speed:0.5][spacing:8][voice:"..voice.."]"
                local lines = Utils.split(dialogue, "\n")
                for i,line in ipairs(lines) do
                    if i > 1 then
                        full_line = full_line.."\n  "..line
                    else
                        full_line = full_line.."  "..line
                    end
                end
                table.insert(self.gameover_lines, full_line)
            end
            self.gameover_dialogue = DialogueText(self.gameover_lines[1], 50*2, 151*2, nil, nil, nil, "none")
            self.gameover_dialogue.line_offset = 14
            self.gameover_dialogue.skip_speed = true
            self.stage:addChild(self.gameover_dialogue)
            table.remove(self.gameover_lines, 1)
            self.gameover_stage = 6
        end
    end
    if (self.gameover_stage == 6) and Input.pressed("confirm") and (not self.gameover_dialogue:isTyping()) then
        if #self.gameover_lines > 0 then
            self.gameover_dialogue:setText(self.gameover_lines[1])
            self.gameover_dialogue.line_offset = 14
            table.remove(self.gameover_lines, 1)
        else
            self.gameover_dialogue:remove()
            self.gameover_stage = 7
        end
    end
    if (self.gameover_stage == 7) then
        self.gameover_stage = 8
        self.gameover_selected = 1
        self.gameover_fadebuffer = 10
        self.gameover_ideal_x = 80 + (self.font:getWidth("CONTINUE") / 4 - 10)
        self.gameover_ideal_y = 180
        self.gameover_heart_x = self.gameover_ideal_x
        self.gameover_heart_y = self.gameover_ideal_y
        self.gameover_choicer_done = false
    end

    if (self.gameover_stage == 8) then
        self.gameover_fadebuffer = self.gameover_fadebuffer - DTMULT

        if self.gameover_fadebuffer < 0 then
            if Input.pressed("left") then self.gameover_selected = 1 end
            if Input.pressed("right") then self.gameover_selected = 2 end
            if self.gameover_selected == 1 then
                self.gameover_ideal_x = 80   + (self.font:getWidth("CONTINUE") / 4 - 10)  --((string_width(NAME[CURX][CURY]) / 2) - 10)
                self.gameover_ideal_y = 180
            else
                self.gameover_ideal_x = 190  + (self.font:getWidth("GIVE UP") / 4 - 10)
                self.gameover_ideal_y = 180
            end

            if Input.pressed("confirm") then
                self.gameover_choicer_done = true
                self.music:stop()
                if self.gameover_selected == 1 then
                    self.gameover_stage = 9

                    self.gameover_timer = 0
                else
                    self.gameover_text:remove()
                    self.gameover_stage = 20

                    self.gameover_dialogue = DialogueText("[noskip][speed:0.5][spacing:8][voice:none] THEN THE WORLD[wait:30] \n WAS COVERED[wait:30] \n IN DARKNESS.", 60*2, 81*2, nil, nil, nil, "GONER")
                    self.gameover_dialogue.line_offset = 14
                    self.stage:addChild(self.gameover_dialogue)
                end
            end
        end
    end

    if (self.gameover_stage == 9) then
        if (self.gameover_timer >= 30) then
            self.gameover_timer = 0
            self.gameover_stage = 10
            local sound = Assets.newSound("snd_dtrans_lw")
            sound:play()
            self.fade_white = true
        end
    end

    if (self.gameover_stage == 10) then
        self.fade_white = true
        self.fader_alpha = self.fader_alpha + (0.01 * DTMULT)
        if self.gameover_timer >= 120 then
            self.gameover_stage = 11
            self:loadQuick()
        end
    end

    if (self.gameover_stage == 20) and Input.pressed("confirm") and (not self.gameover_dialogue:isTyping()) then
        self.gameover_dialogue:remove()
        self.music:play("AUDIO_DARKNESS")
        self.music.source:setLooping(false)
        self.gameover_stage = 21
    end

    if (self.gameover_stage == 21) and (not self.music:isPlaying()) then
        if Kristal.getModOption("hardReset") then
            love.event.quit("restart")
        else
            Kristal.returnToMenu()
        end
        self.gameover_stage = 0
    end




    if (self.gameover_choicer_done) then
        if self.gameover_fadebuffer < 0 then
            self.gameover_fadebuffer = 0
        end
        self.gameover_fadebuffer = self.gameover_fadebuffer + DTMULT
    end

    if (self.gameover_stage >= 8) and self.gameover_fadebuffer < 10 then
        if (math.abs(self.gameover_heart_x - self.gameover_ideal_x) <= 2) then
            self.gameover_heart_x = self.gameover_ideal_x
        end
        if (math.abs(self.gameover_heart_y - self.gameover_ideal_y) <= 2) then
            self.gameover_heart_y = self.gameover_ideal_y
        end

        local HEARTDIFF = ((self.gameover_ideal_x - self.gameover_heart_x) * 0.3)
        self.gameover_heart_x = self.gameover_heart_x + (HEARTDIFF * DTMULT)

        HEARTDIFF = ((self.gameover_ideal_y - self.gameover_heart_y) * 0.3)
        self.gameover_heart_y = self.gameover_heart_y + (HEARTDIFF * DTMULT)
    end

    if ((self.gameover_timer >= 80) and (self.gameover_timer < 150)) then
        if Input.pressed("confirm") then
            self.gameover_skipping = self.gameover_skipping + 1
        end
        if (self.gameover_skipping >= 4) then
            self:loadQuick()
        end
    end

    if self.gameover_text then
        self.gameover_alpha = self.gameover_alpha + (0.02 * DTMULT)
        self.gameover_text:setColor(1, 1, 1, self.gameover_alpha)
    end
end

function Game:saveQuick(...)
    self.quick_save = Utils.copy(self:save(...), true)
end

function Game:loadQuick()
    local save = self.quick_save
    if save then
        self:load(save, self.save_id)
    else
        Kristal.loadGame(self.save_id)
    end
    self.quick_save = save
end

function Game:encounter(encounter, transition, enemy)
    if transition == nil then transition = true end

    if self.battle then
        error("Attempt to enter battle while already in battle")
    end

    self.encounter_enemy = enemy

    self.state = "BATTLE"

    self.battle = Battle()
    if type(transition) == "string" then
        self.battle:postInit(transition, encounter)
    else
        self.battle:postInit(transition and "TRANSITION" or "INTRO", encounter)
    end
    self.stage:addChild(self.battle)
end

function Game:setupShop(shop)
    if self.shop then
        error("Attempt to enter shop while already in shop")
    end

    if type(shop) == "string" then
        shop = Registry.createShop(shop)
    end

    if shop == nil then
        error("Attempt to enter shop with nil shop")
    end

    self.shop = shop
    self.shop:postInit()
end

function Game:enterShop(shop)
    -- Add the shop to the stage and enter it.
    if not self.shop then
        error("Attempt to enter shop without calling setupShop")
    end

    self.state = "SHOP"

    self.stage:addChild(self.shop)
    self.shop:onEnter()
end

function Game:setVolume(volume)
    MASTER_VOLUME = math.max(0, math.min(1, volume))
    love.audio.setVolume(MASTER_VOLUME)
end

function Game:getVolume()
    return MASTER_VOLUME or 1
end

function Game:setFlag(flag, value)
    self.flags[flag] = value
end

function Game:getFlag(flag, default)
    local result = self.flags[flag]
    if result == nil then
        return default
    else
        return result
    end
end

function Game:initPartyMembers()
    self.party_data = {}
    for id,_ in pairs(Registry.party_members) do
        self.party_data[id] = Registry.createPartyMember(id)
    end
end

function Game:getPartyMember(id)
    if self.party_data[id] then
        return self.party_data[id]
    end
end

function Game:addPartyMember(chara, index)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    if index then
        table.insert(self.party, index, chara)
    else
        table.insert(self.party, chara)
    end
end

function Game:removePartyMember(chara)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    Utils.removeFromTable(self.party, chara)
end

function Game:hasPartyMember(chara)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    for _,party_member in ipairs(self.party) do
        if party_member.id == chara.id then
            return true
        end
    end
    return false
end

function Game:movePartyMember(chara, index)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    self:removePartyMember(chara)
    self:addPartyMember(chara, index)
end

function Game:getSoulPartyMember()
    local current
    for _,party in ipairs(self.party) do
        if not current or (party.soul_priority > current.soul_priority) then
            current = party
        end
    end
    return current
end

function Game:getSoulColor()
    local chara = Game:getSoulPartyMember()

    local r, g, b, a = 1, 0, 0, 1

    if chara and chara.soul_priority >= 0 and chara.soul_color then
        r, g, b, a = chara.soul_color[1] or 1, chara.soul_color[2] or 1, chara.soul_color[3] or 1, chara.soul_color[4] or 1
    end

    return r, g, b, a
end

function Game:getActLeader()
    for _,party in ipairs(self.party) do
        if party.has_act then
            return party
        end
    end
end

function Game:update(dt)
    if self.state == "EXIT" then
        self.fader:update(dt)
        return
    end

    if self.previous_state and self.previous_state.animation_active then
        self.previous_state:update(dt)
        self.lock_input = true
    elseif not self.started then
        self.started = true
        self.lock_input = false
        if self.world.player then
            self.world.player.visible = true
        end
        for _,follower in ipairs(self.world.followers) do
            follower.visible = true
        end
        if Kristal.getModOption("encounter") then
            self:encounter(Kristal.getModOption("encounter"), self.world.player ~= nil)
        end
    end

    if Kristal.callEvent("preUpdate", dt) then
        return
    end

    if (self.state == "BATTLE" and self.battle and self.battle:isWorldHidden()) or
       (self.state == "SHOP"   and self.shop) then
        self.world.active = false
        self.world.visible = false
    else
        self.world.active = true
        self.world.visible = true
    end

    self.playtime = self.playtime + dt

    self.stage:update(dt)

    if self.state == "GAMEOVER" then
        self:updateGameOver(dt)
    end

    Kristal.callEvent("postUpdate", dt)
end

function Game:textinput(key)
    self.console:textinput(key)
end

function Game:keypressed(key)
    if self.previous_state and self.previous_state.animation_active then return end

    if Kristal.callEvent("onKeyPressed", key) then
        return
    end

    self.console:keypressed(key)

    if self.state == "BATTLE" then
        if self.battle then
            self.battle:keypressed(key)
        end
    elseif self.state == "OVERWORLD" then
        if self.world then
            self.world:keypressed(key)
        end
    elseif self.state == "SHOP" then
        if self.shop then
            self.shop:keypressed(key)
        end
    end
end

function Game:draw()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.push()
    if Kristal.callEvent("preDraw") then
        love.graphics.pop()
        if self.previous_state and self.previous_state.animation_active then
            self.previous_state:draw()
        end
        return
    end
    love.graphics.pop()

    self.stage:draw()

    if self.state == "GAMEOVER" then
        if self.gameover_screenshot then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.gameover_screenshot)
        end
        if (self.gameover_stage >= 8) and (self.gameover_fadebuffer < 10)then
            local xfade = ((10 - self.gameover_fadebuffer) / 10)
            if (xfade > 1) then
                xfade = 1
            end

            local soul_r, soul_g, soul_b, soul_a = self:getSoulColor()
            love.graphics.setColor(soul_r, soul_g, soul_b, soul_a * xfade * 0.6)

            love.graphics.draw(self.soul_blur, self.gameover_heart_x * 2, self.gameover_heart_y * 2, 0, 2, 2)

            love.graphics.setFont(self.font)
            love.graphics.setColor(1, 1, 1, xfade)
            if self.gameover_selected == 1 then
                love.graphics.setColor(1, 1, 0, xfade)
            end
            love.graphics.print("CONTINUE", 160, 360)
            love.graphics.setColor(1, 1, 1, xfade)
            if self.gameover_selected == 2 then
                love.graphics.setColor(1, 1, 0, xfade)
            end
            love.graphics.print("GIVE UP", 380, 360)
        end
    end

    if self.fade_white then
        love.graphics.setColor(1, 1, 1, self.fader_alpha)
    else
        love.graphics.setColor(0, 0, 0, self.fader_alpha)
    end
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.push()
    Kristal.callEvent("postDraw")
    love.graphics.pop()

    if self.previous_state and self.previous_state.animation_active then
        self.previous_state:draw(true)
    end
end

return Game