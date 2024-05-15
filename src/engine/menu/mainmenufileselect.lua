---@class MainMenuFileSelect : StateClass
---
---@field menu MainMenu
---
---@overload fun(menu:MainMenu) : MainMenuFileSelect
local MainMenuFileSelect, super = Class(StateClass)

function MainMenuFileSelect:init(menu)
    self.menu = menu
end

function MainMenuFileSelect:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuFileSelect:onEnter(old_state)
    if old_state == "FILENAME" then
        self.container.visible = true
        self.container.active = true
        return
    end

    self.mod = self.menu.selected_mod

    self.container = self.menu.stage:addChild(Object())
    self.container:setLayer(50)

    -- SELECT, COPY, ERASE, TRANSITIONING
    self.state = "SELECT"

    self.result_text = nil
    self.result_timer = 0

    self.focused_button = nil
    self.copied_button = nil
    self.erase_stage = 1

    self.selected_x = 1
    self.selected_y = 1

    self.files = {}
    for i = 1, 3 do
        local data = Kristal.loadData("file_" .. i, self.mod.id)
        local button = FileButton(self, i, data, 110, 110 + 90 * (i - 1), 422, 82)
        if i == 1 then
            button.selected = true
        end
        table.insert(self.files, button)
        self.container:addChild(button)
    end

    self.bottom_row_heart = { 80, 250, 440 }
end

function MainMenuFileSelect:onLeave(new_state)
    if new_state == "FILENAME" then
        self.container.visible = false
        self.container.active = false
    else
        self.container:remove()
        self.container = nil
    end
end

