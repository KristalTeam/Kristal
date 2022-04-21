local GameOver, super = Class(Object, "gameover")

function GameOver:init(x, y)
    super:init(self, 0, 0)

    self.font = Assets.getFont("main")
    self.soul_blur = Assets.getTexture("player/heart_blur")

    self.screenshot = love.graphics.newImage(SCREEN_CANVAS:newImageData())

    self.music = Music()

    self.soul = Sprite("player/heart")
    self.soul:setOrigin(0.5, 0.5)
    self.soul:setColor(Game:getSoulColor())
    self.soul.x = x
    self.soul.y = y

    self:addChild(self.soul)

    self.current_stage = 0
    self.fader_alpha = 0
    self.skipping = 0
    self.fade_white = false

    self.timer = 0
end

function GameOver:onRemove(parent)
    super:onRemove(self, parent)

    self.music:remove()
end


function GameOver:update(dt)
    super:update(self, dt)

    self.timer = self.timer + DTMULT
    if (self.timer >= 30) and (self.current_stage == 0) then
        self.screenshot = nil
        self.current_stage = 1
    end
    if (self.timer >= 50) and (self.current_stage == 1) then
        Assets.playSound("snd_break1")
        self.soul:setSprite("player/heart_break")
        self.current_stage = 2
    end
    if (self.timer >= 90) and (self.current_stage == 2) then
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
            self:addChild(shard)
        end

        self.soul:remove()
        self.soul = nil
        self.current_stage = 3
    end
    if (self.timer >= 140) and (self.current_stage == 3) then
        self.fader_alpha = (self.timer - 140) / 10
        if self.fader_alpha >= 1 then
            for i = #self.shards, 1, -1 do
                self.shards[i]:remove()
            end
            self.shards = {}
            self.fader_alpha = 0
            self.current_stage = 4
        end
    end
    if (self.timer >= 150) and (self.current_stage == 4) then
        self.music:play("AUDIO_DEFEAT")
        self.text = Sprite("ui/gameover", 0, 40)
        self.text:setScale(2)
        self.alpha = 0
        self:addChild(self.text)
        self.text:setColor(1, 1, 1, self.alpha)
        self.current_stage = 5
    end
    if (self.timer >= 180) and (self.current_stage == 5) then
        local options = {}
        local main_chara = Game:getSoulPartyMember()
        for _, member in ipairs(Game.party) do
            if member ~= main_chara and member:getGameOverMessage(main_chara) then
                table.insert(options, member)
            end
        end
        if #options == 0 then
            self.current_stage = 7
        else
            local member = Utils.pick(options)
            local voice = member:getActor().voice or "default"
            self.lines = {}
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
                table.insert(self.lines, full_line)
            end
            self.dialogue = DialogueText(self.lines[1], 50*2, 151*2, nil, nil, nil, "none")
            self.dialogue.line_offset = 14
            self.dialogue.skip_speed = true
            self:addChild(self.dialogue)
            table.remove(self.lines, 1)
            self.current_stage = 6
        end
    end
    if (self.current_stage == 6) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        if #self.lines > 0 then
            self.dialogue:setText(self.lines[1])
            self.dialogue.line_offset = 14
            table.remove(self.lines, 1)
        else
            self.dialogue:remove()
            self.current_stage = 7
        end
    end
    if (self.current_stage == 7) then
        self.current_stage = 8
        self.selected = 1
        self.fadebuffer = 10
        self.ideal_x = 80 + (self.font:getWidth("CONTINUE") / 4 - 10)
        self.ideal_y = 180
        self.heart_x = self.ideal_x
        self.heart_y = self.ideal_y
        self.choicer_done = false
    end

    if (self.current_stage == 8) then
        self.fadebuffer = self.fadebuffer - DTMULT

        if self.fadebuffer < 0 then
            if Input.pressed("left") then self.selected = 1 end
            if Input.pressed("right") then self.selected = 2 end
            if self.selected == 1 then
                self.ideal_x = 80   + (self.font:getWidth("CONTINUE") / 4 - 10)  --((string_width(NAME[CURX][CURY]) / 2) - 10)
                self.ideal_y = 180
            else
                self.ideal_x = 190  + (self.font:getWidth("GIVE UP") / 4 - 10)
                self.ideal_y = 180
            end

            if Input.pressed("confirm") then
                self.choicer_done = true
                self.music:stop()
                if self.selected == 1 then
                    self.current_stage = 9

                    self.timer = 0
                else
                    self.text:remove()
                    self.current_stage = 20

                    self.dialogue = DialogueText("[noskip][speed:0.5][spacing:8][voice:none] THEN THE WORLD[wait:30] \n WAS COVERED[wait:30] \n IN DARKNESS.", 60*2, 81*2, nil, nil, nil, "GONER")
                    self.dialogue.line_offset = 14
                    self:addChild(self.dialogue)
                end
            end
        end
    end

    if (self.current_stage == 9) then
        if (self.timer >= 30) then
            self.timer = 0
            self.current_stage = 10
            local sound = Assets.newSound("snd_dtrans_lw")
            sound:play()
            self.fade_white = true
        end
    end

    if (self.current_stage == 10) then
        self.fade_white = true
        self.fader_alpha = self.fader_alpha + (0.01 * DTMULT)
        if self.timer >= 120 then
            self.current_stage = 11
            Game:loadQuick()
        end
    end

    if (self.current_stage == 20) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        self.dialogue:remove()
        self.music:play("AUDIO_DARKNESS")
        self.music.source:setLooping(false)
        self.current_stage = 21
    end

    if (self.current_stage == 21) and (not self.music:isPlaying()) then
        if Kristal.getModOption("hardReset") then
            love.event.quit("restart")
        else
            Kristal.returnToMenu()
        end
        self.current_stage = 0
    end

    if (self.choicer_done) then
        if self.fadebuffer < 0 then
            self.fadebuffer = 0
        end
        self.fadebuffer = self.fadebuffer + DTMULT
    end

    if (self.current_stage >= 8) and self.fadebuffer < 10 then
        if (math.abs(self.heart_x - self.ideal_x) <= 2) then
            self.heart_x = self.ideal_x
        end
        if (math.abs(self.heart_y - self.ideal_y) <= 2) then
            self.heart_y = self.ideal_y
        end

        local HEARTDIFF = ((self.ideal_x - self.heart_x) * 0.3)
        self.heart_x = self.heart_x + (HEARTDIFF * DTMULT)

        HEARTDIFF = ((self.ideal_y - self.heart_y) * 0.3)
        self.heart_y = self.heart_y + (HEARTDIFF * DTMULT)
    end

    if ((self.timer >= 80) and (self.timer < 150)) then
        if Input.pressed("confirm") then
            self.skipping = self.skipping + 1
        end
        if (self.skipping >= 4) then
            Game:loadQuick()
        end
    end

    if self.text then
        self.alpha = self.alpha + (0.02 * DTMULT)
        self.text:setColor(1, 1, 1, self.alpha)
    end
end

function GameOver:draw()
    super:draw(self)

    if self.screenshot then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.screenshot)
    end
    if (self.current_stage >= 8) and (self.fadebuffer < 10) then

        local xfade = ((10 - self.fadebuffer) / 10)
        if (xfade > 1) then
            xfade = 1
        end

        local soul_r, soul_g, soul_b, soul_a = Game:getSoulColor()
        love.graphics.setColor(soul_r, soul_g, soul_b, soul_a * xfade * 0.6)

        love.graphics.draw(self.soul_blur, self.heart_x * 2, self.heart_y * 2, 0, 2, 2)

        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1, xfade)
        if self.selected == 1 then
            love.graphics.setColor(1, 1, 0, xfade)
        end
        love.graphics.print("CONTINUE", 160, 360)
        love.graphics.setColor(1, 1, 1, xfade)
        if self.selected == 2 then
            love.graphics.setColor(1, 1, 0, xfade)
        end
        love.graphics.print("GIVE UP", 380, 360)
    end

    if self.fade_white then
        love.graphics.setColor(1, 1, 1, self.fader_alpha)
    else
        love.graphics.setColor(0, 0, 0, self.fader_alpha)
    end
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameOver:keypressed(key)
    if Game.console.is_open then return end

end

return GameOver