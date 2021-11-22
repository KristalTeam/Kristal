local DarkSaveMenu, super = Class(Object)

function DarkSaveMenu:init()
    super:init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.parallax_x = 0
    self.parallax_y = 0

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_select = Assets.newSound("ui_select")

    self.heart_sprite = Assets.getTexture("player/heart")

    self.main_box = DarkBox(124, 130, 391, 154)
    self.main_box.layer = -1
    self:addChild(self.main_box)

    self.save_box = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.save_box:setColor(0, 0, 0, 0.8)
    self.save_box.layer = -1
    self.save_box.visible = false
    self:addChild(self.save_box)

    self.save_header = DarkBox(92, 44, 457, 42)
    self.save_box:addChild(self.save_header)

    self.save_list = DarkBox(92, 156, 457, 258)
    self.save_box:addChild(self.save_list)

    -- MAIN, SAVE
    self.state = "MAIN"

    self.selected_x = 1
    self.selected_y = 1

    self.saved_file = nil
end

function DarkSaveMenu:updateSaveBoxSize()
    if not self.saved_file then
        self.save_list.height = 258
    else
        self.save_list.height = 210
    end
end

function DarkSaveMenu:update(dt)
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
    end

    super:update(self, dt)
end

function DarkSaveMenu:draw()
    love.graphics.setFont(self.font)
    if self.state == "MAIN" then
        -- Header
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(Game.save_name, 120, 120)
        love.graphics.print("LV "..Game.chapter, 352, 120)

        local minutes = math.floor(Game.playtime / 60)
        local seconds = math.floor(Game.playtime % 60)
        local time_text = string.format("%d:%02d", minutes, seconds)
        love.graphics.print(time_text, 520 - self.font:getWidth(time_text), 120)

        -- Room name
        local room_text = Game.world.map.data.id
        love.graphics.print(room_text, 319.5 - self.font:getWidth(room_text)/2, 170)

        -- Buttons
        love.graphics.print("Save", 170, 220)
        love.graphics.print("Return", 350, 220)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Storage", 170, 260)
        love.graphics.print("Recruits", 350, 260)

        -- Heart
        local heart_positions_x = {142, 322}
        local heart_positions_y = {228, 270}
        love.graphics.setColor(1, 0, 0)
        love.graphics.draw(self.heart_sprite, heart_positions_x[self.selected_x], heart_positions_y[self.selected_y])
    elseif self.state == "SAVE" then
        
    end

    super:draw(self)
end

function DarkSaveMenu:drawSaveFile(index, data, x, y, selected, header)
    if self.saved_file then
        if self.saved_file == index then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(68/255, 68/255, 68/255)
        end
    end
    if selected then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    if not data then
        love.graphics.print("New File", x+193, y+22)
        if selected then
            love.graphics.setColor(1, 0, 0)
            love.graphics.draw(self.heart_sprite, x+161, y+30)
        end
    elseif self.saved_file == index and not header then
        love.graphics.print("File Saved", x+180, y+22)
    else
        if self.saved_file or self.header then
            love.graphics.print("LV "..data.level, x+26, y+6)
        else
            love.graphics.print("LV "..data.level, x+50, y+6)
        end

        love.graphics.print(data.name, x + (493/2) - self.font:getWidth(data.name)/2, y+6)

        local minutes = math.floor(data.playtime / 60)
        local seconds = math.floor(data.playtime % 60)
        local time_text = string.format("%d:%02d", minutes, seconds)
        love.graphics.print(time_text, x+467 - self.font:getWidth(time_text), y+6)

        love.graphics.print(data.room_name, x + (493/2) - self.font:getWidth(data.room_name)/2, y+38)

        
    end
end

return DarkSaveMenu