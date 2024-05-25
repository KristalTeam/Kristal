---@class SaveMenu : Object
---@overload fun(...) : SaveMenu
local SaveMenu, super = Class(Object)

function SaveMenu:init(marker)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.parallax_x = 0
    self.parallax_y = 0

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_select = Assets.newSound("ui_select")

    self.heart_sprite = Assets.getTexture("player/heart")
    self.divider_sprite = Assets.getTexture("ui/box/dark/top")

    self.main_box = UIBox(124, 130, 391, 154)
    self.main_box.layer = -1
    self:addChild(self.main_box)

    self.save_box = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.save_box:setColor(0, 0, 0, 0.8)
    self.save_box.layer = -1
    self.save_box.visible = false
    self:addChild(self.save_box)

    self.save_header = UIBox(92, 44, 457, 42)
    self.save_box:addChild(self.save_header)

    self.save_list = UIBox(92, 156, 457, 258)
    self.save_box:addChild(self.save_list)

    self.overwrite_box = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.overwrite_box:setColor(0, 0, 0, 0.8)
    self.overwrite_box.layer = 1
    self.overwrite_box.visible = false
    self:addChild(self.overwrite_box)

    self.overwrite_box:addChild(UIBox(42, 132, 557, 217))

    self.marker = marker

    -- MAIN, SAVE, SAVED, OVERWRITE
    self.state = "MAIN"

    self.selected_x = 1
    self.selected_y = 1

    self.saved_file = nil

    self.saves = {}
    for i = 1, 3 do
        self.saves[i] = Kristal.getSaveFile(i)
    end
end

function SaveMenu:updateSaveBoxSize()
    if self.state == "SAVED" then
        self.save_list.height = 210
    else
        self.save_list.height = 258
    end
end

function SaveMenu:update()
    if self.state == "MAIN" then
        if Input.pressed("cancel") then
            self:remove()
            Game.world:closeMenu()
        end
        if Input.pressed("left") or Input.pressed("right") then
            self.selected_x = self.selected_x == 1 and 2 or 1
        end
        if Input.pressed("up") or Input.pressed("down") then
            self.selected_y = self.selected_y == 1 and 2 or 1
        end
        if Input.pressed("confirm") then
            if self.selected_x == 1 and self.selected_y == 1 then
                self.state = "SAVE"

                self.ui_select:stop()
                self.ui_select:play()

                self.selected_y = Game.save_id
                self.saved_file = nil

                self.main_box.visible = false
                self.save_box.visible = true
                self:updateSaveBoxSize()
            elseif self.selected_x == 2 and self.selected_y == 1 then
                self:remove()
                Game.world:closeMenu()
            elseif self.selected_x == 1 and self.selected_y == 2 then
                if Game.inventory.storage_enabled then
                    Input.clear("confirm")
                    self:remove()
                    Game.world:closeMenu()
                    Game.world:openMenu(DarkStorageMenu())
                end
            elseif self.selected_x == 2 and self.selected_y == 2 then
                if Game:getConfig("enableRecruits") and #Game:getRecruits(true) > 0 then
                    Input.clear("confirm")
                    self:remove()
                    Game.world:closeMenu()
                    Game.world:openMenu(RecruitMenu())
                end
            end
        end
    elseif self.state == "SAVE" then
        if Input.pressed("cancel") then
            self.state = "MAIN"

            self.ui_select:stop()
            self.ui_select:play()

            self.selected_x = 1
            self.selected_y = 1

            self.main_box.visible = true
            self.save_box.visible = false
        end
        local last_selected = self.selected_y
        if Input.pressed("up") then
            self.selected_y = self.selected_y - 1
        end
        if Input.pressed("down") then
            self.selected_y = self.selected_y + 1
        end
        self.selected_y = Utils.clamp(self.selected_y, 1, 4)
        if Input.pressed("confirm") then
            self.ui_select:stop()
            self.ui_select:play()

            if self.selected_y == 4 then
                self.state = "MAIN"

                self.selected_x = 1
                self.selected_y = 1

                self.main_box.visible = true
                self.save_box.visible = false
            elseif self.selected_y ~= Game.save_id and self.saves[self.selected_y] then
                self.state = "OVERWRITE"

                self.overwrite_box.visible = true
            else
                self.state = "SAVED"

                self.saved_file = self.selected_y
                Kristal.saveGame(self.saved_file, Game:save(self.marker))
                self.saves[self.saved_file] = Kristal.getSaveFile(self.saved_file)

                Assets.playSound("save")
                self:updateSaveBoxSize()
            end
        end
    elseif self.state == "SAVED" then
        if Input.pressed("cancel") or Input.pressed("confirm") then
            self:remove()
            Game.world:closeMenu()
        end
    elseif self.state == "OVERWRITE" then
        if Input.pressed("cancel") then
            self.state = "SAVE"

            self.selected_x = 1
            self.overwrite_box.visible = false
        end
        if Input.pressed("left") or Input.pressed("right") then
            self.selected_x = self.selected_x == 1 and 2 or 1
        end
        if Input.pressed("confirm") then
            if self.selected_x == 1 then
                self.state = "SAVED"

                self.saved_file = self.selected_y
                Kristal.saveGame(self.saved_file, Game:save(self.marker))
                self.saves[self.saved_file] = Kristal.getSaveFile(self.saved_file)

                Assets.playSound("save")

                self.selected_x = 1
                self.overwrite_box.visible = false
                self:updateSaveBoxSize()
            else
                self.state = "SAVE"

                self.selected_x = 1
                self.overwrite_box.visible = false
            end
        end
    end

    super.update(self)
