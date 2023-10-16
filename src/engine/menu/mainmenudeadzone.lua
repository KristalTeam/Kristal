---@class (exact) MainMenuDeadzone : StateClass
---
---@field menu MainMenu
---
---@field state string
---@field state_manager StateManager
---
---@field selected_option number
---
---@overload fun(menu:MainMenu) : MainMenuDeadzone
local MainMenuDeadzone, super = Class(StateClass)

function MainMenuDeadzone:init(menu)
    self.menu = menu

    self.state_manager = StateManager("SELECT", self, true)
    self.state_manager:addState("SELECT", {keypressed = self.onKeyPressedSelect})
    self.state_manager:addState("SLIDER", {keypressed = self.onKeyPressedSlider})

    self.selected_option = 1
end

function MainMenuDeadzone:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuDeadzone:onEnter(old_state)
    self.state_manager:setState("SELECT")

    self.selected_option = 1

    self.menu.heart_target_x = 152 - 18
    self.menu.heart_target_y = 296 + 16
end

function MainMenuDeadzone:onKeyPressed(key, is_repeat)
    self.state_manager:call("keypressed", key, is_repeat)
end

function MainMenuDeadzone:update()
    self.state_manager:update()
end

function MainMenuDeadzone:draw()
    Draw.setColor(COLORS.silver)
    Draw.printShadow("( OPTIONS )", 0, 0, 2, "center", 640)

    Draw.setColor(1, 1, 1)
    Draw.printShadow("DEADZONE CONFIG", 0, 48, 2, "center", 640)

    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(2)

    local function drawStick(type, x, y, radius)
        local stick_x, stick_y, deadzone

        if type == "left" then
            stick_x, stick_y = Input.gamepad_left_x, Input.gamepad_left_y
            deadzone = Kristal.Config["leftStickDeadzone"]
        elseif type == "right" then
            stick_x, stick_y = Input.gamepad_right_x, Input.gamepad_right_y
            deadzone = Kristal.Config["rightStickDeadzone"]
        end

        Draw.setColor(0, 0, 0)
        love.graphics.circle("fill", x + 2, y + 4, radius + 1)
        Draw.setColor(0.33, 0.33, 0.33)
        love.graphics.circle("fill", x, y, radius)
        Draw.setColor(0.16, 0.16, 0.16)
        love.graphics.circle("fill", x, y, radius * deadzone)
        Draw.setColor(1, 1, 1)
        love.graphics.circle("line", x, y, radius)

        local magnitude = math.sqrt(stick_x * stick_x + stick_y * stick_y)
        if magnitude > 1 then
            stick_x = stick_x / magnitude
            stick_y = stick_y / magnitude
            magnitude = 1
        end
        if magnitude <= deadzone then
            Draw.setColor(1, 0, 0)
        else
            Draw.setColor(0, 1, 0)
        end

        local cx, cy = x + (stick_x * (radius - 8)), y + (stick_y * (radius - 8))
        love.graphics.circle("line", cx, cy, 8)
        love.graphics.circle("fill", cx, cy, 2)
    end

    drawStick("left", 200, 200, 80)
    drawStick("right", 440, 200, 80)

    local function drawSlider(index, type, x, y)
        if self.selected_option == index and self.state == "SLIDER" then
            Draw.setColor(0, 1, 1)
        else
            Draw.setColor(1, 1, 1)
        end

        Draw.printShadow("<", x, y)
        Draw.printShadow(">", x + 80, y)

        local deadzone = Kristal.Config[type .. "StickDeadzone"]
        deadzone = math.floor(deadzone * 100)

        Draw.printShadow(deadzone .. "%", x + 16, y, 2, "center", 64)
    end

    drawSlider(1, "left", 152, 296)
    drawSlider(2, "right", 392, 296)

    Draw.setColor(1, 1, 1)

    Draw.printShadow("Back", 286, 364)

    self.state_manager:draw()
end

-------------------------------------------------------------------------------
-- Substate Callbacks
-------------------------------------------------------------------------------

function MainMenuDeadzone:onKeyPressedSelect(key, is_repeat)
    if Input.isCancel(key) then
        Assets.stopAndPlaySound("ui_select")
        self.menu:popState()
    end
    local last_selected = self.selected_option
    if not Input.isThumbstick(key) then
        if Input.is("down", key) then
            self.selected_option = 3
        elseif Input.is("up", key) then
            self.selected_option = 1
        end
        if Input.is("right", key) and self.selected_option == 1 then
            self.selected_option = 2
        elseif Input.is("left", key) and self.selected_option == 2 then
            self.selected_option = 1
        end
    end
    if last_selected ~= self.selected_option then
        Assets.stopAndPlaySound("ui_move")
    end
    if self.selected_option == 1 then
        self.menu.heart_target_x = 152 - 18
        self.menu.heart_target_y = 296 + 16
    elseif self.selected_option == 2 then
        self.menu.heart_target_x = 392 - 18
        self.menu.heart_target_y = 296 + 16
    elseif self.selected_option == 3 then
        self.menu.heart_target_x = 270
        self.menu.heart_target_y = 382
    end
    if Input.isConfirm(key) then
        Assets.stopAndPlaySound("ui_select")

        if self.selected_option == 3 then
            self.menu:popState()
        else
            self.state_manager:setState("SLIDER")
        end
    end
end

function MainMenuDeadzone:onKeyPressedSlider(key, is_repeat)
    if not is_repeat and (Input.isCancel(key) or Input.isConfirm(key)) then
        Assets.stopAndPlaySound("ui_select")
        Kristal.saveConfig()
        self.state_manager:setState("SELECT")
    end
    local config_name = (self.selected_option == 1 and "left" or "right") .. "StickDeadzone"
    local deadzone = Kristal.Config[config_name]
    if not Input.isThumbstick(key) then
        if Input.is("left", key) then
            deadzone = math.max(0, deadzone - 0.01)
            Assets.stopAndPlaySound("ui_move")
        elseif Input.is("right", key) then
            deadzone = math.min(1, deadzone + 0.01)
            Assets.stopAndPlaySound("ui_move")
        end
    end
    Kristal.Config[config_name] = deadzone
end

return MainMenuDeadzone