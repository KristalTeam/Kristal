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
    self.state_manager:addState("MAIN", { update = self.updateMainState })
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
    self.noise_timer = 0

    self.options = {}
    self:registerDefaults()
    Kristal.callEvent(KRISTAL_EVENT.getConfigOptions, self, self.options)

    self:sortConfigOptions()

    self:addExitOptions()

    self.config_text = self:addChild(Text("CONFIG", 188, -12))
    self.config_text:setColor(PALETTE["world_text"])
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
    option:setAdded(false)
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

    ---@cast option DarkConfigOption
    option:setPosition(0, 38 + ((index - 1) * 35))
    self:addChild(option)
    option:setAdded(true)

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
    option:setAdded(true)

    table.insert(self.options, option)

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
    for i = #self.options, 1, -1 do
        self.options[i].visible = true
    end

    self.config_text.visible = true
end

function DarkConfigMenu:hideOptions()
    for i = #self.options, 1, -1 do
        self.options[i].visible = false
    end

    self.config_text.visible = false
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

    self:updateCurrentlySelected()
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