end

function SaveMenu:draw()
    love.graphics.setFont(self.font)
    if self.state == "MAIN" then
        local data = Game:getSavePreview()

        -- Header
        Draw.setColor(PALETTE["world_text"])
        love.graphics.print(data.name, 120, 120)
        love.graphics.print("LV "..data.level, 352, 120)

        local minutes = math.floor(data.playtime / 60)
        local seconds = math.floor(data.playtime % 60)
        local time_text = string.format("%d:%02d", minutes, seconds)
        love.graphics.print(time_text, 520 - self.font:getWidth(time_text), 120)

        -- Room name
        love.graphics.print(data.room_name, 319.5 - self.font:getWidth(data.room_name)/2, 170)

        -- Buttons
        love.graphics.print("Save", 170, 220)
        love.graphics.print("Return", 350, 220)
        if Game.inventory.storage_enabled then
            Draw.setColor(PALETTE["world_text"])
        else
            Draw.setColor(PALETTE["world_gray"])
        end
        love.graphics.print("Storage", 170, 260)
        
        if Game:getConfig("enableRecruits") and #Game:getRecruits(true) > 0 then
            Draw.setColor(PALETTE["world_text"])
        else
            Draw.setColor(PALETTE["world_gray"])
        end
        love.graphics.print("Recruits", 350, 260)

        -- Heart
        local heart_positions_x = {142, 322}
        local heart_positions_y = {228, 270}
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, heart_positions_x[self.selected_x], heart_positions_y[self.selected_y])
    elseif self.state == "SAVE" or self.state == "OVERWRITE" then
        self:drawSaveFile(0, Game:getSavePreview(), 74, 26, false, true)

        self:drawSaveFile(1, self.saves[1], 74, 138, self.selected_y == 1)
        Draw.draw(self.divider_sprite, 74, 208, 0, 493, 2)

        self:drawSaveFile(2, self.saves[2], 74, 222, self.selected_y == 2)
        Draw.draw(self.divider_sprite, 74, 292, 0, 493, 2)

        self:drawSaveFile(3, self.saves[3], 74, 306, self.selected_y == 3)
        Draw.draw(self.divider_sprite, 74, 376, 0, 493, 2)

        if self.selected_y == 4 then
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, 236, 402)

            Draw.setColor(PALETTE["world_text_selected"])
        else
            Draw.setColor(PALETTE["world_text"])
        end
        love.graphics.print("Return", 278, 394)
    elseif self.state == "SAVED" then
        self:drawSaveFile(self.saved_file, self.saves[self.saved_file], 74, 26, false, true)

        self:drawSaveFile(1, self.saves[1], 74, 138, self.selected_y == 1)
        Draw.draw(self.divider_sprite, 74, 208, 0, 493, 2)

        self:drawSaveFile(2, self.saves[2], 74, 222, self.selected_y == 2)
        Draw.draw(self.divider_sprite, 74, 292, 0, 493, 2)

        self:drawSaveFile(3, self.saves[3], 74, 306, self.selected_y == 3)
    end

    super.draw(self)

    if self.state == "OVERWRITE" then
        Draw.setColor(PALETTE["world_text"])
        local overwrite_text = "Overwrite Slot "..self.selected_y.."?"
        love.graphics.print(overwrite_text, SCREEN_WIDTH/2 - self.font:getWidth(overwrite_text)/2, 123)

        local function drawOverwriteSave(data, x, y)
            local w = 478

            -- Header
            love.graphics.print(data.name, x + (w/2) - self.font:getWidth(data.name)/2, y)
            love.graphics.print("LV "..data.level, x, y)

            local minutes = math.floor(data.playtime / 60)
            local seconds = math.floor(data.playtime % 60)
            local time_text = string.format("%d:%02d", minutes, seconds)
            love.graphics.print(time_text, x + w - self.font:getWidth(time_text), y)

            -- Room name
            love.graphics.print(data.room_name, x + (w/2) - self.font:getWidth(data.room_name)/2, y+30)
        end

        Draw.setColor(PALETTE["world_text"])
        drawOverwriteSave(self.saves[self.selected_y], 80, 165)
        Draw.setColor(PALETTE["world_text_selected"])
        drawOverwriteSave(Game:getSavePreview(), 80, 235)

        if self.selected_x == 1 then
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, 142, 332)

            Draw.setColor(PALETTE["world_text_selected"])
        else
            Draw.setColor(PALETTE["world_text"])
        end
        love.graphics.print("Save", 170, 324)

        if self.selected_x == 2 then
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, 322, 332)

            Draw.setColor(PALETTE["world_text_selected"])
        else
            Draw.setColor(PALETTE["world_text"])
        end
        love.graphics.print("Return", 350, 324)
    end
