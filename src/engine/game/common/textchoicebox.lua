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

    self:setAdvance(false)
end

function TextChoicebox:update()
    super.update(self)
    if not self.text:isTyping() then
        if Input.pressed("left")  then self.current_choice = self.current_choice - 1 end
        if Input.pressed("right") then self.current_choice = self.current_choice + 1 end

        if self.current_choice < 1 then
            self.current_choice = #self.choices
        end

        if self.current_choice > #self.choices then
            self.current_choice = 1
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

    super.setText(self, self:transformText(text), callback)
end

function TextChoicebox:transformText(text)
    if self.face.texture then
        return text .. "\n" .. table.concat(self.choices, "     ")
    else
        return text .. "\n       " .. table.concat(self.choices, "     ")
    end
end

function TextChoicebox:isDone()
    return self.done
end

function TextChoicebox:draw()
    super.draw(self)
    if not self.text:isTyping() then
        local x = 122 + (self.current_choice - 1) * 192
        local y = 76
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart, x, y, 0, 2, 2)
        Draw.setColor(1, 1, 1)
    end
end

return TextChoicebox