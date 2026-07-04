--- The config menu, for changing in-game settings.
---
---@class DarkConfigMenu : Object
---@overload fun(...) : DarkConfigMenu
local DarkConfigMenu, super = Class(Object)

function DarkConfigMenu:init()
    super.init(self, 82, 112, 477, 277)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.layer = WORLD_LAYERS["ui"]
    self:setParallax(0, 0)

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")

    self.bg = UIBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self.bg.debug_select = false
    self:addChild(self.bg)

    -- MAIN, VOLUME, CONTROLS, BORDERS
    self.state = "MAIN"

    self.currently_selected = 0
    self.noise_timer = 0

    self.reset_flash_timer = 0
    self.rebinding = false

    self.options = {}
    self:registerDefaults()
    Kristal.callEvent(KRISTAL_EVENT.getConfigOptions, self, self.options)

    self:sortConfigOptions()

    self:addBackOption()
end

--- Adds the default back button.
function DarkConfigMenu:addBackOption()
    self:addOption(DarkConfigOption(self, "Back", function()
        if Game.chapter ~= 1 then -- TODO
            Assets.stopAndPlaySound("ui_cancel_small")
        end
        Game.world.menu:closeBox()
    end))
end

--- Clears all options from the menu.
function DarkConfigMenu:clearOptions()
    for i = #self.options, 1, -1 do
        self.options[i]:remove()
    end

    self.options = {}
end

