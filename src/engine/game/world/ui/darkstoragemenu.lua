local DarkStorageMenu, super = Class(Object)

function DarkStorageMenu:init()
    super:init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self:setParallax(0, 0)

    self.draw_children_below = 0

    self.font = Assets.getFont("plain")

    self.ui_select = Assets.newSound("ui_select")

    self.arrow_left = Assets.getTexture("ui/flat_arrow_left")
    self.arrow_right = Assets.getTexture("ui/flat_arrow_right")

    self.heart = Sprite("player/heart_menu")
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setColor(Game:getSoulColor())
    self.heart.layer = 100
    self:addChild(self.heart)

    self.description_box = Rectangle(0, 0, SCREEN_WIDTH, 121)
    self.description_box:setColor(0, 0, 0)
    self:addChild(self.description_box)

    self.description = Text("---", 20, 20, SCREEN_WIDTH - 20, 100)
    self.description_box:addChild(self.description)

    -- POCKET, STORAGE
    self.state = "POCKET"

    self.pocket_selected_x = 1
    self.pocket_selected_y = 1

    self.storage_selected_x = 1
    self.storage_selected_y = 1
    self.storage_page = 1
    -- temporary
    self.storage_page_max = 2

    self.pocket_text_x = 155
    self.pocket_text_y = 144

    self.storage_text_x = 155
    self.storage_text_y = 294

    self.heart_target_x = self.pocket_text_x - 10.5
    self.heart_target_y = self.pocket_text_y + 8.5

    self.heart:setPosition(self.heart_target_x, self.heart_target_y)
end

function DarkStorageMenu:getSelectedIndex(state)
    state = state or self.state
    if state == "POCKET" then
        return self.pocket_selected_x + (self.pocket_selected_y - 1) * 2
    elseif state == "STORAGE" then
        local page_offset = (self.storage_page - 1) * 12
        return page_offset + self.storage_selected_x + (self.storage_selected_y - 1) * 2
    end
end

function DarkStorageMenu:getSelectedStorage(state)
    state = state or self.state
    if state == "POCKET" then
        return "items"
    elseif state == "STORAGE" then
        return "storage"
    end
end

function DarkStorageMenu:getSelectedItem(state)
    return Game.inventory:getItem(self:getSelectedStorage(state), self:getSelectedIndex(state))
end

function DarkStorageMenu:updateDescription()
    local item = self:getSelectedItem(self.state)
    local new_text = "---"
    if item then
        new_text = item:getDescription()
    end
    if self.description.text ~= new_text then
        self.description:setText(new_text)
    end
end

function DarkStorageMenu:update(dt)
    if self.state == "POCKET" then
        if Input.pressed("confirm") then
            self.state = "STORAGE"
        elseif Input.pressed("cancel") then
            self:remove()
            Game.world:closeMenu()
        end
        if Input.pressed("left") then
            self.pocket_selected_x = self.pocket_selected_x - 1
            if self.pocket_selected_x < 1 then
                self.pocket_selected_x = 2
            end
        end
        if Input.pressed("right") then
            self.pocket_selected_x = self.pocket_selected_x + 1
            if self.pocket_selected_x > 2 then
                self.pocket_selected_x = 1
            end
        end
        if Input.pressed("up") then
            self.pocket_selected_y = self.pocket_selected_y - 1
            if self.pocket_selected_y < 1 then
                self.pocket_selected_y = 6
            end
        end
        if Input.pressed("down") then
            self.pocket_selected_y = self.pocket_selected_y + 1
            if self.pocket_selected_y > 6 then
                self.pocket_selected_y = 1
            end
        end
    elseif self.state == "STORAGE" then
        if Input.pressed("confirm") then
            Game.inventory:swapItems(
                self:getSelectedStorage("POCKET"), self:getSelectedIndex("POCKET"),
                self:getSelectedStorage("STORAGE"), self:getSelectedIndex("STORAGE")
            )

            self.ui_select:stop()
            self.ui_select:play()

            self.state = "POCKET"
        elseif Input.pressed("cancel") then
            self.state = "POCKET"
        end
        if Input.pressed("left") then
            self.storage_selected_x = self.storage_selected_x - 1
            if self.storage_selected_x < 1 then
                self.storage_selected_x = 2
                if self.storage_page > 1 then
                    self.storage_page = self.storage_page - 1
                else
                    self.storage_page = self.storage_page_max
                end
            end
        end
        if Input.pressed("right") then
            self.storage_selected_x = self.storage_selected_x + 1
            if self.storage_selected_x > 2 then
                self.storage_selected_x = 1
                if self.storage_page < self.storage_page_max then
                    self.storage_page = self.storage_page + 1
                else
                    self.storage_page = 1
                end
            end
        end
        if Input.pressed("up") then
            self.storage_selected_y = self.storage_selected_y - 1
            if self.storage_selected_y < 1 then
                self.storage_selected_y = 6
            end
        end
        if Input.pressed("down") then
            self.storage_selected_y = self.storage_selected_y + 1
            if self.storage_selected_y > 6 then
                self.storage_selected_y = 1
            end
        end
    end

    self:updateDescription()

    -- Update the heart target position
    if self.state == "POCKET" then
        self.heart_target_x = self.pocket_text_x + (self.pocket_selected_x - 1) * 220 - 10.5
        self.heart_target_y = self.pocket_text_y + (self.pocket_selected_y - 1) * 20  + 8.5
    elseif self.state == "STORAGE" then
        self.heart_target_x = self.storage_text_x + (self.storage_selected_x - 1) * 220 - 10.5
        self.heart_target_y = self.storage_text_y + (self.storage_selected_y - 1) * 20  + 8.5
    end

    -- Move the heart closer to the target
    if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
        self.heart.x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart.y)) <= 2)then
        self.heart.y = self.heart_target_y
    end
    self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * (dt * 30)
    self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * (dt * 30)
