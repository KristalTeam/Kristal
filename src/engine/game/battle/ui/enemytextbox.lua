local EnemyTextbox, super = Class(Object)

function EnemyTextbox:init(text, x, y, speaker, right)
    super:init(self, x, y, 0, 0)

    self.layer = LAYERS["above_arena"] - 1

    self.bubble_end = Assets.getTexture("ui/battle/bubble_end")

    self.font = Assets.getFont("plain")
    self.font_data = Assets.getFontData("plain")

    self.text = DialogueText("", 0, 0, 1, 1, "plain", "none")
    self.text.color = {0, 0, 0}
    self:addChild(self.text)

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

    self.text_list = {}
    if type(text) == "table" then
        self.text_list = text
    else
        self.text_list = {text}
    end
    self.current_text = 0

    self.can_advance = false
    self.auto_advance = false

    self.done = false

    self.text:registerCommand("noautoskip", function(text, node)
        Game.battle.use_textbox_timer = false
        text.state.typed_characters = text.state.typed_characters + 1
    end)

    self:next()
end

function EnemyTextbox:next()
    self.current_text = self.current_text + 1
    if self.current_text > #self.text_list then
        if self.speaker then
            self.speaker.textbox = nil
        end
        self.done = true
        self:remove()
        return true
    end
    self.done = false
    self:setText(self.text_list[self.current_text])
    return false
end

function EnemyTextbox:setText(text)
    self.text.width = SCREEN_WIDTH
    self.text.height = SCREEN_HEIGHT

    self.text:setText(text)

    local parsed = self.text.display_text

    local _,lines = parsed:gsub("\n", "")

    local w = self.font:getWidth(parsed)
    local h = self.font_data["lineSpacing"] * (lines + 1) - (self.font_data["lineSpacing"] - self.font:getHeight())

    self.text.width = w
    self.text.height = h

    self.width = w + self.bubble_end:getWidth()
    self.height = h
end

function EnemyTextbox:isTyping()
    return self.text.state.typing
end

function EnemyTextbox:update(dt)
    if self.can_advance then
        if Input.pressed("confirm") or self.auto_advance or Input.down("menu") then
            if not self:isTyping() and self:next() and Game.battle.cutscene then
                local enemy_text = Game.battle.cutscene.waiting_for_enemy_text
                if enemy_text and Utils.containsValue(enemy_text, self) then
                    Utils.removeFromTable(enemy_text, self)
                    if #enemy_text == 0 then
                        Game.battle.cutscene.waiting_for_enemy_text = nil
                        Game.battle.cutscene:resume()
                    end
                end
            end
        end
    end
    super:update(self, dt)
end

function EnemyTextbox:draw()
    love.graphics.rectangle("fill", self.text.x - 10, self.text.y - 5, self.text.width + 20, self.text.height + 10)
    love.graphics.rectangle("fill", self.text.x - 5, self.text.y - 10, self.text.width + 10, self.text.height + 20)
    local scale = 1
    if self.text.height < 35 then
        scale = 0.5
    end
    if self.right then
        love.graphics.draw(self.bubble_end, self.text.x - 5 - 1, self.text.height/2 - (self.bubble_end:getHeight()/2) * scale, 0, -1, scale)
    else
        love.graphics.draw(self.bubble_end, self.text.width + 5 + 1, self.text.height/2 - (self.bubble_end:getHeight()/2) * scale, 0, 1, scale)
    end

    super:draw(self)
end

return EnemyTextbox