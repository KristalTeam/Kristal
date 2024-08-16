---@class DarkStorageMenu : Object
---@overload fun(...) : DarkStorageMenu
local DarkStorageMenu, super = Class(Object)

function DarkStorageMenu:init(top_storage, bottom_storage)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self:setParallax(0, 0)

    self.draw_children_below = 0

    self.font = Assets.getFont("plain")

    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")

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

    -- SELECT, SWAP
    self.state = "SELECT"

    self.list = 1

    self.storages = {top_storage or "items", bottom_storage or "storage"}

    self.selected_x = {1, 1}
    self.selected_y = {1, 1}
    self.selected_page = {1, 1}

    self.text_x = {155, 155}
    self.text_y = {144, 294}

    self.arrow_y = {188, 340}

    self.heart_target_x = self.text_x[1] - 10.5
    self.heart_target_y = self.text_y[1] + 8.5
    self.heart:setPosition(self.heart_target_x, self.heart_target_y)
end

function DarkStorageMenu:getStorage(list)
    return Game.inventory:getStorage(self.storages[list or self.list])
end

function DarkStorageMenu:getSelectedIndex(list)
    local page_offset = (self.selected_page[list or self.list] - 1) * 12
    return page_offset + self.selected_x[list or self.list] + (self.selected_y[list or self.list] - 1) * 2
end

function DarkStorageMenu:getMaxPages(list)
    return math.floor((self:getStorage(list).max - 1) / 12) + 1
end

function DarkStorageMenu:getSelectedItem(list)
    return Game.inventory:getItem(self:getStorage(list), self:getSelectedIndex(list))
end

function DarkStorageMenu:updateDescription()
    local item = self:getSelectedItem(self.list)
    local new_text = "---"
    if item then
        new_text = item:getDescription()
    end
    if self.description.text ~= new_text then
        self.description:setText(new_text)
    end
end

function DarkStorageMenu:update()
    if Input.pressed("left", true) then
        self.selected_x[self.list] = self.selected_x[self.list] - 1
        if self.selected_x[self.list] < 1 then
            self.selected_x[self.list] = 2
            if self.selected_page[self.list] > 1 then
                self.selected_page[self.list] = self.selected_page[self.list] - 1
            else
                self.selected_page[self.list] = self:getMaxPages(self.list)
            end
        end
    end
    if Input.pressed("right", true) then
        self.selected_x[self.list] = self.selected_x[self.list] + 1
        if self.selected_x[self.list] > 2 then
            self.selected_x[self.list] = 1
            if self.selected_page[self.list] < self:getMaxPages(self.list) then
                self.selected_page[self.list] = self.selected_page[self.list] + 1
            else
                self.selected_page[self.list] = 1
            end
        end
    end
    if Input.pressed("up", true) then
        self.selected_y[self.list] = self.selected_y[self.list] - 1
        if self.selected_y[self.list] < 1 then
            self.selected_y[self.list] = 6
        end
    end
    if Input.pressed("down", true) then
        self.selected_y[self.list] = self.selected_y[self.list] + 1
        if self.selected_y[self.list] > 6 then
            self.selected_y[self.list] = 1
        end
    end
    if self.state == "SELECT" then
        if Input.pressed("confirm", false) then
            if self:getStorage(self.list).max < self:getSelectedIndex(self.list) then
                self.ui_cant_select:stop()
                self.ui_cant_select:play()
            else
                self.state = "SWAP"
                self.list = 2
            end
        elseif Input.pressed("cancel", false) then
            self:remove()
            Game.world:closeMenu()
        end
    elseif self.state == "SWAP" then
        if Input.pressed("confirm", false) then
            if self:getStorage(self.list).max < self:getSelectedIndex(self.list) then
                self.ui_cant_select:stop()
                self.ui_cant_select:play()
            else
                Game.inventory:swapItems(
                    self:getStorage(1), self:getSelectedIndex(1),
                    self:getStorage(2), self:getSelectedIndex(2)
                )

                self.ui_select:stop()
                self.ui_select:play()

                self.state = "SELECT"
                self.list = 1
            end
        elseif Input.pressed("cancel", false) then
            self.state = "SELECT"
            self.list = 1
        end
    end

    self:updateDescription()

    -- Update the heart target position
    self.heart_target_x = self.text_x[self.list] + (self.selected_x[self.list] - 1) * 220 - 10.5
    self.heart_target_y = self.text_y[self.list] + (self.selected_y[self.list] - 1) * 20  + 8.5

    -- Move the heart closer to the target
    if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
        self.heart.x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart.y)) <= 2) then
        self.heart.y = self.heart_target_y
    end
    self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
    self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT
end

function DarkStorageMenu:draw()
    love.graphics.setLineWidth(4)
    Draw.setColor(PALETTE["world_border"])
    love.graphics.rectangle("line", 42, 122, 557, 155)
    love.graphics.rectangle("line", 42, 277, 557, 152)
    Draw.setColor(PALETTE["world_fill"])
    love.graphics.rectangle("fill", 44, 124, 553, 151)
    love.graphics.rectangle("fill", 44, 279, 553, 148)
    love.graphics.setLineWidth(1)

    self:drawStorage(1)
    self:drawStorage(2)

    super.draw(self)
end

function DarkStorageMenu:drawStorage(list)
    local text_x = self.text_x[list]
    local text_y = self.text_y[list]

    local name_text_x = text_x - 94
    local name_text_y = text_y - 6

    local page_text_x = name_text_x
    local page_text_y = name_text_y + 70

    local storage = self:getStorage(list)

    love.graphics.setFont(self.font)

    Draw.setColor(self.list == list and PALETTE["world_light_gray"] or PALETTE["world_dark_gray"])
    love.graphics.print(storage.id == "items" and "POCKET" or storage.name, name_text_x, name_text_y)

    local max_pages = self:getMaxPages(list)
    if max_pages > 1 then
        love.graphics.print("Page", page_text_x, page_text_y)
        love.graphics.print(self.selected_page[list].."/"..max_pages, page_text_x, page_text_y + 20)
    end

    for i = 1, 2 do
        for j = 1, 6 do
            local page_offset = (self.selected_page[list] - 1) * 12
            local item_index = page_offset + i + (j - 1) * 2
            local x = self.text_x[list] + (i - 1) * 220
            local y = self.text_y[list] + (j - 1) * 20
            local storage = Game.inventory:getStorage(self.storages[list])
            local item = Game.inventory:getItem(storage, item_index)
            if storage.max < item_index then
                Draw.setColor(PALETTE["world_dark_gray"])
            elseif self.list ~= list and list ~= 1 then
                Draw.setColor(PALETTE["world_gray"])
            elseif self.selected_x[list] == i and self.selected_y[list] == j then
                Draw.setColor(PALETTE["world_text_selected"])
            else
                Draw.setColor(PALETTE["world_text"])
            end
            if item then
                love.graphics.print(item:getName(), x, y)
            else
                love.graphics.print("---", x, y)
            end
        end
    end

    Draw.setColor(1, 1, 1, 1)
    if self.list == list and max_pages > 1 then
        local left_arrow_x, left_arrow_y = 32, self.arrow_y[list]
        local right_arrow_x, right_arrow_y = 592, self.arrow_y[list]
        local offset = Utils.round(math.sin(Kristal.getTime() * 5)) * 2
        Draw.draw(self.arrow_left, left_arrow_x - offset, left_arrow_y, 0, 2, 2)
        Draw.draw(self.arrow_right, right_arrow_x + offset, right_arrow_y, 0, 2, 2)
    end
end

return DarkStorageMenu