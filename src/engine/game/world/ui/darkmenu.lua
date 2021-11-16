local DarkMenu, super = Class(Object)

function DarkMenu:init()
    super:init(self, 0, -80)

    self.layer = 1 -- TODO

    self.parallax_x = 0
    self.parallax_y = 0

    self.animation_done = false
    self.animation_timer = 0
    self.animate_out = false

    self.selected_submenu = 1

    self.item_header_selected = 1
    self.equip_selected = 1
    self.power_selected = 1

    self.item_selected_x = 1
    self.item_selected_y = 1

    self.selected_party = 1

    self.selected_item = 1

    -- States: MAIN, ITEMMENU, ITEMSELECT, KEYSELECT, PARTYSELECT,
    -- EQUIPMENU, WEAPONSELECT, REPLACEMENTSELECT, POWERMENU, SPELLSELECT,
    -- CONFIGMENU, VOLUMESELECT, CONTROLSMENU, CONTROLSELECT
    self.state = "MAIN"
    self.state_reason = nil
    self.heart_sprite = Assets.getTexture("player/heart")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.font = Assets.getFont("main")

    self.desc_sprites = {
        Assets.getTexture("ui/menu/desc/item"),
        Assets.getTexture("ui/menu/desc/equip"),
        Assets.getTexture("ui/menu/desc/power"),
        Assets.getTexture("ui/menu/desc/config")
    }

    self.buttons = {
        {Assets.getTexture("ui/menu/btn/item"  ), Assets.getTexture("ui/menu/btn/item_h"  ), Assets.getTexture("ui/menu/btn/item_s"  )},
        {Assets.getTexture("ui/menu/btn/equip" ), Assets.getTexture("ui/menu/btn/equip_h" ), Assets.getTexture("ui/menu/btn/equip_s" )},
        {Assets.getTexture("ui/menu/btn/power" ), Assets.getTexture("ui/menu/btn/power_h" ), Assets.getTexture("ui/menu/btn/power_s" )},
        {Assets.getTexture("ui/menu/btn/config"), Assets.getTexture("ui/menu/btn/config_h"), Assets.getTexture("ui/menu/btn/config_s")}
    }

    self.box = nil
end

function DarkMenu:transitionOut()
    self.animate_out = true
    self.animation_timer = 0
    self.animation_done = false

    self.state = "MAIN"
    if self.box then
        self.box:remove()
    end
end

