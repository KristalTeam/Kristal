---@class FileList : Object
---@overload fun(...) : FileList
local FileList, super = Class(Object)

function FileList:init(menu, mod)
    super:init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.menu = menu
    self.mod = mod

    -- SELECT, COPY, ERASE, TRANSITIONING
    self.state = "SELECT"

    self.result_text = nil
    self.result_timer = 0

    self.focused_button = nil
    self.copied_button = nil
    self.erase_stage = 1

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cancel = Assets.newSound("ui_cancel")
    self.ui_spooky_action = Assets.newSound("ui_spooky_action")

    self.selected_x = 1
    self.selected_y = 1

    self.files = {}
    for i = 1, 3 do
        local data = Kristal.loadData("file_"..i, mod.id)
        local button = FileButton(self, i, data, 110, 110 + 90*(i-1), 422, 82)
        if i == 1 then
            button.selected = true
        end
        table.insert(self.files, button)
        self:addChild(button)
    end

    self.bottom_row_heart = {80, 250, 440}
end

function FileList:getTitle()
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

function FileList:setState(state, result_text)
    self:setResultText(result_text)
    self.state = state
end

function FileList:setResultText(text)
    self.result_text = text
    self.result_timer = 3
end

function FileList:updateSelected()
    for i,file in ipairs(self.files) do
        if i == self.selected_y or (self.state == "COPY" and self.copied_button == file) then
            file.selected = true
        else
            file.selected = false
        end
    end
end

function FileList:getSelectedFile()
    return self.files[self.selected_y]
end