--- Sorts the config options and updates their positions.
function DarkConfigMenu:sortConfigOptions()
    for i, option in ipairs(self.options) do
        option:setPosition(0, 38 + ((i - 1) * 35))
    end

    self.currently_selected = MathUtils.clamp(self.currently_selected, 1, #self.options)
    self:updateCurrentlySelected()
end

--- Updates the currently selected option's hover state.
function DarkConfigMenu:updateCurrentlySelected()
    for i, option in ipairs(self.options) do
        option:setHovered(i == self.currently_selected)
    end
end

--- Removes an option from the menu.
---@param index integer
---@return DarkConfigOption option
function DarkConfigMenu:removeOption(index)
    if index < 1 or index > #self.options then
        error("DarkConfigMenu:removeOption() - Index out of bounds")
    end

    local option = self.options[index]

    option:remove()
    table.remove(self.options, index)

    self:sortConfigOptions()

    return option
end

--- Removes an option from the menu.
---@generic T : DarkConfigOption
---@param child T
---@return T? option
function DarkConfigMenu:removeOptionByChild(child)
    for i, option in ipairs(self.options) do
        if option == child then
            self:removeOption(i)
            return child
        end
    end
end

--- Inserts an option into the menu at a specific index.
---@generic T : DarkConfigOption
---@param index integer
---@param option T
---@return T option
function DarkConfigMenu:insertOption(index, option)
    if index < 1 or index > #self.options + 1 then
        error("DarkConfigMenu:insertOption() - Index out of bounds")
    end

    ---@cast option DarkConfigOption
    option:setPosition(0, 38 + ((index - 1) * 35))
    self:addChild(option)

    table.insert(self.options, index, option)

    self:sortConfigOptions()

    return option
end

--- Adds an option to the menu.
---@generic T : DarkConfigOption
---@param option T
---@return T option
function DarkConfigMenu:addOption(option)
    ---@cast option DarkConfigOption
    option:setPosition(0, 38 + (#self.options * 35))
    self:addChild(option)

    table.insert(self.options, option)

    return option
end

function DarkConfigMenu:setState(state)
    local old_state = self.state
    self.state = state
    self:onStateChanged(old_state, state)
end

function DarkConfigMenu:getState()
    return self.state
end

function DarkConfigMenu:onStateChanged(old, new)
    for _, option in ipairs(self.options) do
        option:onStateChanged(old, new)
    end

    if old == "CONTROLS" then
        for i = #self.options, 1, -1 do
            self.options[i].visible = true
        end
    end

    if new == "VOLUME" then
        self.noise_timer = 0
    elseif new == "CONTROLS" then
        for i = #self.options, 1, -1 do
            self.options[i].visible = false
        end

        self.currently_selected = 1
        self:updateCurrentlySelected()
    elseif new == "EXIT" then
        self:clearOptions()
    end
end

--- Registers the default options.
---
--- If "forced fullscreen" is enabled (consoles, phones) then the fullscreen option is not present, and replaced with the border option.
function DarkConfigMenu:registerDefaults()
    self:addOption(DarkConfigVolumeOption(self))

    self:addOption(DarkConfigOption(self, "Controls", function()
        self:setState("CONTROLS")
    end))

    self:addOption(DarkConfigBooleanOption(self, "Simplify VFX", function(option)
        Kristal.Config["simplifyVFX"] = not Kristal.Config["simplifyVFX"]
        option:setEnabled(Kristal.Config["simplifyVFX"])
    end, Kristal.Config["simplifyVFX"]))

    if not Kristal.isForcedFullscreen() then
        self:addOption(DarkConfigBooleanOption(self, "Fullscreen", function(option)
            Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
            love.window.setFullscreen(Kristal.Config["fullscreen"])
            option:setEnabled(Kristal.Config["fullscreen"])
        end, Kristal.Config["fullscreen"]))
    end

    self:addOption(DarkConfigBooleanOption(self, "Auto-Run", function(option)
        Kristal.Config["autoRun"] = not Kristal.Config["autoRun"]
        option:setEnabled(Kristal.Config["autoRun"])
    end, Kristal.Config["autoRun"]))

    if Kristal.isForcedFullscreen() then
        self:addOption(DarkConfigBorderOption(self))
    end

    self:addOption(DarkConfigOption(self, "Return to Title", function()
        self:setState("EXIT")
        Game:returnToMenu()
    end))
end

function DarkConfigMenu:getBindNumberFromIndex(current_index)
    local shown_bind = 1
    local alias = Input.orderedNumberToKey(current_index)
    local keys = Input.getBoundKeys(alias, Input.usingGamepad())
    for index, current_key in ipairs(keys) do
        if Input.usingGamepad() then
            if StringUtils.startsWith(current_key, "gamepad:") then
                shown_bind = index
                break
            end
        else
            if not StringUtils.startsWith(current_key, "gamepad:") then
                shown_bind = index
                break
            end
        end
    end
    return shown_bind
end

function DarkConfigMenu:onKeyPressed(key)
    if self.state == "CONTROLS" then
        if self.rebinding then
            local gamepad = StringUtils.startsWith(key, "gamepad:")

            local worked = key ~= "escape" and
                Input.setBind(Input.orderedNumberToKey(self.currently_selected), 1, key, gamepad)

            self.rebinding = false

            if worked then
                Assets.stopAndPlaySound("ui_select")
            else
                Assets.stopAndPlaySound("ui_cant_select")
            end

            return
        end
        if Input.pressed("confirm") then
            if self.currently_selected < 8 then
                Assets.stopAndPlaySound("ui_select")
                self.rebinding = true
                return
            end

            if self.currently_selected == 8 then
                Assets.playSound("levelup")

                if Kristal.isConsole() then
                    Input.resetBinds(true)  -- Console, no keyboard, only reset gamepad binds
                elseif Input.hasGamepad() then
                    Input.resetBinds()      -- PC, keyboard and gamepad, reset all binds
                else
                    Input.resetBinds(false) -- PC, no gamepad, only reset keyboard binds
                end
                Input.saveBinds()
                self.reset_flash_timer = 10
            end

            if self.currently_selected == 9 then
                self.reset_flash_timer = 0
                self:setState("MAIN")
                self.currently_selected = 2

                Assets.stopAndPlaySound("ui_select")

                Input.clear("confirm", true)
            end
            return
        end

        local old_selected = self.currently_selected
        if Input.pressed("up") then
            self.currently_selected = self.currently_selected - 1
        end
        if Input.pressed("down") then
            self.currently_selected = self.currently_selected + 1
        end

        self.currently_selected = MathUtils.clamp(self.currently_selected, 1, 9)

        if old_selected ~= self.currently_selected then
            Assets.stopAndPlaySound("ui_move")
        end
    end
end

function DarkConfigMenu:update()
    if self.state == "MAIN" then
        if Input.pressed("confirm") then
            Assets.stopAndPlaySound("ui_select")

            local option = self.options[self.currently_selected]
            if option ~= nil then
                option:onSelected()
            end

            return
        end

        if Input.pressed("cancel") then
            Assets.stopAndPlaySound("ui_cancel_small")
            Game.world.menu:closeBox()
            return
        end

        if Input.pressed("up") then
            self.currently_selected = self.currently_selected - 1
            Assets.stopAndPlaySound("ui_move")
        end
        if Input.pressed("down") then
            self.currently_selected = self.currently_selected + 1
            Assets.stopAndPlaySound("ui_move")
        end

        self.currently_selected = MathUtils.clamp(self.currently_selected, 1, #self.options)

        self:updateCurrentlySelected()
    elseif self.state == "VOLUME" then
        if Input.pressed("cancel") or Input.pressed("confirm") then
            Kristal.setVolume(MathUtils.round(Kristal.getVolume() * 100) / 100)

            Assets.stopAndPlaySound("ui_select")

            self:setState("MAIN")
            return
        end

        self.noise_timer = self.noise_timer + DTMULT
        if Input.down("left") then
            Kristal.setVolume(Kristal.getVolume() - ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("noise")
            end
        end
        if Input.down("right") then
            Kristal.setVolume(Kristal.getVolume() + ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("noise")
            end
        end
        if (not Input.down("right")) and (not Input.down("left")) then
            self.noise_timer = 3
        end
    elseif self.state == "BORDERS" then
        if Input.pressed("cancel") or Input.pressed("confirm") then
            self:setState("MAIN")
            return
        end

        local types = Kristal.getBorderTypes()

        local border_index = -1
        for current_index, border in ipairs(types) do
            if border[1] == Kristal.Config["borders"] then
                border_index = current_index
            end
        end
        if border_index == -1 then
            border_index = 1
        end

        local old_index = border_index
        if Input.pressed("left") then
            border_index = math.max(border_index - 1, 1)
        end
        if Input.pressed("right") then
            border_index = math.min(border_index + 1, #types)
        end

        if old_index ~= border_index then
            Kristal.Config["borders"] = types[border_index][1]

            if types[border_index][1] == "off" then
                Kristal.resetWindow()
            elseif types[old_index][1] == "off" then
                Kristal.resetWindow()
            end
        end
    end

    self.reset_flash_timer = math.max(self.reset_flash_timer - DTMULT, 0)

    super.update(self)
end

function DarkConfigMenu:draw()
    if self:getState() == "EXIT" then
        super.draw(self)
        return
    end

    love.graphics.setFont(self.font)
    Draw.setColor(PALETTE["world_text"])

    if self.state ~= "CONTROLS" then
        love.graphics.print("CONFIG", 188, -12)
    else
        -- NOTE: This is forced to true if using a PlayStation in DELTARUNE... Kristal doesn't have a PlayStation port though.
        local dualshock = Input.getControllerType() == "ps4"

        love.graphics.print("Function", 23, -12)
        -- Console accuracy for the Heck of it
        if not Kristal.isConsole() then
            love.graphics.print("Key", 243, -12)
        end
        if Input.hasGamepad() then
            love.graphics.print(Kristal.isConsole() and "Button" or "Gamepad", 353, -12)
        end

        for index, name in ipairs(Input.order) do
            if index > 7 then
                break
            end
            Draw.setColor(PALETTE["world_text"])
            if self.currently_selected == index then
                if self.rebinding then
                    Draw.setColor(PALETTE["world_text_rebind"])
                else
                    Draw.setColor(PALETTE["world_text_hover"])
                end
            end

            if dualshock then
                love.graphics.print(name:gsub("_", " "):upper(), 23, -4 + (29 * index))
            else
                love.graphics.print(name:gsub("_", " "):upper(), 23, -4 + (28 * index) + 4)
            end

            local shown_bind = self:getBindNumberFromIndex(index)

            if not Kristal.isConsole() then
                local alias = Input.getBoundKeys(name, false)[1]
                if type(alias) == "table" then
                    local title_cased = {}
                    for _, word in ipairs(alias) do
                        table.insert(title_cased, StringUtils.titleCase(word))
                    end
                    love.graphics.print(table.concat(title_cased, "+"), 243, 0 + (28 * index))
                elseif alias ~= nil then
                    love.graphics.print(StringUtils.titleCase(alias), 243, 0 + (28 * index))
                end
            end

            Draw.setColor(1, 1, 1)

            if Input.hasGamepad() then
                local alias = Input.getBoundKeys(name, true)[1]
                if alias then
                    local btn_tex = Input.getButtonTexture(alias)
                    if dualshock then
                        Draw.draw(btn_tex, 353 + 42, -2 + (29 * index), 0, 2, 2, btn_tex:getWidth() / 2, 0)
                    else
                        Draw.draw(btn_tex, 353 + 42 + 16 - 6, -2 + (28 * index) + 11 - 6 + 1, 0, 2, 2,
                                  btn_tex:getWidth() / 2, 0)
                    end
                end
            end
        end

        Draw.setColor(PALETTE["world_text"])
        if self.currently_selected == 8 then
            Draw.setColor(PALETTE["world_text_hover"])
        end

        if (self.reset_flash_timer > 0) then
            Draw.setColor(ColorUtils.mergeColor(PALETTE["world_text_hover"], PALETTE["world_text_selected"],
                                           ((self.reset_flash_timer / 10) - 0.1)))
        end

        if dualshock then
            love.graphics.print("Reset to default", 23, -4 + (29 * 8))
        else
            love.graphics.print("Reset to default", 23, -4 + (28 * 8) + 4)
        end

        Draw.setColor(PALETTE["world_text"])
        if self.currently_selected == 9 then
            Draw.setColor(PALETTE["world_text_hover"])
        end

        if dualshock then
            love.graphics.print("Finish", 23, -4 + (29 * 9))
        else
            love.graphics.print("Finish", 23, -4 + (28 * 9) + 4)
        end

        Draw.setColor(Game:getSoulColor())

        if dualshock then
            Draw.draw(self.heart_sprite, -2, 34 + ((self.currently_selected - 1) * 29))
        else
            Draw.draw(self.heart_sprite, -2, 34 + ((self.currently_selected - 1) * 28) + 2)
        end
    end

    Draw.setColor(1, 1, 1, 1)

    super.draw(self)
end

return DarkConfigMenu
