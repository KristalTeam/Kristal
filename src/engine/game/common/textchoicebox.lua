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
    
    self.choices_text = {}
    self.added_text_boxes = false
    self.typing_choice_text = 0
    self.multi_line_mode = false

    self:setAdvance(false)
end

function TextChoicebox:update()
    super.update(self)
    if #self.choices > 0 and not self.added_text_boxes then
        self.added_text_boxes = true
        for _,choice in ipairs(self.choices) do
            if string.find(choice, "\n") ~= nil then
                self.multi_line_mode = true
                break
            end
        end
        
        for i = (self.multi_line_mode and 2 or 0), 0, -1 do
            table.insert(self.choices_text, DialogueText("", 148, 68 - 36 * i))
            table.insert(self.choices_text, DialogueText("", 340, 68 - 36 * i))
        end
        for _,text in ipairs(self.choices_text) do
            self:addChild(text)
        end
    end
    if self.added_text_boxes then
        if not self.text:isTyping() then
            for i,text in ipairs(self.choices_text) do
                if self.typing_choice_text == i-1 and (i == 1 or not self.choices_text[i-1]:isTyping()) then
                    self.typing_choice_text = i
                    
                    local wait = "[wait:10]"
                    if self.face.texture then
                        text.x = text.x + 2
                        if i == 1 then
                            wait = ""
                        else
                            wait = "[wait:5]"
                        end
                    elseif self.multi_line_mode then
                        if i % 2 == 1 then
                            wait = "[wait:10]"
                        else
                            wait = "[wait:5]"
                        end
                    end
                    
                    local voice = ""
                    if self.actor and self.actor:getVoice() then
                        voice = "[voice:"..self.actor:getVoice().."]"
                    end
                    if self.multi_line_mode then
                        -- Function to pad a table with empty strings to a specified length
                        local function pad_with_empty(lines, length)
                            while #lines < length do
                                table.insert(lines, 1, "")  -- Insert an empty string at the beginning
                            end
                        end

                        -- Function to interleave lines from two strings and return the combined list
                        local function interleave_lines(str1, str2)
                            -- Split the strings by newline character
                            local lines1 = Utils.split(str1, "\n")
                            local lines2 = Utils.split(str2, "\n")

                            -- Ensure both strings have at least 2 lines by padding with empty strings
                            pad_with_empty(lines1, 2)
                            pad_with_empty(lines2, 2)

                            -- The maximum number of lines
                            local max_lines = math.ceil(#self.choices_text / 2)

                            -- Pad the shorter table with empty strings at the beginning
                            pad_with_empty(lines1, max_lines)
                            pad_with_empty(lines2, max_lines)

                            -- Interleave lines
                            local interleaved = {}
                            for i = 1, max_lines do
                                table.insert(interleaved, lines1[i])
                                table.insert(interleaved, lines2[i])
                            end

                            return interleaved
                        end

                        -- Function to return a specific interleaved line from the combined list
                        local function get_interleaved_line(str1, str2, line_number)
                            local interleaved = interleave_lines(str1 or "", str2 or "")
                            return interleaved[line_number] or ""
                        end
                        if get_interleaved_line(self.choices[1], self.choices[2], i) ~= "" then
                            text:setText(voice..wait..get_interleaved_line(self.choices[1], self.choices[2], i))
                        end
                    else
                        if self.choices[i] and self.choices[i] ~= "" then
                            text:setText(voice..wait..self.choices[i])
                        end
                    end
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
            
            if (self.ui_sound == nil and not self.face.texture or self.ui_sound) and self.current_choice ~= old_choice then
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