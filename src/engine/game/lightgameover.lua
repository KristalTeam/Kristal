--- An object that is created whenever the player reaches a Game Over while in a Light World Map, responsible for managing the GameOver sequence. \
--- This Game Over only plays if the player died in the Light World
---@class LightGameOver : Object
---@field current_stage OldGameOverState The state that the GameOver is on
---@overload fun(...) : LightGameOver
local LightGameOver, super = Class(Object, "lightgameover")

---@enum LightGameOverState
local LightGameOverState = {
    START = 0,
    SOUL_SPLIT = 1,
    SOUL_SHARDS = 2,
    FADE_OUT = 3,
    SCREEN = 4,
    PARTY_TEXT = 5,
    TEXT_CONFIRM = 6,
    FADE_IN = 7,
    END = -1
}

function LightGameOver:init(x, y)
    super.init(self, 0, 0)

    self.music = Music()

    self.soul = Sprite("player/heart")
    self.soul:setOrigin(0.5, 0.5)
    self.soul:setColor(Game:getSoulColor())
    self.soul.x = x
    self.soul.y = y

    self:addChild(self.soul)

    self.current_stage = LightGameOverState.START
    self.fader_alpha = 0

    self.timer = 28
    self.skipping = 0
end

function LightGameOver:onRemove(parent)
    super.onRemove(self, parent)
    self.music:remove()
end


function LightGameOver:update()
    super.update(self)

    self.timer = self.timer + DTMULT
    if (self.timer >= 30) and (self.current_stage == LightGameOverState.START) then
        self.current_stage = LightGameOverState.SOUL_SPLIT
    end
    if (self.timer >= 50) and (self.current_stage == LightGameOverState.SOUL_SPLIT) then
        Assets.playSound("break1")
        self.soul:setSprite("player/heart_break")
        self.current_stage = LightGameOverState.SOUL_SHARDS
    end
    if (self.timer >= 90) and (self.current_stage == LightGameOverState.SOUL_SHARDS) then
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
        self.current_stage = LightGameOverState.FADE_OUT
    end
    if (self.timer >= 140) and (self.current_stage == LightGameOverState.FADE_OUT) then
        self.fader_alpha = 0
        self.current_stage = LightGameOverState.SCREEN
    end
    if (self.timer >= 150) and (self.current_stage == LightGameOverState.SCREEN) then
        self.music:play("determination")
        self.text = Sprite("ui/gameover_ut", 111, 32)
        self.alpha = 0
        self:addChild(self.text)
        self.text:setColor(1, 1, 1, self.alpha)
        self.current_stage = LightGameOverState.PARTY_TEXT
    end
    if ((self.timer >= 230)) and (self.current_stage == LightGameOverState.PARTY_TEXT) then
        local options = {}
        local main_chara = Game:getSoulPartyMember()
        for _, member in ipairs(Game.party) do
            if member ~= main_chara and member:getGameOverMessage(main_chara) then
                table.insert(options, member)
            end
        end
        if #options == 0 then
            if Input.pressed("confirm") or Input.pressed("menu") then
                self.music:fade(0, 2)
                self.current_stage = LightGameOverState.FADE_IN
                self.timer = 0
            end
        else
            local member = TableUtils.pick(options)
            local voice = member:getActor():getVoice() or "default"
            self.lines = {}
            for _,dialogue in ipairs(member:getGameOverMessage(main_chara)) do
                local spacing = 6
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
                self.lines[1], 114, 320,
                {
                    style = "none",
                    actor = member:getActor(Game:isLight())
                })
            self.dialogue.skippable = false
            self.dialogue.line_offset = 8
            table.insert(self.lines, "")
            self:addChild(self.dialogue)
            table.remove(self.lines, 1)
            self.current_stage = LightGameOverState.TEXT_CONFIRM
        end
    end
    if (self.current_stage == LightGameOverState.TEXT_CONFIRM) and Input.pressed("confirm") and (not self.dialogue:isTyping()) then
        if #self.lines > 0 then
            self.dialogue:setText(self.lines[1])
            self.dialogue.line_offset = 14
            table.remove(self.lines, 1)
        else
            self.dialogue:remove()
            self.music:fade(0, 2)
            self.current_stage = LightGameOverState.FADE_IN
            self.timer = 0
        end
    end

    if (self.current_stage == LightGameOverState.FADE_IN) then
        self.fader_alpha = self.fader_alpha + .02 * DTMULT
        if self.timer >= 80 then
            self.current_stage = LightGameOverState.END
            Game:loadQuick()
            Game.fader:fadeIn(nil, {alpha = 1, speed = 12/30, color = {0, 0, 0}})
        end
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

function LightGameOver:draw()
    super.draw(self)

    Draw.setColor(0, 0, 0, self.fader_alpha)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    Draw.setColor(1, 1, 1, 1)
end

return LightGameOver
