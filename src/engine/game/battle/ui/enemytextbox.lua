local EnemyTextbox, super = Class(Object)

function EnemyTextbox:init(text, x, y, enemy)
    super:init(self, x, y, 0, 0)

    self:setOrigin(1, 0.5)

    self.layer = LAYERS["above_arena"] - 1

    self.bubble_end = Assets.getTexture("ui/battle/bubble_end")

    self.font = Assets.getFont("plain")
    self.font_data = Assets.getFontData("plain")

    self.text = DialogueText("", 0, 0, 1, 1, "plain", "none")
    self.text.color = {0, 0, 0}
    self:addChild(self.text)

    self.enemy = enemy
    if self.enemy then
        self.enemy.textbox = self
    end

    self.text_list = {}
    if type(text) == "table" then
        self.text_list = text
    else
        self.text_list = {text}
    end
    self.current_text = 0

    self.done = false

    self:next()
end

function EnemyTextbox:next()
    self.current_text = self.current_text + 1
    if self.current_text > #self.text_list then
        if self.enemy then
            self.enemy.textbox = nil
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
    local _,lines = text:gsub("\n", "")

    local w = self.font:getWidth(text)
    local h = self.font_data["lineSpacing"] * (lines + 1) - (self.font_data["lineSpacing"] - self.font:getHeight())

    self.text.width = w
    self.text.height = h

    self.width = w + self.bubble_end:getWidth()
    self.height = h

    self.text:setText(text)
end

function EnemyTextbox:isTyping()
    return self.text.state.typing
end

function EnemyTextbox:update(dt)
    if Game.battle:hasCutscene() then
        if Input.pressed("confirm") or self.auto_advance or Input.down("menu") then
            if not self:isTyping() and self:next() then
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
    love.graphics.draw(self.bubble_end, self.text.width + 5 + 1, self.text.height/2 - (self.bubble_end:getHeight()/2) * scale, 0, 1, scale)

    super:draw(self)
end

return EnemyTextbox