function MainMenuFileSelect:onKeyPressed(key, is_repeat)
    if is_repeat or self.state == "TRANSITIONING" then
        return true
    end
    if self.focused_button then
        local button = self.focused_button
        if Input.is("cancel", key) then
            button:setColor(1, 1, 1)
            button:setChoices()
            if self.state == "COPY" then
                self.selected_y = self.copied_button.id
                self.copied_button:setColor(1, 1, 1)
                self.copied_button = nil
                self:updateSelected()
            elseif self.state == "ERASE" then
                self.erase_stage = 1
            end
            self.focused_button = nil
            Assets.stopAndPlaySound("ui_cancel")
            return true
        end
        if Input.is("left", key) and button.selected_choice == 2 then
            button.selected_choice = 1
            Assets.stopAndPlaySound("ui_move")
        end
        if Input.is("right", key) and button.selected_choice == 1 then
            button.selected_choice = 2
            Assets.stopAndPlaySound("ui_move")
        end
        if Input.is("confirm", key) then
            if self.state == "SELECT" then
                Assets.stopAndPlaySound("ui_select")
                if button.selected_choice == 1 then
                    local skip_naming = button.data ~= nil
                        or self.mod.nameInput == "none" or self.mod.nameInput == false
                        or Kristal.Config["skipNameEntry"] and self.mod.nameInput ~= "force"

                    if skip_naming then
                        self:setState("TRANSITIONING")
                        local save_name = nil
                        if not button.data and Kristal.Config["skipNameEntry"] and Kristal.Config["defaultName"] ~= "" then
                            save_name = string.sub(Kristal.Config["defaultName"], 1, self.mod["nameLimit"] or 12)
                        end
                        Kristal.loadMod(self.mod.id, self.selected_y, save_name)
                    else
                        self.menu:setState("FILENAME")

                        button:setChoices()
                        self.focused_button = nil
                    end
                elseif button.selected_choice == 2 then
                    button:setChoices()
                    self.focused_button = nil
                end
            elseif self.state == "ERASE" then
                if button.selected_choice == 1 and self.erase_stage == 1 then
                    Assets.stopAndPlaySound("ui_select")
                    button:setColor(1, 0, 0)
                    button:setChoices({ "Yes!", "No!" }, "Really erase it?")
                    self.erase_stage = 2
                else
                    local result
                    if button.selected_choice == 1 and self.erase_stage == 2 then
                        Assets.stopAndPlaySound("ui_spooky_action")
                        Kristal.eraseData("file_" .. button.id, self.mod.id)
                        button:setData(nil)
                        result = "Erase complete."
                    else
                        Assets.stopAndPlaySound("ui_select")
                    end
                    button:setChoices()
                    button:setColor(1, 1, 1)
                    self.focused_button = nil
                    self.erase_stage = 1

                    self:setState("SELECT", result)
                    self.selected_x = 2
                    self.selected_y = 4
                    self:updateSelected()
                end
            elseif self.state == "COPY" then
                if button.selected_choice == 1 then
                    Assets.stopAndPlaySound("ui_spooky_action")
                    local data = Kristal.loadData("file_" .. self.copied_button.id, self.mod.id)
                    Kristal.saveData("file_" .. button.id, data, self.mod.id)
                    button:setData(data)
                    button:setChoices()
                    self:setState("SELECT", "Copy complete.")
                    self.copied_button:setColor(1, 1, 1)
                    self.copied_button = nil
                    self.focused_button = nil
                    self.selected_x = 1
                    self.selected_y = 4
                    self:updateSelected()
                elseif button.selected_choice == 2 then
                    Assets.stopAndPlaySound("ui_select")
                    button:setChoices()
                    self:setState("SELECT")
                    self.copied_button:setColor(1, 1, 1)
                    self.copied_button = nil
                    self.focused_button = nil
                    self.selected_x = 1
                    self.selected_y = 4
                    self:updateSelected()
                end
            end
        end
    elseif self.state == "SELECT" then
        if Input.is("cancel", key) then
            if not TARGET_MOD then
                self.menu:setState("MODSELECT")
				if MainMenu.mod_list:getSelectedMod().soulColor then
					MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
				end
            else
                self.menu:setState("TITLE")
                self.menu.title_screen:selectOption("play")
            end
            Assets.stopAndPlaySound("ui_cancel")
            return true
        end
        if Input.is("confirm", key) then
            Assets.stopAndPlaySound("ui_select")
            if self.selected_y <= 3 then
                self.focused_button = self:getSelectedFile()
                if self.focused_button.data then
                    self.focused_button:setChoices({ "Continue", "Back" })
                else
                    self.focused_button:setChoices({ "Start", "Back" })
                end
            elseif self.selected_y == 4 then
                if self.selected_x == 1 then
                    self:setState("COPY")
                    self.selected_x = 1
                    self.selected_y = 1
                    self:updateSelected()
                elseif self.selected_x == 2 then
                    self:setState("ERASE")
                    self.erase_stage = 1
                    self.selected_x = 1
                    self.selected_y = 1
                    self:updateSelected()
                elseif self.selected_x == 3 then
                    if not TARGET_MOD then
                        self.menu:setState("MODSELECT")
						if MainMenu.mod_list:getSelectedMod().soulColor then
							MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
						end
                    else
                        self.menu:setState("TITLE")
                        self.menu.title_screen:selectOption("play")
                    end
                end
            end
            return true
        end
        local last_x, last_y = self.selected_x, self.selected_y
        if Input.is("up", key) then self.selected_y = self.selected_y - 1 end
        if Input.is("down", key) then self.selected_y = self.selected_y + 1 end
        if Input.is("left", key) then self.selected_x = self.selected_x - 1 end
        if Input.is("right", key) then self.selected_x = self.selected_x + 1 end
        self.selected_y = Utils.clamp(self.selected_y, 1, 4)
        if self.selected_y <= 3 then
            self.selected_x = 1
        else
            self.selected_x = Utils.clamp(self.selected_x, 1, 3)
        end
        if last_x ~= self.selected_x or last_y ~= self.selected_y then
            Assets.stopAndPlaySound("ui_move")
            self:updateSelected()
        end
    elseif self.state == "COPY" then
        if Input.is("cancel", key) then
            Assets.stopAndPlaySound("ui_cancel")
            if self.copied_button then
                self.selected_y = self.copied_button.id
                self.copied_button:setColor(1, 1, 1)
                self.copied_button = nil
                self:updateSelected()
            else
                self:setState("SELECT")
                self.selected_x = 1
                self.selected_y = 4
                self:updateSelected()
            end
            return true
        end
        if Input.is("confirm", key) then
            if self.selected_y <= 3 then
                if not self.copied_button then
                    local button = self:getSelectedFile()
                    if button.data then
                        Assets.stopAndPlaySound("ui_select")
                        self.copied_button = self:getSelectedFile()
                        self.copied_button:setColor(1, 1, 0.5)
                        self.selected_y = 1
                        self:updateSelected()
                    else
                        Assets.stopAndPlaySound("ui_cancel")
                        self:setResultText("It can't be copied.")
                    end
                else
                    local selected = self:getSelectedFile()
                    if selected == self.copied_button then
                        Assets.stopAndPlaySound("ui_cancel")
                        self:setResultText("You can't copy there.")
                    elseif selected.data then
                        Assets.stopAndPlaySound("ui_select")
                        self.focused_button = selected
                        self.focused_button:setChoices({ "Yes", "No" }, "Copy over this file?")
                    else
                        Assets.stopAndPlaySound("ui_spooky_action")
                        local data = Kristal.loadData("file_" .. self.copied_button.id, self.mod.id)
                        Kristal.saveData("file_" .. selected.id, data, self.mod.id)
                        selected:setData(data)
                        self:setState("SELECT", "Copy complete.")
                        self.copied_button:setColor(1, 1, 1)
                        self.copied_button = nil
                        self.selected_x = 1
                        self.selected_y = 4
                        self:updateSelected()
                    end
                end
            elseif self.selected_y == 4 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("SELECT")
                if self.copied_button then
                    self.copied_button:setColor(1, 1, 1)
                    self.copied_button = nil
                end
                self.selected_x = 1
                self.selected_y = 4
                self:updateSelected()
            end
            return true
        end
        local last_x, last_y = self.selected_x, self.selected_y
        if Input.is("up", key) then self.selected_y = self.selected_y - 1 end
        if Input.is("down", key) then self.selected_y = self.selected_y + 1 end
        self.selected_x = 1
        self.selected_y = Utils.clamp(self.selected_y, 1, 4)
        if last_x ~= self.selected_x or last_y ~= self.selected_y then
            Assets.stopAndPlaySound("ui_move")
            self:updateSelected()
        end
    elseif self.state == "ERASE" then
        if Input.is("cancel", key) then
            Assets.stopAndPlaySound("ui_cancel")
            self:setState("SELECT")
            self.selected_x = 2
            self.selected_y = 4
            self:updateSelected()
            return true
        end
        if Input.is("confirm", key) then
            if self.selected_y <= 3 then
                local button = self:getSelectedFile()
                if button.data then
                    self.focused_button = button
                    self.focused_button:setChoices({ "Yes", "No" }, "Erase this file?")
                    Assets.stopAndPlaySound("ui_select")
                else
                    self:setResultText("There's nothing to erase.")
                    Assets.stopAndPlaySound("ui_cancel")
                end
            elseif self.selected_y == 4 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("SELECT")
                self.selected_x = 2
                self.selected_y = 4
                self:updateSelected()
            end
            return true
        end
        local last_x, last_y = self.selected_x, self.selected_y
        if Input.is("up", key) then self.selected_y = self.selected_y - 1 end
        if Input.is("down", key) then self.selected_y = self.selected_y + 1 end
        self.selected_x = 1
        self.selected_y = Utils.clamp(self.selected_y, 1, 4)
        if last_x ~= self.selected_x or last_y ~= self.selected_y then
            Assets.stopAndPlaySound("ui_move")
            self:updateSelected()
        end
    end

    return true
