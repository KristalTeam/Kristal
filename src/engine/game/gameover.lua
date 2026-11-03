--- An object that is created whenever the player reaches a Game Over, responsible for managing the GameOver sequence. \
--- This is the normal GameOver that happens on the Dark World from Chapter 2 onwards
---@class GameOver : Object
---@field current_stage GameOverState
---@overload fun(...) : GameOver
local GameOver, super = Class(Object, "gameover")

---@enum GameOverState
local GameOverState = {
    START = 0,
    SOUL_SPLIT = 1,
    SOUL_SHARDS = 2,
    FADE_OUT = 3,
    SCREEN = 4,
    TEXT1 = 5,
    TEXT2 = 6,
    CHOICER = 7,
    CHOICER_SELECT = 8,
    CHOICER_NO = 9,
    CHOICER_YES = 10,
    FADE_IN = 11,
    RETURN_TO_MENU = 12,
    END = -1
}
function GameOver:init(x, y)
    super.init(self, 0, 0)

    self.screenshot = love.graphics.newImage(SCREEN_CANVAS:newImageData())

    self.music = Music()

    self.soul = Sprite("player/heart")
    self.soul:setOrigin(0.5, 0.5)
    self.soul:setColor(Game:getSoulColor())
    self.soul.x = x
    self.soul.y = y

    self:addChild(self.soul)

    self.current_stage = GameOverState.START
    self.fader_alpha = 0
    self.skipping = 0
    self.fade_white = false

    self.timer = 0
end

function GameOver:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end


function GameOver:update()
    super.update(self)

    self.timer = self.timer + DTMULT
    if (self.timer >= 30) and (self.current_stage == GameOverState.START) then
        self.screenshot = nil
        self.current_stage = GameOverState.SOUL_SPLIT
    end
    if (self.timer >= 50) and (self.current_stage == GameOverState.SOUL_SPLIT) then
        Assets.playSound("break1")
        self.soul:setSprite("player/heart_break")
        self.current_stage = GameOverState.SOUL_SHARDS
    end
    if (self.timer >= 90) and (self.current_stage == GameOverState.SOUL_SHARDS) then
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
            shard.physics.direction = math.rad(MathUtils.random(360))
            shard.physics.speed = 7
            shard.physics.gravity = 0.2
            shard:play(5/30)
            table.insert(self.shards, shard)
            self:addChild(shard)
        end

        self.soul:remove()
        self.soul = nil
        self.current_stage = GameOverState.FADE_OUT
    end
    if (self.timer >= 140) and (self.current_stage == GameOverState.FADE_OUT) then
        self.fader_alpha = (self.timer - 140) / 10
        if self.fader_alpha >= 1 then
            for i = #self.shards, 1, -1 do
                self.shards[i]:remove()
            end
            self.shards = {}
            self.fader_alpha = 0
            self.current_stage = GameOverState.SCREEN
        end
    end
    if (self.timer >= 150) and (self.current_stage == GameOverState.SCREEN) then
        self.music:play("AUDIO_DEFEAT")
            self.text = Sprite("ui/gameover", 0, 40)
            self.text:setScale(2)
            self.alpha = 0
            self:addChild(self.text)
            self.text:setColor(1, 1, 1, self.alpha)
        self.current_stage = GameOverState.TEXT1
    end
    if ((self.timer >= 180)) and (self.current_stage == GameOverState.TEXT1) then
        local options = {}
        local main_chara = Game:getSoulPartyMember()
        for _, member in ipairs(Game.party) do
            if member ~= main_chara and member:getGameOverMessage(main_chara) then
                table.insert(options, member)
            end
        end
        if #options == 0 then
            self.current_stage = GameOverState.CHOICER
        else
            local member = TableUtils.pick(options)
            local voice = member:getActor():getVoice() or "default"
            self.lines = {}
            for _,dialogue in ipairs(member:getGameOverMessage(main_chara)) do
                local spacing = 8
                local full_line = "[speed:0.5][spacing:"..spacing.."][voice:"..voice.."]"
                local lines = StringUtils.split(dialogue, "\n")
                for i,line in ipairs(lines) do
                    if i > 1 then
                        full_line = full_line.."\n  "..line
                    else
                        full_line = full_line.."  "..line
                    end
                end
                table.insert(self.lines, full_line)
            end
            self.dialogue = DialogueText(
                self.lines[1], 100, 300,
                {
                    style = "none",
                    actor = member:getActor(Game:isLight())
                })

            self.dialogue.skip_speed = true
            self.dialogue.line_offset = 14
            self:addChild(self.dialogue)
            table.remove(self.lines, 1)
            self.current_stage = GameOverState.TEXT2
        end
    end
    if (self.current_stage == GameOverState.TEXT2) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        if #self.lines > 0 then
            self.dialogue:setText(self.lines[1])
            self.dialogue.line_offset = 14
            table.remove(self.lines, 1)
        else
            self.dialogue:remove()
            self.current_stage = GameOverState.CHOICER
        end
    end

    if (self.current_stage == GameOverState.CHOICER) then
        self.choicer = GonerChoice(160, 360, {
            {{"CONTINUE",0,0},{"<<"},{">>"},{"GIVE UP",220,0}}
        })
        self.choicer:setSelectedOption(2, 1)
        self.choicer:setSoulPosition(140, 0)
        self:addChild(self.choicer)
        self.current_stage = GameOverState.CHOICER_SELECT
    end

    if (self.current_stage == GameOverState.CHOICER_SELECT) then
        if self.choicer.choice then
            self.music:stop()

            if self.choicer.choice_x == 1 then
                self.current_stage = GameOverState.CHOICER_YES
                self.timer = 0
            else
                self.current_stage = GameOverState.CHOICER_NO
                local world_ended_text = "[noskip][speed:0.5][spacing:8][voice:none] THEN THE WORLD[wait:30] \n WAS COVERED[wait:30] \n IN DARKNESS."
                self.text:remove()
                self.dialogue = DialogueText(world_ended_text, 120, 160, {style = "GONER", line_offset = 12})
                self:addChild(self.dialogue)
            end
        end
    end

    if (self.current_stage == GameOverState.CHOICER_YES) then
        if (self.timer >= 30) then
            self.timer = 0
            self.current_stage = GameOverState.FADE_IN
            local sound = Assets.newSound("dtrans_lw")
            sound:play()
            self.fade_white = true
        end
    end

    if (self.current_stage == GameOverState.FADE_IN) then
        self.fade_white = true
        self.fader_alpha = self.fader_alpha + (0.01 * DTMULT)
        if self.timer >= 120 then
            self.current_stage = GameOverState.END
            Game:loadQuick()
        end
    end

    if (self.current_stage == GameOverState.CHOICER_NO) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        self.dialogue:remove()
        self.music:play("AUDIO_DARKNESS")
        self.music.source:setLooping(false)
        self.current_stage = GameOverState.RETURN_TO_MENU
    end

    if (self.current_stage == GameOverState.RETURN_TO_MENU) and (not self.music:isPlaying()) then
        if Kristal.getModOption("hardReset") then
            love.event.quit("restart")
        else
            Kristal.returnToMenu()
        end
        self.current_stage = GameOverState.END
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

return GameOver
