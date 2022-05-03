local DebugSystem, super = Class(Object)

function DebugSystem:init()
    super:init(self, 0, 0)
    self.layer = 10000000 - 1

    self.font_size = 32
    self.font_name = "main"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.heart = Sprite("player/heart_menu")
    self.heart.visible = true
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setScale(2, 2)
    self.heart:setColor(1, 0, 0)
    self.heart.layer = 100
    self:addChild(self.heart)

    self.heart_target_x = -8
    self.heart_target_y = -8

    -- States: IDLE, MENU
    self.state = "IDLE"
    self.state_reason = nil

    self.menu_options = {
        {"Show FPS", "Toggle the FPS display.", function() Kristal.Config["showFPS"] = not Kristal.Config["showFPS"] end},
        {"Explode The Player", "You know what this does", function() if Game.world and Game.world.player then Game.world.player:explode() end end}
    }

    self.current_selecting = 1
end

function DebugSystem:openMenu()
    Game.lock_input = true
    Assets.playSound("ui_select")
    self:setState("MENU")
end

function DebugSystem:closeMenu()
    Assets.playSound("ui_move")
    Game.lock_input = false
    self:setState("IDLE")
end

function DebugSystem:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

function DebugSystem:onStateChange(old, new)
    self.heart_target_x = -8
    self.heart_target_y = -8
    if new == "MENU" then
        self.heart_target_x = 19
        self.heart_target_y = 35
    end
end

function DebugSystem:keypressed(key)
    if self.state == "MENU" then
        if Input.isCancel(key) then
            self:closeMenu()
            return
        end
        if Input.isConfirm(key) then
            Assets.playSound("ui_select")
            self.menu_options[self.current_selecting][3]()
        end
        if Input.is("down", key) then
            Assets.playSound("ui_move")
            self.current_selecting = self.current_selecting + 1
        end
        if Input.is("up", key) then
            Assets.playSound("ui_move")
            self.current_selecting = self.current_selecting - 1
        end
        if self.current_selecting <= 0 then self.current_selecting = #self.menu_options end
        if self.current_selecting > #self.menu_options then self.current_selecting = 1 end

        self.heart_target_x = 19
        self.heart_target_y = (self.current_selecting - 1) * 32 + 35

    end
end

function DebugSystem:isMenuOpen()
    return self.state == "MENU"
end

function DebugSystem:update()
    if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
        self.heart.x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart.y)) <= 2)then
        self.heart.y = self.heart_target_y
    end
    self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
    self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT
end

function DebugSystem:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)

    local menu_x = 19
    if self.state == "MENU" then
        for i, v in ipairs(self.menu_options) do
            local text = v[1]
            local desc = v[2]
            local func = v[3]
            self:printShadow(text, menu_x + 19, (i - 1) * 32 + 16)
            if self.current_selecting == i then
                if desc then
                    self:printShadow(" - " .. desc, menu_x + 19 + self.font:getWidth(text), (i - 1) * 32 + 16, COLORS.gray)
                end
            end
        end
    end

    super:draw(self)
end

function DebugSystem:printShadow(text, x, y, color, align, limit)
    -- Draw the shadow, offset by two pixels to the bottom right
    love.graphics.setFont(self.font)
    love.graphics.setColor({0, 0, 0, 1})
    love.graphics.printf(text, x + 2, y + 2, limit or self.font:getWidth(text), align or "left")

    -- Draw the main text
    love.graphics.setColor(color or {1, 1, 1, 1})
    love.graphics.printf(text, x, y, limit or self.font:getWidth(text), align or "left")
end


return DebugSystem