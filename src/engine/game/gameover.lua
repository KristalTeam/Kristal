---@class GameOver : Object
---@overload fun(...) : GameOver
local GameOver, super = Class(Object, "gameover")

function GameOver:init(x, y)
    super.init(self, 0, 0)

    self.font = Assets.getFont("main")
    self.soul_blur = Assets.getTexture("player/heart_blur")

    if not Game:isLight() then
        self.screenshot = love.graphics.newImage(SCREEN_CANVAS:newImageData())
    end

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

    if Game:isLight() then
        self.timer = 28 -- We only wanna show one frame if we're in Undertale mode
    end
end

function GameOver:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end


function GameOver:update()
    super.update(self)

    self.timer = self.timer + DTMULT
    if (self.timer >= 30) and (self.current_stage == 0) then
        self.screenshot = nil
        self.current_stage = 1
    end
    if (self.timer >= 50) and (self.current_stage == 1) then
        Assets.playSound("break1")
        self.soul:setSprite("player/heart_break")
        self.current_stage = 2
    end
    if (self.timer >= 90) and (self.current_stage == 2) then
        Assets.playSound("break2")

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
        if Game:isLight() then
            self.fader_alpha = 0
            self.current_stage = 4
        else
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
    end
    if (self.timer >= 150) and (self.current_stage == 4) then
        self.music:play(Game:isLight() and "determination" or Game:getConfig("oldGameOver") and "AUDIO_DRONE" or "AUDIO_DEFEAT")
        if not Game:getConfig("oldGameOver") or Game:isLight() then
            if Game:isLight() then
                self.text = Sprite("ui/gameover_ut", 111, 32)
            else
                self.text = Sprite("ui/gameover", 0, 40)
                self.text:setScale(2)
            end
            self.alpha = 0
            self:addChild(self.text)
            self.text:setColor(1, 1, 1, self.alpha)
        end
        self.current_stage = 5
    end
    if ((self.timer >= (Game:isLight() and 230 or 180))) and (self.current_stage == 5) then
        local options = {}
        local main_chara = Game:getSoulPartyMember()
        for _, member in ipairs(Game.party) do
            if member ~= main_chara and member:getGameOverMessage(main_chara) then
                table.insert(options, member)
            end
        end
        if Game:getConfig("oldGameOver") and not Game:isLight() then
            if Game.died_once then 
                self.current_stage = 6
            else
                self.dialogue = DialogueText("[speed:0.5][spacing:8][voice:none]IT APPEARS YOU\nHAVE REACHED[wait:30]\n\n   AN END.", 160, 160, {style = "GONER", line_offset = 14})
                self.dialogue.skip_speed = true
                self:addChild(self.dialogue)
                self.current_stage = 6
            end
        elseif #options == 0 then
            if Game:isLight() then
                if Input.pressed("confirm") or Input.pressed("menu") then
                    self.music:fade(0, 2)
                    self.current_stage = 10
                    self.timer = 0
                end
            else
                self.current_stage = 7
            end
        else
            local member = Utils.pick(options)
            local voice = member:getActor().voice or "default"
            self.lines = {}
            for _,dialogue in ipairs(member:getGameOverMessage(main_chara)) do
                local spacing = Game:isLight() and 6 or 8
                local full_line = "[speed:0.5][spacing:"..spacing.."][voice:"..voice.."]"
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
            self.dialogue = DialogueText(self.lines[1], Game:isLight() and 114 or 100, Game:isLight() and 320 or 300, {style = "none"})
            if Game:isLight() then
                self.dialogue.skippable = false
                self.dialogue.line_offset = 8
                table.insert(self.lines, "")
            else
                self.dialogue.skip_speed = true
                self.dialogue.line_offset = 14
            end
            self:addChild(self.dialogue)
            table.remove(self.lines, 1)
            self.current_stage = 6
        end
    end
    if (self.current_stage == 6) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        if not Game:getConfig("oldGameOver") or Game:isLight() then
            if #self.lines > 0 then
                self.dialogue:setText(self.lines[1])
                self.dialogue.line_offset = 14
                table.remove(self.lines, 1)
            else
                self.dialogue:remove()
                self.current_stage = 7
                if Game:isLight() then
                    self.music:fade(0, 2)
                    self.current_stage = 10
                    self.timer = 0
                end
            end
        else
            self.dialogue:setText("[speed:0.5][spacing:8][voice:none]WILL YOU TRY AGAIN?")
            self.dialogue.x = 100
            self.current_stage = 7
        end
    end
    if Game:getConfig("oldGameOver") and self.current_stage == 6 and Game.died_once then
        self.dialogue = DialogueText("[speed:0.5][spacing:8][voice:none]WILL YOU PERSIST?", 120, 160, {style = "GONER", line_offset = 14})
        self:addChild(self.dialogue)
        self.current_stage = 7
    end

    if (self.current_stage == 7) then
        if not Game:getConfig("oldGameOver") then
            self.choicer = GonerChoice(160, 360, {
                {{"CONTINUE",0,0},{"<<"},{">>"},{"GIVE UP",220,0}}
            })
            self.choicer:setSelectedOption(2, 1)
            self.choicer:setSoulPosition(140, 0)
        else
            self.choicer = GonerChoice(220, 360, {
                {{"YES",0,0},{"<<"},{">>"},{"NO",160,0}}
            })
            self.choicer:setSelectedOption(2, 1)
            self.choicer:setSoulPosition(80, 0)
        end
        self:addChild(self.choicer)
        self.current_stage = 8
    end

    if (self.current_stage == 8) then
        if self.choicer.choice then
            self.music:stop()

            if self.choicer.choice_x == 1 then
                self.current_stage = 9
                self.timer = 0
            else
                self.current_stage = 20
                if not Game:getConfig("oldGameOver") then
                    self.text:remove()

                    self.dialogue = DialogueText("[noskip][speed:0.5][spacing:8][voice:none] THEN THE WORLD[wait:30] \n WAS COVERED[wait:30] \n IN DARKNESS.", 120, 160, {style = "GONER", line_offset = 14})
                    self:addChild(self.dialogue)
                else
                    self.dialogue:setText("[noskip][speed:0.5][spacing:8][voice:none] THEN THE WORLD[wait:30] \n WAS COVERED[wait:30] \n IN DARKNESS.")
                    self.dialogue.x = 120
                end
            end
        end
    end

    if (self.current_stage == 9) then
        if Game:getConfig("oldGameOver") then
            if Game.died_once then
                self.dialogue:setText("")
            else
                self.dialogue:setText("[noskip][speed:0.5][spacing:8][voice:none] THEN, THE FUTURE\n IS IN YOUR HANDS.")
            end
        end
        if (self.timer >= 30) then
            self.timer = 0
            self.current_stage = 10
            if not Game:getConfig("oldGameOver") then
                local sound = Assets.newSound("dtrans_lw")
                sound:play()
            end
            self.fade_white = true
        end
    end

    if (self.current_stage == 10) then
        self.fade_white = not Game:isLight()
        self.fader_alpha = self.fader_alpha + ((Game:isLight() and 0.02 or Game:getConfig("oldGameOver") and Game.died_once and 0.03 or 0.01) * DTMULT)
        if self.timer >= (Game:isLight() and 80 or Game:getConfig("oldGameOver") and Game.died_once and 40 or 120) then
            if Game:getConfig("oldGameOver") and not Game:isLight() then Game.died_once = true end
            self.current_stage = 11
            Game:loadQuick()
            if Game:isLight() then
                Game.fader:fadeIn(nil, {alpha = 1, speed = 0.5})
            end
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
    super.draw(self)

    if self.screenshot then
        Draw.setColor(1, 1, 1, 1)
        Draw.draw(self.screenshot)
    end

    if self.fade_white then
        Draw.setColor(1, 1, 1, self.fader_alpha)
    else
        Draw.setColor(0, 0, 0, self.fader_alpha)
    end
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    Draw.setColor(1, 1, 1, 1)
end

function GameOver:onKeyPressed(key)
    -- ?
end

return GameOver