function DarkMenu:keypressed(key)
    if (Input.isMenu(key) or Input.isCancel(key)) and self.state == "MAIN" then
        Game.world:closeMenu()
        return
    end

    if not self.animation_done then return end

    if self.state == "MAIN" then
        local old_selected = self.selected_submenu
        if Input.is("left", key) then self.selected_submenu = self.selected_submenu - 1 end
        if Input.is("right", key) then self.selected_submenu = self.selected_submenu + 1 end
        if self.selected_submenu < 1 then self.selected_submenu = 4 end
        if self.selected_submenu > 4 then self.selected_submenu = 1 end
        if old_selected ~= self.selected_submenu then
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.isConfirm(key) then
            if self.selected_submenu == 1 then
                self.state = "ITEMMENU"

                self.box = DarkBox(92, 112, 457, 227)
                self.box.layer = -1
                self:addChild(self.box)

                self.ui_select:stop()
                self.ui_select:play()
            elseif self.selected_submenu == 2 then
                self.state = "EQUIPMENU"

                self.equip_selected = 1

                self.box = DarkBox(82, 112, 477, 277)
                self.box.layer = -1
                self:addChild(self.box)

                local char = Sprite("ui/menu/caption_char", 68 - 32, 6 - 32)
                char:setScale(2)
                self.box:addChild(char)

                local equipped = Sprite("ui/menu/caption_equipped", 68 - 32 + 258, 6 - 32)
                equipped:setScale(2)
                self.box:addChild(equipped)

                local stats = Sprite("ui/menu/caption_stats", 68 - 32 - 2, 6 - 32 + 130)
                stats:setScale(2)
                self.box:addChild(stats)

                local weapons = Sprite("ui/menu/caption_weapons", 68 - 32 - 2 + 256, 6 - 32 + 130)
                weapons:setScale(2)
                self.box:addChild(weapons)

                self.ui_select:stop()
                self.ui_select:play()
            elseif self.selected_submenu == 3 then
                self.state = "POWERMENU"

                -- The power menu does not reset the selected character, for some reason.
                self.box = DarkBox(82, 112, 477, 277)
                self.box.layer = -1
                self:addChild(self.box)

                self.ui_select:stop()
                self.ui_select:play()
            elseif self.selected_submenu == 4 then
                self.state = "CONFIGMENU"

                self.box = DarkBox(82, 112, 477, 277)
                self.box.layer = -1
                self:addChild(self.box)

                self.ui_select:stop()
                self.ui_select:play()
            end
        end
    elseif self.state == "ITEMMENU" then
        if Input.isCancel(key) then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            self.box:remove()
            self.box = nil
            self.state = "MAIN"
            return
        end
        if Input.is("left", key) then
            self.item_header_selected = self.item_header_selected - 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.is("right", key) then
            self.item_header_selected = self.item_header_selected + 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if self.item_header_selected < 1 then self.item_header_selected = 3 end
        if self.item_header_selected > 3 then self.item_header_selected = 1 end
        if Input.isConfirm(key) and (#Game.inventory > 0) then
            self.ui_select:stop()
            self.ui_select:play()
            self.item_selected_x = 1
            self.item_selected_y = 1
            self.selected_item = 1
            self.state = "ITEMSELECT"
        end
    elseif self.state == "ITEMSELECT" then
        if Input.isCancel(key) then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            self.state = "ITEMMENU"
            return
        end
        local old_x, old_y = self.item_selected_x, self.item_selected_y
        if Input.is("left", key) or Input.is("right", key) then
            if self.item_selected_x == 1 then
                self.item_selected_x = 2
            else
                self.item_selected_x = 1
            end
        end
        if Input.is("up", key) then
            self.item_selected_y = self.item_selected_y - 1
        end
        if Input.is("down", key) then
            self.item_selected_y = self.item_selected_y + 1
        end
        if self.item_selected_y < 1 then self.item_selected_y = 1 end
        if (2 * (self.item_selected_y - 1) + self.item_selected_x) > #Game.inventory then
            if (#Game.inventory % 2) ~= 0 then
                self.item_selected_x = ((#Game.inventory - 1) % 2) + 1
            end
            self.item_selected_y = math.floor((#Game.inventory - 1) / 2) + 1
        end
        self.selected_item = (2 * (self.item_selected_y - 1) + self.item_selected_x)
        if self.item_selected_y ~= old_y or self.item_selected_x ~= old_x then
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.isConfirm(key) then
            self.selected_item = (2 * (self.item_selected_y - 1) + self.item_selected_x)
            local item = Game.inventory[self.selected_item]
            if item.usable_in == "world" or item.usable_in == "all" then
                self.state = "PARTYSELECT"
                Game.world.healthbar.action_boxes[self.selected_party].selected = true
                Game.world.healthbar.action_boxes[self.selected_party]:setHeadIcon("heart")
                self.ui_select:stop()
                self.ui_select:play()
            else
                self.ui_cant_select:stop()
                self.ui_cant_select:play()
            end
        end
    elseif self.state == "PARTYSELECT" then
        if Input.isCancel(key) then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            self.state = "ITEMSELECT"
            for _, actionbox in ipairs(Game.world.healthbar.action_boxes) do
                actionbox.selected = false
                actionbox:setHeadIcon("head")
            end
            return
        end
        local old_selected = self.selected_party
        if Input.is("left", key) then
            self.selected_party = self.selected_party - 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.is("right", key) then
            self.selected_party = self.selected_party + 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if self.selected_party < 1 then self.selected_party = #Game.party end
        if self.selected_party > #Game.party then self.selected_party = 1 end
        if old_selected ~= self.selected_party then
            for _, actionbox in ipairs(Game.world.healthbar.action_boxes) do
                actionbox.selected = false
                actionbox:setHeadIcon("head")
            end
        end
        Game.world.healthbar.action_boxes[self.selected_party].selected = true
        Game.world.healthbar.action_boxes[self.selected_party]:setHeadIcon("heart")
        if Input.isConfirm(key) then
            self.state = "ITEMSELECT"
            Game.world.healthbar.action_boxes[self.selected_party].selected = false
            Game.world.healthbar.action_boxes[self.selected_party]:setHeadIcon("head")
            local dropping = (self.item_header_selected == 2)

            if dropping then
                self.ui_cancel_small:stop()
                self.ui_cancel_small:play()
            end

            local result
            if not dropping then
                result = Game.inventory[self.selected_item]:onWorldUse(Game.party[self.selected_party])
            end

            if result == nil or result then
                local item = Game.inventory[self.selected_item]
                if item.result_item and (not dropping) then
                    Game.inventory[self.selected_item] = Registry.getItem(item.result_item)
                else
                    table.remove(Game.inventory, self.selected_item)
                end
                if (self.selected_item == (#Game.inventory + 1)) then
                    if self.item_selected_x == 2 then
                        self.item_selected_x = 1
                    else
                        self.item_selected_x = 2
                        self.item_selected_y = self.item_selected_y - 1
                        if self.item_selected_y < 1 then
                            self.state = "ITEMMENU"
                        end
                    end
                    self.selected_item = (2 * (self.item_selected_y - 1) + self.item_selected_x)
                end
            end
        end
    elseif self.state == "EQUIPMENU" then
        if Input.isCancel(key) then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            self.box:remove()
            self.box = nil
            self.state = "MAIN"
        end
        if Input.is("left", key) then
            self.equip_selected = self.equip_selected - 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.is("right", key) then
            self.equip_selected = self.equip_selected + 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if self.equip_selected < 1 then self.equip_selected = #Game.party end
        if self.equip_selected > #Game.party then self.equip_selected = 1 end
    elseif self.state == "POWERMENU" then
        if Input.isCancel(key) then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            self.box:remove()
            self.box = nil
            self.state = "MAIN"
            return
        end
        if Input.is("left", key) then
            self.power_selected = self.power_selected - 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.is("right", key) then
            self.power_selected = self.power_selected + 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if self.power_selected < 1 then self.power_selected = #Game.party end
        if self.power_selected > #Game.party then self.power_selected = 1 end
    elseif self.state == "CONFIGMENU" then
        if Input.isCancel(key) then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            self.box:remove()
            self.box = nil
            self.state = "MAIN"
        end
    end
end

function DarkMenu:update(dt)
    self.animation_timer = self.animation_timer + (dt * 30)

    local max_time = self.animate_out and 3 or 8

    if self.animation_timer > max_time + 1 then
        self.animation_done = true
        self.animation_timer = max_time + 1
        if self.animate_out then
            Game.world.menu = nil
            self:remove()
            return
        end
    end

    local offset
    if not self.animate_out then
        self.y = Ease.outCubic(math.min(max_time, self.animation_timer), -80, 80, max_time)
    else
        self.y = Ease.outCubic(math.min(max_time, self.animation_timer), 0, -80, max_time)
    end

    super:update(self, dt)
end

function DarkMenu:draw()
    super:draw(self)

    -- Draw the black background
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, 640, 80)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.desc_sprites[self.selected_submenu], 20, 24, 0, 2, 2)

    self:drawButton(1, 120, 20)
    self:drawButton(2, 220, 20)
    self:drawButton(3, 320, 20)
    self:drawButton(4, 420, 20)

    love.graphics.setFont(self.font)
    love.graphics.print("D$ " .. Game.gold, 520, 20)

    self:drawStates()
end

function DarkMenu:drawStates()
    if self.state == "ITEMSELECT" or self.state == "PARTYSELECT" then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 80)
        love.graphics.setColor(1, 1, 1, 1)
        if self.state == "PARTYSELECT" and self.item_header_selected == 2 then
            love.graphics.print("Really throw away the\n" .. Game.inventory[self.selected_item].name .. "?", 20, 10)
        elseif self.state == "ITEMSELECT" or self.state == "PARTYSELECT" then
            love.graphics.print(Game.inventory[self.selected_item].description, 20, 10)
        end
    end
    if self.state == "ITEMMENU" or self.state == "ITEMSELECT" or self.state == "PARTYSELECT" then

        if self.state == "ITEMSELECT" or self.state == "PARTYSELECT" then
            if self.item_header_selected == 1 then love.graphics.setColor(255/255, 160/255, 64/255) else love.graphics.setColor(128/255, 128/255, 128/255) end
            love.graphics.print("USE",  180, 110)
            if self.item_header_selected == 2 then love.graphics.setColor(255/255, 160/255, 64/255) else love.graphics.setColor(128/255, 128/255, 128/255) end
            love.graphics.print("TOSS", 300, 110)
            if self.item_header_selected == 3 then love.graphics.setColor(255/255, 160/255, 64/255) else love.graphics.setColor(128/255, 128/255, 128/255) end
            love.graphics.print("KEY",  420, 110)
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("USE",  180, 110)
            love.graphics.print("TOSS", 300, 110)
            love.graphics.print("KEY",  420, 110)
        end

        local heart_x = 20
        local heart_y = 20

        if self.state == "ITEMMENU" then
            local heart_x_choices = {155, 275, 395}
            heart_x = heart_x_choices[self.item_header_selected]
            heart_y = 120
        elseif self.state == "ITEMSELECT" then
            heart_x = 120 + (self.item_selected_x - 1) * 210
            heart_y = 162 + (self.item_selected_y - 1) * 30
        end
        if self.state ~= "PARTYSELECT" then
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.draw(self.heart_sprite, heart_x, heart_y)
        end

        local item_x = 0
        local item_y = 0
        local inventory = Game.inventory

        for index, item in ipairs(inventory) do
            -- Draw the item shadow
            love.graphics.setColor(51/255, 32/255, 51/255, 1)
            love.graphics.print(item.name, 146 + (item_x * 210) + 2, 152 + (item_y * 30) + 2)

            if self.state == "ITEMMENU" then
                love.graphics.setColor(128/255, 128/255, 128/255, 1)
            else
                if item.usable_in == "world" or item.usable_in == "all" then
                    love.graphics.setColor(1, 1, 1, 1)
                else
                    love.graphics.setColor(192/255, 192/255, 192/255, 1)
                end
            end
            love.graphics.print(item.name, 146 + (item_x * 210), 152 + (item_y * 30))
            item_x = item_x + 1
            if item_x >= 2 then
                item_x = 0
                item_y = item_y + 1
            end
        end

    elseif self.state == "EQUIPMENU" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 270, 88,  6,   139)
        love.graphics.rectangle("fill", 58,  221, 58,  6)
        love.graphics.rectangle("fill", 212, 221, 160, 6)
        love.graphics.rectangle("fill", 504, 221, 81,  6)
        love.graphics.rectangle("fill", 323, 221, 6,   192)
    end
end

function DarkMenu:drawButton(index, x, y)
    local sprite = 1
    if index == self.selected_submenu then
        sprite = 2
        if self.state ~= "MAIN" then
            sprite = 3
        end
    end
    love.graphics.draw(self.buttons[index][sprite], x, y, 0, 2, 2)
end

return DarkMenu