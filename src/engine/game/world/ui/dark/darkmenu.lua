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
    self.party_select_mode = "SINGLE" -- SINGLE, ALL
    self.after_party_select = nil

    self.selected_item = 1

    -- States: MAIN, ITEMMENU, ITEMSELECT, KEYSELECT, PARTYSELECT,
    -- EQUIPMENU, WEAPONSELECT, REPLACEMENTSELECT, POWERMENU, SPELLSELECT,
    -- CONFIGMENU, VOLUMESELECT, CONTROLSMENU, CONTROLSELECT
    self.state = "MAIN"
    self.state_reason = nil
    self.heart_sprite = Assets.getTexture("player/heart_menu_small")

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
        {Assets.getTexture("ui/menu/btn/item"  ), Assets.getTexture("ui/menu/btn/item_h"  )},
        {Assets.getTexture("ui/menu/btn/equip" ), Assets.getTexture("ui/menu/btn/equip_h" )},
        {Assets.getTexture("ui/menu/btn/power" ), Assets.getTexture("ui/menu/btn/power_h" )},
        {Assets.getTexture("ui/menu/btn/config"), Assets.getTexture("ui/menu/btn/config_h")}
    }

    self.button_offset = 100

    self.description_box = Rectangle(0, 0, SCREEN_WIDTH, 80)
    self.description_box:setColor(0, 0, 0)
    self.description_box.visible = false
    self.description_box.layer = 10
    self:addChild(self.description_box)

    self.description = Text("", 20, 10, SCREEN_WIDTH - 20, SCREEN_HEIGHT - 10)
    self.description_box:addChild(self.description)

    self.box = nil
end

function DarkMenu:onAdd(parent)
    super:onAdd(parent)
    Game.world:showHealthBars()
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

function DarkMenu:closeBox()
    self.state = "MAIN"
    if self.box then
        self.box:remove()
        self.box = nil
    end
end

function DarkMenu:setDescription(text, visible)
    self.description:setText(text)
    if visible ~= nil then
        self.description_box.visible = visible
    end
end

function DarkMenu:partySelect(mode, after)
    self.state_reason = self.state
    self.state = "PARTYSELECT"

    self.party_select_mode = mode or "SINGLE"
    self.after_party_select = after

    self:updateSelectedBoxes()
end

function DarkMenu:keypressed(key)
    if (Input.isMenu(key) or Input.isCancel(key)) and self.state == "MAIN" then
        Game.world:closeMenu()
        return
    end

    if not self.animation_done then return end

    if self.state == "MAIN" then
        local old_selected = self.selected_submenu
        if Input.is("left", key)  then self.selected_submenu = self.selected_submenu - 1 end
        if Input.is("right", key) then self.selected_submenu = self.selected_submenu + 1 end
        if self.selected_submenu < 1             then self.selected_submenu = #self.buttons end
        if self.selected_submenu > #self.buttons then self.selected_submenu = 1             end
        if old_selected ~= self.selected_submenu then
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.isConfirm(key) then
            self:onButtonSelect(self.selected_submenu)
        end
    elseif self.state == "PARTYSELECT" then
        if Input.isCancel(key) then
            Input.consumePress("cancel")
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            self.state = self.state_reason
            if self.after_party_select then
                self.after_party_select(false)
            end

            self:updateSelectedBoxes()
            return
        end
        local old_selected = self.selected_party
        if self.party_select_mode == "SINGLE" then
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
        end
        if self.selected_party < 1 then self.selected_party = #Game.party end
        if self.selected_party > #Game.party then self.selected_party = 1 end
        if old_selected ~= self.selected_party then
            self:updateSelectedBoxes()
        end
        if Input.isConfirm(key) then
            Input.consumePress("confirm")
            self.state = self.state_reason
            self.state_reason = nil
            if self.after_party_select then
                if self.party_select_mode == "SINGLE" then
                    self.after_party_select(true, Game.party[self.selected_party])
                else
                    self.after_party_select(true, Game.party)
                end
            end
            self:updateSelectedBoxes()
        end
    end
end

function DarkMenu:onButtonSelect(button)
    if button == 1 then
        self.state = "ITEMMENU"

        Input.consumePress("confirm")
        self.box = DarkItemMenu()
        self.box.layer = 1
        self:addChild(self.box)

        self.ui_select:stop()
        self.ui_select:play()
    elseif button == 2 then
        self.state = "EQUIPMENU"

        Input.consumePress("confirm")
        self.box = DarkEquipMenu()
        self.box.layer = 1
        self:addChild(self.box)

        self.ui_select:stop()
        self.ui_select:play()
    elseif button == 3 then
        self.state = "POWERMENU"

        -- The power menu does not reset the selected character, for some reason.
        -- But we're not doing that (for now at least)
        Input.consumePress("confirm")
        self.box = DarkPowerMenu()
        self.box.layer = 1
        self:addChild(self.box)

        self.ui_select:stop()
        self.ui_select:play()
    elseif button == 4 then
        self.state = "CONFIGMENU"

        Input.consumePress("confirm")
        self.box = DarkConfigMenu()
        self.box.layer = -1
        self:addChild(self.box)

        self.ui_select:stop()
        self.ui_select:play()
    end
end

function DarkMenu:updateSelectedBoxes()
    for _, actionbox in ipairs(Game.world.healthbar.action_boxes) do
        if self.state == "PARTYSELECT" and self.party_select_mode == "ALL" then
            actionbox.selected = true
            actionbox:setHeadIcon("heart")
        else
            actionbox.selected = false
            actionbox:setHeadIcon("head")
        end
    end
    if self.state == "PARTYSELECT" then
        Game.world.healthbar.action_boxes[self.selected_party].selected = true
        Game.world.healthbar.action_boxes[self.selected_party]:setHeadIcon("heart")
    end
end

function DarkMenu:update()
    self.animation_timer = self.animation_timer + DTMULT

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

    super:update(self)
end

function DarkMenu:draw()
    -- Draw the black background
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, 640, 80)

    love.graphics.setColor(1, 1, 1, 1)
    if self.desc_sprites[self.selected_submenu] then
        love.graphics.draw(self.desc_sprites[self.selected_submenu], 20, 24, 0, 2, 2)
    end

    for i = 1, #self.buttons do
        self:drawButton(i, 20 + (i * self.button_offset), 20)
    end

    love.graphics.setFont(self.font)
    love.graphics.print("D$ " .. Game.money, 520, 20)

    super:draw(self)
end

function DarkMenu:drawButton(index, x, y)
    local sprite = 1
    if index == self.selected_submenu then
        sprite = 2
    end
    love.graphics.draw(self.buttons[index][sprite], x, y, 0, 2, 2)
    if index == self.selected_submenu and self.state == "MAIN" then
        love.graphics.setColor(Game:getSoulColor())
        love.graphics.draw(self.heart_sprite, x + 15, y + 25, 0, 2, 2, self.heart_sprite:getWidth() / 2, self.heart_sprite:getHeight() / 2)
        love.graphics.setColor(1, 1, 1)
    end
end

return DarkMenu