function FileList:onKeyPressed(key)
    if self.state == "TRANSITIONING" then
        return
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
            self.ui_cancel:stop()
            self.ui_cancel:play()
            return
        end
        if Input.is("left", key) and button.selected_choice == 2 then
            button.selected_choice = 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.is("right", key) and button.selected_choice == 1 then
            button.selected_choice = 2
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.is("confirm", key) then
            if self.state == "SELECT" then
                self.ui_select:stop()
                self.ui_select:play()
                if button.selected_choice == 1 then
                    local skip_naming = button.data ~= nil
                        or self.mod.nameInput == "none" or self.mod.nameInput == false
                        or Kristal.Config["skipNameEntry"] and self.mod.nameInput ~= "force"

                    if skip_naming then
                        self:setState("TRANSITIONING")
                        local save_name = nil
                        if not button.data and Kristal.Config["skipNameEntry"] and Kristal.Config["defaultName"] ~= "" then
                            save_name = Kristal.Config["defaultName"]
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
                    self.ui_select:stop()
                    self.ui_select:play()
                    button:setColor(1, 0, 0)
                    button:setChoices({"Yes!", "No!"}, "Really erase it?")
                    self.erase_stage = 2
                else
                    local result
                    if button.selected_choice == 1 and self.erase_stage == 2 then
                        self.ui_spooky_action:stop()
                        self.ui_spooky_action:play()
                        Kristal.eraseData("file_"..button.id, self.mod.id)
                        button:setData(nil)
                        result = "Erase complete."
                    else
                        self.ui_select:stop()
                        self.ui_select:play()
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
                    self.ui_spooky_action:stop()
                    self.ui_spooky_action:play()
                    local data = Kristal.loadData("file_"..self.copied_button.id, self.mod.id)
                    Kristal.saveData("file_"..button.id, data, self.mod.id)
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
                    self.ui_select:stop()
                    self.ui_select:play()
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
            else
                self.menu:setState("MAINMENU")
                self.menu.heart_target_x = 196
                self.menu.heart_target_y = 238
            end
            self.ui_cancel:stop()
            self.ui_cancel:play()
            return
        end
        if Input.is("confirm", key) then
            self.ui_select:stop()
            self.ui_select:play()
            if self.selected_y <= 3 then
                self.focused_button = self:getSelectedFile()
                if self.focused_button.data then
                    self.focused_button:setChoices({"Continue", "Back"})
                else
                    self.focused_button:setChoices({"Start", "Back"})
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
                    else
                        self.menu:setState("MAINMENU")
                        self.menu.heart_target_x = 196
                        self.menu.heart_target_y = 238
                    end
                end
            end
            return
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
            self.ui_move:stop()
            self.ui_move:play()
            self:updateSelected()
        end
    elseif self.state == "COPY" then
        if Input.is("cancel", key) then
            self.ui_cancel:stop()
            self.ui_cancel:play()
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
            return
        end
        if Input.is("confirm", key) then
            if self.selected_y <= 3 then
                if not self.copied_button then
                    local button = self:getSelectedFile()
                    if button.data then
                        self.ui_select:stop()
                        self.ui_select:play()
                        self.copied_button = self:getSelectedFile()
                        self.copied_button:setColor(1, 1, 0.5)
                        self.selected_y = 1
                        self:updateSelected()
                    else
                        self.ui_cancel:stop()
                        self.ui_cancel:play()
                        self:setResultText("It can't be copied.")
                    end
                else
                    local selected = self:getSelectedFile()
                    if selected == self.copied_button then
                        self.ui_cancel:stop()
                        self.ui_cancel:play()
                        self:setResultText("You can't copy there.")
                    elseif selected.data then
                        self.ui_select:stop()
                        self.ui_select:play()
                        self.focused_button = selected
                        self.focused_button:setChoices({"Yes", "No"}, "Copy over this file?")
                    else
                        self.ui_spooky_action:stop()
                        self.ui_spooky_action:play()
                        local data = Kristal.loadData("file_"..self.copied_button.id, self.mod.id)
                        Kristal.saveData("file_"..selected.id, data, self.mod.id)
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
                self.ui_select:stop()
                self.ui_select:play()
                self:setState("SELECT")
                if self.copied_button then
                    self.copied_button:setColor(1, 1, 1)
                    self.copied_button = nil
                end
                self.selected_x = 1
                self.selected_y = 4
                self:updateSelected()
            end
            return
        end
        local last_x, last_y = self.selected_x, self.selected_y
        if Input.is("up", key) then self.selected_y = self.selected_y - 1 end
        if Input.is("down", key) then self.selected_y = self.selected_y + 1 end
        self.selected_x = 1
        self.selected_y = Utils.clamp(self.selected_y, 1, 4)
        if last_x ~= self.selected_x or last_y ~= self.selected_y then
            self.ui_move:stop()
            self.ui_move:play()
            self:updateSelected()
        end
    elseif self.state == "ERASE" then
        if Input.is("cancel", key) then
            self.ui_cancel:stop()
            self.ui_cancel:play()
            self:setState("SELECT")
            self.selected_x = 2
            self.selected_y = 4
            self:updateSelected()
            return
        end
        if Input.is("confirm", key) then
            if self.selected_y <= 3 then
                local button = self:getSelectedFile()
                if button.data then
                    self.focused_button = button
                    self.focused_button:setChoices({"Yes", "No"}, "Erase this file?")
                    self.ui_select:stop()
                    self.ui_select:play()
                else
                    self:setResultText("There's nothing to erase.")
                    self.ui_cancel:stop()
                    self.ui_cancel:play()
                end
            elseif self.selected_y == 4 then
                self.ui_select:stop()
                self.ui_select:play()
                self:setState("SELECT")
                self.selected_x = 2
                self.selected_y = 4
                self:updateSelected()
            end
            return
        end
        local last_x, last_y = self.selected_x, self.selected_y
        if Input.is("up", key) then self.selected_y = self.selected_y - 1 end
        if Input.is("down", key) then self.selected_y = self.selected_y + 1 end
        self.selected_x = 1
        self.selected_y = Utils.clamp(self.selected_y, 1, 4)
        if last_x ~= self.selected_x or last_y ~= self.selected_y then
            self.ui_move:stop()
            self.ui_move:play()
            self:updateSelected()
        end
    end
end

function FileList:getHeartPos()
    if self.selected_y <= 3 then
        local button = self:getSelectedFile()
        local hx, hy = button:getHeartPos()
        local x, y = button:getRelativePos(hx, hy, self)
        return x + 9, y + 9
    elseif self.selected_y == 4 then
        return self.bottom_row_heart[self.selected_x]+9, 390+9
    end
end

function FileList:update()
    if self.result_timer > 0 then
        self.result_timer = Utils.approach(self.result_timer, 0, DT)
        if self.result_timer == 0 then
            self.result_text = nil
        end
    end

    self:updateSelected()
    super:update(self)
end

function FileList:draw()
    local function setColor(x, y)
        if self.selected_x == x and self.selected_y == y then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.6, 0.6, 0.7)
        end
    end

    local title = self:getTitle()
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(title, 80+2, 60+2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 80, 60)

    if self.state == "SELECT" or self.state == "TRANSITIONING" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Copy", 108+2, 380+2)
        setColor(1, 4)
        love.graphics.print("Copy", 108, 380)

        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Erase", 280+2, 380+2)
        setColor(2, 4)
        love.graphics.print("Erase", 280, 380)

        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Back", 468+2, 380+2)
        setColor(3, 4)
        love.graphics.print("Back", 468, 380)
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Cancel", 110+2, 380+2)
        setColor(1, 4)
        love.graphics.print("Cancel", 110, 380)
    end

    super:draw(self)
end

return FileList