end

function SaveMenu:drawSaveFile(index, data, x, y, selected, header)
    if self.saved_file then
        if self.saved_file == index then
            Draw.setColor(PALETTE["world_text_selected"])
        else
            Draw.setColor(PALETTE["world_save_other"])
        end
    else
        if selected then
            Draw.setColor(PALETTE["world_text_selected"])
        else
            Draw.setColor(PALETTE["world_text"])
        end
    end
    if self.saved_file == index and not header then
        love.graphics.print("File Saved", x + 180, y + 22)
    elseif not data then
        love.graphics.print("New File", x + 193, y + 22)
        if selected then
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, x + 161, y + 30)
        end
    else
        if self.saved_file or header then
            love.graphics.print("LV "..data.level, x + 26, y + 6)
        else
            love.graphics.print("LV "..data.level, x + 50, y + 6)
        end

        love.graphics.print(data.name, x + (493 / 2) - self.font:getWidth(data.name) / 2, y + 6)

        local minutes = math.floor(data.playtime / 60)
        local seconds = math.floor(data.playtime % 60)
        local time_text = string.format("%d:%02d", minutes, seconds)
        love.graphics.print(time_text, x + 467 - self.font:getWidth(time_text), y + 6)

        love.graphics.print(data.room_name, x + (493 / 2) - self.font:getWidth(data.room_name) / 2, y + 38)

        if selected and not header then
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, x + 18, y + 14)
        end
    end
    Draw.setColor(1, 1, 1)
end

return SaveMenu