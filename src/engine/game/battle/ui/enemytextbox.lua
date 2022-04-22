local EnemyTextbox, super = Class(Object)

function EnemyTextbox:init(text, x, y, speaker, right)
    super:init(self, x, y, 0, 0)

    self.layer = BATTLE_LAYERS["above_arena"] - 1

    self.bubble_end = Assets.getTexture("ui/battle/bubble_end")

    self.font = Assets.getFont("plain")
    self.font_data = Assets.getFontData("plain")

    self.text = DialogueText("", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, "plain", "none")
    self.text.color = {0, 0, 0}
    self:addChild(self.text)

    self.text_width = 1
    self.text_height = 1

    if right then
        self.right = true
        self:setOrigin(0, 0.5)
        self.text.x = self.bubble_end:getWidth() + 5
    else
        self.right = false
        self:setOrigin(1, 0.5)
    end

    self.speaker = speaker
    if self.speaker then
        self.speaker.textbox = self
    end

    self.advance_callback = nil

    self.text:registerCommand("noautoskip", function(text, node)
        Game.battle.use_textbox_timer = false
    end)

    self:setText(text)
end

function EnemyTextbox:onRemoveFromStage(stage)
    super:onRemoveFromStage(self, stage)
    if self.speaker and self.speaker.textbox == self then
        self.speaker.textbox = nil
    end
end

function EnemyTextbox:advance()
    self.text:advance()
end

function EnemyTextbox:setText(text, callback)
    self.text:setText(text, callback or self.advance_callback)

    self:updateSize()
end

function EnemyTextbox:setAuto(auto)
    self.text.auto_advance = auto or false
end

function EnemyTextbox:setAdvance(advance)
    self.text.can_advance = advance or false
end

function EnemyTextbox:setSkippable(skippable)
    self.text.skippable = skippable or false
end

function EnemyTextbox:setCallback(callback)
    self.advance_callback = callback
    self.text.advance_callback = callback
end

function EnemyTextbox:isTyping()
    return self.text:isTyping()
end

function EnemyTextbox:isDone()
    return self.text:isDone()
end

function EnemyTextbox:update()
    super:update(self)

    self:updateSize()
end

function EnemyTextbox:updateSize()
    local parsed = self.text.display_text

    local _,lines = parsed:gsub("\n", "")

    local w = self.font:getWidth(parsed)
    local h = self.font_data["lineSpacing"] * (lines + 1) - (self.font_data["lineSpacing"] - self.font:getHeight())

    self.text_width = w
    self.text_height = h

    self.width = w + self.bubble_end:getWidth()
    self.height = h
end

function EnemyTextbox:draw()
    love.graphics.rectangle("fill", self.text.x - 10, self.text.y - 5, self.text_width + 20, self.text_height + 10)
    love.graphics.rectangle("fill", self.text.x - 5, self.text.y - 10, self.text_width + 10, self.text_height + 20)
    local scale = 1
    if self.text.height < 35 then
        scale = 0.5
    end
    if self.right then
        love.graphics.draw(self.bubble_end, self.text.x - 5 - 1, self.text_height/2 - (self.bubble_end:getHeight()/2) * scale, 0, -1, scale)
    else
        love.graphics.draw(self.bubble_end, self.text_width + 5 + 1, self.text_height/2 - (self.bubble_end:getHeight()/2) * scale, 0, 1, scale)
    end

    super:draw(self)
end

return EnemyTextbox