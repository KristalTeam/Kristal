---@class TextChoicebox : Textbox
---@overload fun(...) : TextChoicebox
local TextChoicebox, super = Class(Textbox)

function TextChoicebox:init(x, y, width, height, default_font, default_font_size, battle_box)
    super.init(self, x, y, width, height, default_font, default_font_size, battle_box)

    self.choices = {}

    self.current_choice = 1
    self.selected_choice = nil

    self.done = false

    self.heart = Assets.getTexture("player/heart_menu")
    
    self.typing_choice_text = 0
    self.choices_text = {DialogueText("", 148, 68), DialogueText("", 340, 68)}
    for _,text in ipairs(self.choices_text) do
        self:addChild(text)
    end

    self:setAdvance(false)
end

function TextChoicebox:update()
    super.update(self)
    if not self.text:isTyping() then
        for i,text in ipairs(self.choices_text) do
            if self.choices[i] and self.typing_choice_text < i and (i == 1 or not self.choices_text[i-1]:isTyping()) then
                self.typing_choice_text = i
                
                local wait = "[wait:10]"
                if self.face.texture then
                    text.x = text.x + 2
                    if i == 1 then
                        wait = ""
                    else
                        wait = "[wait:5]"
                    end
                end
                
                local voice = ""
                if self.actor and self.actor:getVoice() then
                    voice = "[voice:"..self.actor:getVoice().."]"
                end

                text:setText(voice..wait..self.choices[i])
            end
        end
    end
    if not self:isTyping() then
        local old_choice = self.current_choice
        
        if Input.pressed("left")  then self.current_choice = self.current_choice - 1 end
        if Input.pressed("right") then self.current_choice = self.current_choice + 1 end

        if self.current_choice < 1 then
            self.current_choice = #self.choices
        end

        if self.current_choice > #self.choices then
            self.current_choice = 1
        end
        
        if (self.ui_sound == nil and not self.actor or self.ui_sound) and self.current_choice ~= old_choice then
            Assets.stopAndPlaySound("ui_move")
        end

        if Input.pressed("confirm") then
            if self.current_choice ~= 0 then
                self.selected_choice = self.current_choice

                self.done = true

                if not self.battle_box then
                    self:remove()
                    if Game.world:hasCutscene() then
                        Game.world.cutscene.choice = self.selected_choice
                        Game.world.cutscene:tryResume()
                    end
                else
                    self:clearChoices()
                    self.active = false
                    self.visible = false
                    Game.battle.battle_ui.encounter_text.active = true
                    Game.battle.battle_ui.encounter_text.visible = true
                    if Game.battle:hasCutscene() then
                        Game.battle.cutscene.choice = self.selected_choice
                        Game.battle.cutscene:tryResume()
                    end
                end
            end
        end
    end
end

function TextChoicebox:clearChoices()
    self.choices = {}
    self.current_choice = 1
end

function TextChoicebox:addChoice(name)
    table.insert(self.choices, name)
end

function TextChoicebox:setText(text, callback)
    if type(text) == "table" then
        error("Text choicers cannot have multiple lines of text!")
    end

    super.setText(self, text, callback)
end

function TextChoicebox:isTyping()
    local typing = self.text:isTyping()
    for _,text in ipairs(self.choices_text) do
        if text:isTyping() then
            typing = true
            break
        end
    end
    return typing
end

function TextChoicebox:isDone()
    return self.done
end

function TextChoicebox:draw()
    super.draw(self)
    if not self:isTyping() then
        local x = 122 + (self.current_choice - 1) * 192
        local y = 76
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart, x, y, 0, 2, 2)
        Draw.setColor(1, 1, 1)
    end
end

return TextChoicebox