end

function MainMenuFileSelect:update()
    if self.result_timer > 0 then
        self.result_timer = Utils.approach(self.result_timer, 0, DT)
        if self.result_timer == 0 then
            self.result_text = nil
        end
    end

    self:updateSelected()

    self.menu.heart_target_x, self.menu.heart_target_y = self:getHeartPos()
end

function MainMenuFileSelect:draw()
    local mod_name = string.upper(self.mod.name or self.mod.id)
    Draw.printShadow(mod_name, 16, 8)

    Draw.printShadow(self:getTitle(), 80, 60)

    local function setColor(x, y)
        if self.selected_x == x and self.selected_y == y then
            Draw.setColor(1, 1, 1)
        else
            Draw.setColor(0.6, 0.6, 0.7)
        end
    end

    if self.state == "SELECT" or self.state == "TRANSITIONING" then
        setColor(1, 4)
        Draw.printShadow("Copy", 108, 380)
        setColor(2, 4)
        Draw.printShadow("Erase", 280, 380)
        setColor(3, 4)
        Draw.printShadow("Back", 468, 380)
    else
        setColor(1, 4)
        Draw.printShadow("Cancel", 110, 380)
    end

    Draw.setColor(1, 1, 1)
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuFileSelect:getTitle()
    if self.result_text then
        return self.result_text
    end
    if self.state == "SELECT" or self.state == "TRANSITIONING" then
        return "Please select a file."
    else
        if self.state == "ERASE" then
            return "Choose a file to erase."
        elseif self.state == "COPY" then
            if not self.copied_button then
                return "Choose a file to copy."
            elseif not self.focused_button then
                return "Choose a file to copy to."
            else
                return "The file will be overwritten."
            end
        end
    end
end

function MainMenuFileSelect:setState(state, result_text)
    self:setResultText(result_text)
    self.state = state
end

function MainMenuFileSelect:setResultText(text)
    self.result_text = text
    self.result_timer = 3
end

function MainMenuFileSelect:updateSelected()
    for i, file in ipairs(self.files) do
        if i == self.selected_y or (self.state == "COPY" and self.copied_button == file) then
            file.selected = true
        else
            file.selected = false
        end
    end
end

function MainMenuFileSelect:getSelectedFile()
    return self.files[self.selected_y]
end

function MainMenuFileSelect:getHeartPos()
    if self.selected_y <= 3 then
        local button = self:getSelectedFile()
        local hx, hy = button:getHeartPos()
        local x, y = button:getRelativePos(hx, hy)
        return x + 9, y + 9
    elseif self.selected_y == 4 then
        return self.bottom_row_heart[self.selected_x] + 9, 390 + 9
    end
end

return MainMenuFileSelect
