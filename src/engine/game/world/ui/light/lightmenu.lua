---@class LightMenu : Object
---@overload fun(...) : LightMenu
local LightMenu, super = Class(Object)

function LightMenu:init()
    super.init(self, 0, 0)

    self.layer = 1 -- TODO

    self.parallax_x = 0
    self.parallax_y = 0

    self.animation_done = false
    self.animation_timer = 0
    self.animate_out = false

    self.selected_submenu = 1

    self.current_selecting = Game.world.current_selecting or 1

    self.item_selected = 1

    -- States: MAIN, ITEMMENU, ITEMUSAGE
    self.state = "MAIN"
    self.state_reason = nil
    self.heart_sprite = Assets.getTexture("player/heart_menu")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.font       = Assets.getFont("main")
    self.font_small = Assets.getFont("small")

    self.box = nil

    self.top = true

    self.info_box = UIBox(56, 76, 94, 62)
    self:addChild(self.info_box)
    self:realign()

    self.choice_box = UIBox(56, 192, 94, 100)
    self:addChild(self.choice_box)

    self.storage = "items"
end

function LightMenu:onAddToStage(stage)
    self.ui_move:stop()
    self.ui_move:play()
end

function LightMenu:close()
    Game.world.current_selecting = self.current_selecting
    Game.world.menu = nil
    self:remove()
end

function LightMenu:closeBox()
    self.state = "MAIN"
    if self.box then
        self.box:remove()
        self.box = nil
    end
end

function LightMenu:onKeyPressed(key)
    if (Input.isMenu(key) or Input.isCancel(key)) and self.state == "MAIN" then
        Game.world:closeMenu()
        return
    end

    if self.state == "MAIN" then
        local old_selected = self.current_selecting
        if Input.is("up", key)    then self.current_selecting = self.current_selecting - 1 end
        if Input.is("down", key) then self.current_selecting = self.current_selecting + 1 end
        local max_selecting = Game:getFlag("has_cell_phone", false) and 3 or 2
        self.current_selecting = Utils.clamp(self.current_selecting, 1, max_selecting)
        if old_selected ~= self.current_selecting then
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.isConfirm(key) then
            self:onButtonSelect(self.current_selecting)
        end
    end
end

function LightMenu:onButtonSelect(button)
    if button == 1 then
        if Game.inventory:getItemCount(self.storage, false) > 0 then
            self.state = "ITEMMENU"
            Input.clear("confirm")
            self.box = LightItemMenu()
            self.box.layer = 1
            self:addChild(self.box)

            self.ui_select:stop()
            self.ui_select:play()
        end
    elseif button == 2 then
        self.state = "STATMENU"
        Input.clear("confirm")
        self.box = LightStatMenu()
        self.box.layer = 1
        self:addChild(self.box)

        self.ui_select:stop()
        self.ui_select:play()
    elseif button == 3 then
        if #Game.world.calls > 0 then
            Input.clear("confirm")
            self.state = "CELLMENU"
            self.box = LightCellMenu()
            self.box.layer = 1
            self:addChild(self.box)

            self.ui_select:stop()
            self.ui_select:play()
        end
    end
end

function LightMenu:update()
    super.update(self)
    self:realign()
end

function LightMenu:realign()
    local _, player_y = Game.world.player:localToScreenPos()
    self.top = player_y > 260

    local offset = 0
    if self.top then
        offset = 270
    end
    self.info_box.y = 76 + offset
end

function LightMenu:draw()
    super.draw(self)

    local offset = 0
    if self.top then
        offset = 270
    end

    local chara = Game.party[1]

    love.graphics.setFont(self.font)
    Draw.setColor(PALETTE["world_text"])
    love.graphics.print(chara:getName(), 46, 60 + offset)

    love.graphics.setFont(self.font_small)
    love.graphics.print("LV  "..chara:getLightLV(), 46, 100 + offset)
    love.graphics.print("HP  "..chara:getHealth().."/"..chara:getStat("health"), 46, 118 + offset)
    love.graphics.print(Utils.padString(Game:getConfig("lightCurrencyShort"), 4)..Game.lw_money, 46, 136 + offset)

    love.graphics.setFont(self.font)
    if Game.inventory:getItemCount(self.storage, false) <= 0 then
        Draw.setColor(PALETTE["world_gray"])
    else
        Draw.setColor(PALETTE["world_text"])
    end
    love.graphics.print("ITEM", 84, 188 + (36 * 0))
    Draw.setColor(PALETTE["world_text"])
    love.graphics.print("STAT", 84, 188 + (36 * 1))
    if Game:getFlag("has_cell_phone", false) then
        if #Game.world.calls > 0 then
            Draw.setColor(PALETTE["world_text"])
        else
            Draw.setColor(PALETTE["world_gray"])
        end
        love.graphics.print("CELL", 84, 188 + (36 * 2))
    end

    if self.state == "MAIN" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 56, 160 + (36 * self.current_selecting), 0, 2, 2)
    end
end

return LightMenu