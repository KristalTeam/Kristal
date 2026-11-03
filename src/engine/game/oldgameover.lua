--- An object that is created whenever the player reaches a Game Over and the project is configured to use the old game over, responsible for managing the GameOver sequence. \
---@class OldGameOver : Object
---@field current_stage OldGameOverState The state that the GameOver is on
---@overload fun(...) : OldGameOver
local OldGameOver, super = Class(Object, "oldgameover")

---@enum OldGameOverState
local OldGameOverState = {
    START = 0,
    SOUL_SPLIT = 1,
    SOUL_SHARDS = 2,
    FADE_OUT = 3,
    SCREEN = 4,
    TEXT1 = 5,
    TEXT2 = 6,
    TEXT_CONFIRM = 7,
    CHOICER = 8,
    CHOICER_NO = 9,
    CHOICER_YES = 10,
    FADE_IN = 11,
    RETURN_TO_MENU = 12,
    END = -1
}
function OldGameOver:init(x, y)
    super.init(self, 0, 0)

    self.screenshot = love.graphics.newImage(SCREEN_CANVAS:newImageData())

    self.music = Music()

    self.soul = Sprite("player/heart")
    self.soul:setOrigin(0.5, 0.5)
    self.soul:setColor(Game:getSoulColor())
    self.soul.x = x
    self.soul.y = y

    self:addChild(self.soul)

    self.current_stage = OldGameOverState.START
    self.fader_alpha = 0
    self.skipping = 0
    self.fade_white = false

    self.timer = 0
end

function OldGameOver:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end


function OldGameOver:update()
    super.update(self)

    self.timer = self.timer + DTMULT
    if (self.timer >= 30) and (self.current_stage == OldGameOverState.START) then
        self.screenshot = nil
        self.current_stage = OldGameOverState.SOUL_SPLIT
    end
    if (self.timer >= 50) and (self.current_stage == OldGameOverState.SOUL_SPLIT) then
        Assets.playSound("break1")
        self.soul:setSprite("player/heart_break")
        self.current_stage = OldGameOverState.SOUL_SHARDS
    end
    if (self.timer >= 90) and (self.current_stage == OldGameOverState.SOUL_SHARDS) then
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
        self.current_stage = OldGameOverState.FADE_OUT
    end
    if (self.timer >= 140) and (self.current_stage == OldGameOverState.FADE_OUT) then

        self.fader_alpha = (self.timer - 140) / 10
        if self.fader_alpha >= 1 then
            for i = #self.shards, 1, -1 do
                self.shards[i]:remove()
            end
            self.shards = {}
            self.fader_alpha = 0
            self.current_stage = OldGameOverState.SCREEN
        end
    end
    if (self.timer >= 150) and (self.current_stage == OldGameOverState.SCREEN) then
        self.music:play("AUDIO_DRONE")
        self.current_stage = OldGameOverState.TEXT1
    end
    if ((self.timer >= 180)) and (self.current_stage == OldGameOverState.TEXT1) then
        if Game.died_once then
            self.current_stage = OldGameOverState.TEXT2
        else
            self.dialogue = DialogueText("[speed:0.5][spacing:8][voice:none]IT APPEARS YOU\nHAVE REACHED[wait:30]\n\n   AN END.", 164, 160, {style = "GONER", line_offset = 12})
            self.dialogue.skip_speed = true
            self:addChild(self.dialogue)
            self.current_stage = OldGameOverState.TEXT2
        end
    end
    
    if (self.current_stage == OldGameOverState.TEXT2) then
        if Game.died_once then
            self.dialogue = DialogueText("[speed:0.5][spacing:8][voice:none]WILL YOU PERSIST?", 104, 160, {style = "GONER", line_offset = 12})
            self:addChild(self.dialogue)
            self.current_stage = OldGameOverState.TEXT_CONFIRM
        elseif Input.pressed("confirm") and self.dialogue and (not self.dialogue:isTyping()) then
            self.dialogue:setText("[speed:0.5][spacing:8][voice:none]WILL YOU TRY AGAIN?")
            self.dialogue.x = 104
            self.current_stage = OldGameOverState.TEXT_CONFIRM
        end
    end

    if (self.current_stage == OldGameOverState.TEXT_CONFIRM) then
        self.choicer = GonerChoice(220, 360, {
            {{"YES",0,0},{"<<"},{">>"},{"NO",160,0}}
        })
        self.choicer:setSelectedOption(2, 1)
        self.choicer:setSoulPosition(80, 0)
        self:addChild(self.choicer)
        self.current_stage = OldGameOverState.CHOICER
    end

    if (self.current_stage == OldGameOverState.CHOICER) then
        if self.choicer.choice then
            self.music:stop()

            if self.choicer.choice_x == 1 then
                self.current_stage = OldGameOverState.CHOICER_YES
                self.timer = 0
            else
                self.current_stage = OldGameOverState.CHOICER_NO
                local world_ended_text = "[noskip][speed:0.5][spacing:8][voice:none] THEN THE WORLD[wait:30] \n WAS COVERED[wait:30] \n IN DARKNESS."
                self.dialogue:setText(world_ended_text)
                self.dialogue.x = 120
            end
        end
    end

    if (self.current_stage == OldGameOverState.CHOICER_YES) then
        self.dialogue.x = 99
        if Game.died_once then
            self.dialogue:setText("")
        else
            self.dialogue:setText("[noskip][speed:0.5][spacing:8][voice:none] THEN, THE FUTURE\n IS IN YOUR HANDS.")
        end
        if (self.timer >= 30) then
            self.timer = 0
            self.current_stage = OldGameOverState.FADE_IN
            self.fade_white = true
        end
    end

    if (self.current_stage == OldGameOverState.FADE_IN) then
        self.fade_white = true
        self.fader_alpha = self.fader_alpha + ((Game.died_once and 0.03 or 0.01) * DTMULT)
        if self.timer >= (Game.died_once and 40 or 120) then
            Game.died_once = true
            self.current_stage = OldGameOverState.END
            Game:loadQuick()
        end
    end

    if (self.current_stage == OldGameOverState.CHOICER_NO) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        self.dialogue:remove()
        self.music:play("AUDIO_DARKNESS")
        self.music.source:setLooping(false)
        self.current_stage = OldGameOverState.RETURN_TO_MENU
    end

    if (self.current_stage == OldGameOverState.RETURN_TO_MENU) and (not self.music:isPlaying()) then
        if Kristal.getModOption("hardReset") then
            love.event.quit("restart")
        else
            Kristal.returnToMenu()
        end
        self.current_stage = OldGameOverState.END
    end

    if ((self.timer >= 80) and (self.timer < 150)) then
        if Input.pressed("confirm") then
            self.skipping = self.skipping + 1
        end
        if (self.skipping >= 4) then
            Game:loadQuick()
        end
    end
end

function OldGameOver:draw()
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

return OldGameOver
