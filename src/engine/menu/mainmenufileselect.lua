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
    self:registerEvent("pause", self.onPause)
    self:registerEvent("resume", self.onResume)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuFileSelect:onEnter(old_state)
    self.mod = self.menu.selected_mod
    self.threat = 0

    self.container = self.menu.container:addChild(Object())
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
    self.bottom_options = {
        {{"copy", "Copy", 108}, {"erase", "Erase", 280}, {"exit", "Back", 468}}
    }
end

function MainMenuFileSelect:onResume(old_state)
    self.container.visible = true
    self.container.active = true
end

function MainMenuFileSelect:onLeave(new_state)
    self.container:remove()
    self.container = nil
end

function MainMenuFileSelect:onPause()
    self.container.visible = false
    self.container.active = false
end

function MainMenuFileSelect:onKeyPressed(key, is_repeat)
    if is_repeat or self.state == "TRANSITIONING" then
        return true
    end
    if self.focused_button then
        local button = self.focused_button
        if Input.is("cancel", key) then
            button.state = nil
            button:setChoices()
            if self.state == "COPY" then
                self.selected_y = self.copied_button.id
                self.copied_button.state = nil
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
                        self.menu:loadGame(self.selected_y, save_name)
                    else
                        self.menu:pushState("FILENAME")

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
                    button.state = "ERASE"
                    button:setChoices({ self:getText"EraseFinalYes", self:getText"EraseFinalNo" }, self:getText("EraseFinalConfirm"))
                    self.erase_stage = 2
                else
                    local result
                    if button.selected_choice == 1 and self.erase_stage == 2 then
                        Assets.stopAndPlaySound("ui_spooky_action")
                        Kristal.eraseData("file_" .. button.id, self.mod.id)
                        button:setData(nil)
                        result = "EraseComplete"
                    else
                        Assets.stopAndPlaySound("ui_select")
                        if self:getText("EraseSpared") then
                            result = "EraseSpared"
                        end
                        if self.erase_stage == 2 and self:getText("EraseThreatReached") then
                            self.threat = self.threat + 1
                            if self.threat > 9 then
                                self.threat = 0
                                result = "EraseThreatReached"
                            end
                        end
                    end
                    button:setChoices()
                    button.state = nil
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
                    self:setState("SELECT", "CopyCompleteOverw")
                    self.copied_button.state = nil
                    self.copied_button = nil
                    self.focused_button = nil
                    self.selected_x = 1
                    self.selected_y = 4
                    self:updateSelected()
                elseif button.selected_choice == 2 then
                    Assets.stopAndPlaySound("ui_select")
                    button:setChoices()
                    self:setState("SELECT")
                    self.copied_button.state = nil
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
				if MainMenu.mod_list:getSelectedMod().soulColor then
					MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
				end
            end
            if #self.menu.state_manager.state_stack > 0 then
                self.menu:popState()
            end
            Assets.stopAndPlaySound("ui_cancel")
            return true
        end
        if Input.is("confirm", key) then
            Assets.stopAndPlaySound("ui_select")
            if self.selected_y <= 3 then
                self.focused_button = self:getSelectedFile()
                if self.focused_button.data then
                    self.focused_button:setChoices({ self:getText "Continue", self:getText "Back" })
                else
                    self.focused_button:setChoices({ self:getText "Start", self:getText "Back" })
                end
            elseif self.selected_y >= 4 then
                self:processExtraButton(self.bottom_options[self.selected_y - 3][self.selected_x][1])
            end
            return true
        end
        local last_x, last_y = self.selected_x, self.selected_y
        if Input.is("up", key) then self.selected_y = self.selected_y - 1 end
        if Input.is("down", key) then self.selected_y = self.selected_y + 1 end
        if Input.is("left", key) then self.selected_x = self.selected_x - 1 end
        if Input.is("right", key) then self.selected_x = self.selected_x + 1 end
        self.selected_y = Utils.clamp(self.selected_y, 1, #self.bottom_options + 3)
        if self.selected_y <= 3 then
            self.selected_x = 1
        else
            self.selected_x = Utils.clamp(self.selected_x, 1, 3)
            local function cond(n)
                return self.selected_x == n and not self.bottom_options[self.selected_y - 3][self.selected_x]
            end
            if cond(1) then self.selected_x = 2 end
            if cond(2) and not Input.is("left",key) then self.selected_x = 3 end
            if cond(3) then self.selected_x = 2 end
            if cond(2) then self.selected_x = 1 end
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
                self.copied_button.state = nil
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
                        self.copied_button.state = "COPY"
                        self.selected_y = 1
                        self:updateSelected()
                    else
                        Assets.stopAndPlaySound("ui_cancel")
                        self:setResultText("CopyEmpty")
                    end
                else
                    local selected = self:getSelectedFile()
                    if selected == self.copied_button then
                        Assets.stopAndPlaySound("ui_cancel")
                        self:setResultText("CopySelf")
                    elseif selected.data then
                        Assets.stopAndPlaySound("ui_select")
                        self.focused_button = selected
                        self.focused_button:setChoices({ self:getText "Yes", self:getText "No" }, self:getText"CopyOver")
                    else
                        Assets.stopAndPlaySound("ui_spooky_action")
                        local data = Kristal.loadData("file_" .. self.copied_button.id, self.mod.id)
                        Kristal.saveData("file_" .. selected.id, data, self.mod.id)
                        selected:setData(data)
                        self:setState("SELECT", "CopyComplete")
                        self.copied_button.state = nil
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
                    self.copied_button.state = nil
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
                    self.focused_button:setChoices({ self:getText "Yes", self:getText "No" }, self:getText "EraseConfirm")
                    Assets.stopAndPlaySound("ui_select")
                else
                    self:setResultText("EraseEmpty")
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
    self:drawHeader()

    local function setColor(x, y)
        if self.selected_x == x and self.selected_y == y then
            Draw.setColor(PALETTE["fileselect_selected"])
        else
            Draw.setColor(PALETTE["fileselect_deselected"])
        end
    end

    local height = 40
    if #self.bottom_options > 2 then height = 20 end
    if self.state == "SELECT" or self.state == "TRANSITIONING" then
        for row_id, row in ipairs(self.bottom_options) do
            for col_id, col in ipairs(row) do
                if col and col[1] then
                    setColor(col_id, row_id+3)
                    local x = col[3] or (self.bottom_row_heart[col_id] + 28)
                    local y = 380 + ((row_id - 1) * height)
                    -- x = col_id * 60
                    Draw.printShadow(col[2], x, y)
                end
            end
        end
    else
        setColor(1, 4)
        Draw.printShadow(self:getText "Cancel", 110, 380)
    end
    Draw.setColor(1, 1, 1)
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuFileSelect:drawHeader()
    local mod_name = string.upper(self.mod.name or self.mod.id)
    Draw.printShadow(mod_name, 16, 8)

    Draw.printShadow(self:getTitle(), 80, 60)
end

function MainMenuFileSelect:getTitle()
    if self.result_text then
        return self:getText(self.result_text)
    end
    if self.state == "SELECT" or self.state == "TRANSITIONING" then
        return self:getText("SelectionTitle")
    else
        if self.state == "ERASE" then
            return self:getText("Erase")
        elseif self.state == "COPY" then
            if not self.copied_button then
                return self:getText("Copy")
            elseif not self.focused_button then
                return self:getText("CopyTo")
            else
                return self:getText("CopyOverTitle")
            end
        end
    end
end

function MainMenuFileSelect:processExtraButton(id)
    if id == "copy" then
        self:setState("COPY")
        self.selected_x = 1
        self.selected_y = 1
        self:updateSelected()
    elseif id == "erase" then
        self:setState("ERASE")
        self.erase_stage = 1
        self.selected_x = 1
        self.selected_y = 1
        self:updateSelected()
    elseif id == "exit" then
        if not TARGET_MOD and MainMenu.mod_list:getSelectedMod().soulColor then
            MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
        end
        if #self.menu.state_manager.state_stack > 0 then
            self.menu:popState()
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
    elseif self.selected_y >= 4 then
        local height = 40
        if #self.bottom_options > 2 then height = 20 end
        return self.bottom_row_heart[self.selected_x] + 9, 390 + 9 + (self.selected_y - 4) * height
    end
end

function MainMenuFileSelect:getText(string)
    local txts = {
        SelectionTitle = "Please select a file.",
        Copy = "Choose a file to copy.",
        CopyTo = "Choose a file to copy to.",
        Erase = "Choose a file to erase.",
        EraseConfirm = "Erase this file?",
        EraseFinalConfirm = "Really erase it?",
        CopySelf = "You can't copy there.",
        Cancel = "Cancel",
        Start = "Start",
        Back = "Back",
        Continue = "Continue",
        EraseFinalYes = "Yes!",
        EraseFinalNo = "No!",
        CopyOver = "Copy over this file?",
        CopyOverTitle = "The file will be overwritten.",
        Yes = "Yes",
        No = "No",
        CopyComplete = "Copy complete.",
        CopyCompleteOverw = "Copy complete.",
        EraseComplete = "Erase complete.",
        EraseEmpty = "There's nothing to erase.",
        CopyEmpty = "It can't be copied.",
        EraseSpared = false,
        EraseThreatReached = false,
    }
    if txts[string] == false then return end
    return txts[string] or ("["..string.."]")
end

return MainMenuFileSelect