end

function DarkStorageMenu:draw()
    love.graphics.setLineWidth(4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 42, 122, 557, 155)
    love.graphics.rectangle("line", 42, 277, 557, 152)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 44, 124, 553, 151)
    love.graphics.rectangle("fill", 44, 279, 553, 148)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(self.font)

    local pocket_side_color = self.state == "POCKET" and {0.75, 0.75, 0.75} or {0.25, 0.25, 0.25}
    local storage_side_color = self.state == "STORAGE" and {0.75, 0.75, 0.75} or {0.25, 0.25, 0.25}

    love.graphics.setColor(pocket_side_color)
    love.graphics.print("POCKET", 61, 140)

    love.graphics.setColor(storage_side_color)
    love.graphics.print("STORAGE", 61, 290)
    love.graphics.print("Page", 61, 360)
    love.graphics.print(self.storage_page.."/"..self.storage_page_max, 61, 380)

    local pocket_color = self.state == "POCKET" and {1, 1, 1} or {0.5, 0.5, 0.5}
    local storage_color = self.state == "STORAGE" and {1, 1, 1} or {0.5, 0.5, 0.5}

    -- Draw pocket items
    for i = 1, 2 do
        for j = 1, 6 do
            local x = self.pocket_text_x + (i - 1) * 220
            local y = self.pocket_text_y + (j - 1) * 20
            local item = Game.inventory:getItem("items", i + (j - 1) * 2)
            if self.pocket_selected_x == i and self.pocket_selected_y == j then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(pocket_color)
            end
            if item then
                love.graphics.print(item:getName(), x, y)
            else
                love.graphics.print("---", x, y)
            end
        end
    end
    -- Draw storage items
    for i = 1, 2 do
        for j = 1, 6 do
            local page_offset = (self.storage_page - 1) * 12
            local x = self.storage_text_x + (i - 1) * 220
            local y = self.storage_text_y + (j - 1) * 20
            local item = Game.inventory:getItem("storage", page_offset + i + (j - 1) * 2)
            if self.storage_selected_x == i and self.storage_selected_y == j and self.state == "STORAGE" then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(storage_color)
            end
            if item then
                love.graphics.print(item:getName(), x, y)
            else
                love.graphics.print("---", x, y)
            end
        end
    end

    if self.state == "STORAGE" then
        local left_arrow_x, left_arrow_y = 32, 340
        local right_arrow_x, right_arrow_y = 592, 340
        local offset = Utils.round(math.sin(love.timer.getTime() * 5)) * 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.arrow_left, left_arrow_x - offset, left_arrow_y, 0, 2, 2)
        love.graphics.draw(self.arrow_right, right_arrow_x + offset, right_arrow_y, 0, 2, 2)
    end

    super:draw(self)
end

return DarkStorageMenu