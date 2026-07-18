--- The config menu, for changing in-game settings.
---
---@class DarkConfigMenu : Object, StateManagedClass
---@overload fun(...) : DarkConfigMenu
local DarkConfigMenu, super = Class(Object)

function DarkConfigMenu:init()
    super.init(self, 82, 112, 477, 277)

    self.state = "MAIN"

    self.rebind_state = DarkConfigRebindState(self)
    self.volume_state = DarkConfigVolumeState(self)
    self.border_state = DarkConfigBorderState(self)

    self.state_manager = StateManager("MAIN", self, true)
    self.state_manager:addState("MAIN", { update = self.updateMainState, draw = self.drawMainState })
    self.state_manager:addState("REBIND", self.rebind_state)
    self.state_manager:addState("VOLUME", self.volume_state)
    self.state_manager:addState("BORDERS", self.border_state)
    self.state_manager:addState("EXIT", { enter = self.onExitState })

    self.draw_children_below = 0

    self.layer = WORLD_LAYERS["ui"]
    self:setParallax(0, 0)

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")

    self.bg = UIBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self.bg.debug_select = false
    self:addChild(self.bg)

    self.currently_selected = 0
    self.scroll_offset = 0
    self.noise_timer = 0

    self.options = {}
    self:registerDefaults()
    Kristal.callEvent(KRISTAL_EVENT.getConfigOptions, self, self.options)

    self:updateConfigOptions()

    self:addExitOptions()

    Kristal.callEvent(KRISTAL_EVENT.postConfigOptions, self, self.options)

    self.config_text = self:addChild(Text("CONFIG", 188, -12))
    self.config_text:setColor(PALETTE["world_text"])

    self.options_hidden = false
end

function DarkConfigMenu:getMaxScroll()
    return 7
end

function DarkConfigMenu:getOptionHeight()
    return 35
end

--- Adds the default "return to title" and "back" buttons.
function DarkConfigMenu:addExitOptions()
    self:addOption(DarkConfigOption(self, "Return to Title", function()
        self:setState("EXIT")
        Game:returnToMenu()
    end))

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
        self.options[i]:setAdded(false)
    end

    self.options = {}
end

--- Updates the config options.
function DarkConfigMenu:updateConfigOptions()
    self.currently_selected = MathUtils.clamp(self.currently_selected, 1, #self.options)

    if self.currently_selected - self.scroll_offset > self:getMaxScroll() then
        self.scroll_offset = self.currently_selected - self:getMaxScroll()
    end

    if self.currently_selected <= self.scroll_offset then
        self.scroll_offset = self.currently_selected - 1
    end

    for i, option in ipairs(self.options) do
        option:setHovered(i == self.currently_selected)
        local position = i - 1 - self.scroll_offset
        option:setPosition(0, 38 + (position * self:getOptionHeight()))
        if self.options_hidden then
            option.visible = false
        else
            if position < 0 or position >= self:getMaxScroll() then
                option.visible = false
            else
                option.visible = true
            end
        end
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
    option:setAdded(false)
    table.remove(self.options, index)

    self:updateConfigOptions()

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

    error("DarkConfigMenu:removeOptionByChild() - Child not found in options")
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

    self:addChild(option)

    ---@cast option DarkConfigOption
    option:setAdded(true)

    table.insert(self.options, index, option)

    self:updateConfigOptions()

    return option
end

--- Adds an option to the menu.
---@generic T : DarkConfigOption
---@param option T
---@return T option
function DarkConfigMenu:addOption(option)
    ---@cast option DarkConfigOption
    self:addChild(option)
    option:setAdded(true)

    table.insert(self.options, option)

    self:updateConfigOptions()

    return option
end

function DarkConfigMenu:setState(state)
    local old_state = self.state
    self.state_manager:setState(state)
    self:onStateChanged(old_state, state)
end

function DarkConfigMenu:getState()
    return self.state
end

function DarkConfigMenu:showOptions()
    self.options_hidden = false
    self.config_text.visible = true

    self:updateConfigOptions()
end

function DarkConfigMenu:hideOptions()
    self.options_hidden = true
    self.config_text.visible = false

    self:updateConfigOptions()
end

function DarkConfigMenu:onStateChanged(old, new)
    for _, option in ipairs(self.options) do
        option:onStateChanged(old, new)
    end
end

--- Registers the default options.
---
--- If "forced fullscreen" is enabled (consoles, phones) then the fullscreen option is not present, and replaced with the border option.
function DarkConfigMenu:registerDefaults()
    self:addOption(DarkConfigVolumeOption(self))

    self:addOption(DarkConfigOption(self, "Controls", function()
        self:setState("REBIND")
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
end

function DarkConfigMenu:onKeyPressed(key)
    self.state_manager:call("keyPressed", key)
end

function DarkConfigMenu:updateMainState()
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

    self:updateConfigOptions()
end

-- Responsible for drawing the scroll bar in the main state.
function DarkConfigMenu:drawMainState()
    local item_count = #self.options

    if item_count <= self:getMaxScroll() then
        return
    end

    local x = 469
    local y = 38

    local bar_size = 190

    if item_count > self:getMaxScroll() then
        Draw.setColor(1, 1, 1)
        local sine_off = math.sin((Kristal.getTime() * 30) / 12) * 3
        if self.scroll_offset + self:getMaxScroll() < item_count then
            Draw.draw(self.arrow_sprite, x + 0, y + bar_size + 39 + sine_off)
        end
        if self.scroll_offset > 0 then
            Draw.draw(self.arrow_sprite, x + 0, y + 14 - sine_off, 0, 1, -1)
        end
    end

    if item_count <= 12 then
        Draw.setColor(1, 1, 1)
        for i = 1, item_count do
            local percentage = (i - 1) / (item_count - 1)
            if i == self.currently_selected then
                love.graphics.rectangle("fill", x + 1, y + 21 + percentage * bar_size, 10, 10)
            else
                love.graphics.rectangle("fill", x + 4, y + 25 + percentage * bar_size, 4, 4)
            end
        end
    else
        Draw.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", x + 4, y + 24, 6, bar_size + 9)
        local percent = self.scroll_offset / (item_count - self:getMaxScroll())
        Draw.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x + 4, y + 24 + math.floor(percent * bar_size), 6, 6)
    end
end

function DarkConfigMenu:onExitState()
    self:hideOptions()
end

function DarkConfigMenu:update()
    self.state_manager:update()
    super.update(self)
end

function DarkConfigMenu:draw()
    self.state_manager:draw()
    super.draw(self)
end

return DarkConfigMenu
