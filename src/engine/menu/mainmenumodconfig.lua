---@class MainMenuModConfig : StateClass
---
---@field menu MainMenu
---
---@field options table
---@field selected_option number
---
---@field editing boolean
---
---@field scroll_target_y number
---@field scroll_y number
---
---@overload fun(menu:MainMenu) : MainMenuModConfig
local MainMenuModConfig, super = Class(StateClass)

function MainMenuModConfig:init(menu)
    self.menu = menu

    self:registerOptions()
    self.selected_option = 1

    self.editing = false

    self.scroll_target_y = 0
    self.scroll_y = 0
end

function MainMenuModConfig:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuModConfig:onEnter(old_state)
    self.selected_option = 1

    self.scroll_target_y = 0
    self.scroll_y = 0

    self.menu.heart_target_x = 64 - 19
    self.menu.heart_target_y = 128 + 19
end

function MainMenuModConfig:onKeyPressed(key, is_repeat)
    if not self.editing then
        if Input.isCancel(key) then
            self.menu:setState("MODCREATE")
            Assets.stopAndPlaySound("ui_move")
            return
        end
        local old = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1  end
        if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1  end
        if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1  end
        if self.selected_option > (#self.options + 1) then self.selected_option = is_repeat and (#self.options + 1) or 1                   end
        if self.selected_option < 1                   then self.selected_option = is_repeat and 1                   or (#self.options + 1) end

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= #self.options + 1 then
            y_off = y_off + 32
        end

        if y_off + self.scroll_target_y < 0 then
            self.scroll_target_y = self.scroll_target_y + (0 - (y_off + self.scroll_target_y))
        end

        if y_off + self.scroll_target_y > (7 * 32) then
            self.scroll_target_y = self.scroll_target_y + ((7 * 32) - (y_off + self.scroll_target_y))
        end

        self.menu.heart_target_x = 45
        self.menu.heart_target_y = 147 + y_off + self.scroll_target_y

        if old ~= self.selected_option then
            Assets.stopAndPlaySound("ui_move")
        end

        if Input.isConfirm(key) then
            if self.selected_option == (#self.options + 1) then
                self.menu:setState("MODCREATE")
                Assets.stopAndPlaySound("ui_select")
                return
            else
                self.menu.heart_target_x = self.menu.heart_target_x + 45 + 167 + 140
                self.editing = true
                Assets.stopAndPlaySound("ui_select")
            end
        end

    elseif self.editing then
        local value = self.options[self.selected_option]
        if Input.isConfirm(key) or Input.isCancel(key) then
            local y_off = (self.selected_option - 1) * 32
            self.menu.heart_target_x = 45
            self.menu.heart_target_y = 147 + y_off + self.scroll_target_y
            self.editing = false
            Assets.stopAndPlaySound("ui_select")
            return
        end
        if Input.is("left", key) then
            Assets.stopAndPlaySound("ui_move")
            value.selected = value.selected - 1
            if value.selected < 1 then value.selected = #value.options end
        end
        if Input.is("right", key) then
            Assets.stopAndPlaySound("ui_move")
            value.selected = value.selected + 1
            if value.selected > #value.options then value.selected = 1 end
        end
    end
end

function MainMenuModConfig:update()
    if (math.abs((self.scroll_target_y - self.scroll_y)) <= 2) then
        self.scroll_y = self.scroll_target_y
    end
    self.scroll_y = self.scroll_y + ((self.scroll_target_y - self.scroll_y) / 2) * DTMULT
end

function MainMenuModConfig:draw()
    local menu_font = Assets.getFont("main")
    love.graphics.setFont(menu_font)

    Draw.printShadow("Edit Feature Config", 0, 48, 2, "center", 640)

    local menu_x = 64
    local menu_y = 128

    local width = 540
    local height = 32 * 8
    local total_height = 32 * (#self.options + 2)

    Draw.pushScissor()
    Draw.scissor(menu_x, menu_y, width + 10, height + 10)

    menu_y = menu_y + self.scroll_y
    for index, config_option in ipairs(self.options) do
        local y_off = (index - 1) * 32
        local x_off = 0

        local x = menu_x + x_off
        local y = menu_y + y_off
        Draw.printShadow(config_option.name, x, y, 2, "left", 640)

        local option = config_option.options[config_option.selected]
        local option_text = option
        if (option == nil)   then option_text = "Default" end
        if (option == true)  then option_text = "True"    end
        if (option == false) then option_text = "False"   end

        Draw.printShadow(option_text, x + 140 + 256, y)

        if self.editing and self.selected_option == index then
            local width = menu_font:getWidth(option_text)
            Draw.setColor(COLORS.white)
            local off = (math.sin(Kristal.getTime() / 0.2) * 2) + 2
            Draw.draw(Assets.getTexture("kristal/menu_arrow_left"),  x + 140 + 256 - 16 - 8 - off, y + 4, 0, 2, 2)
            Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), x + 140 + width + 256 + 6 + off, y + 4, 0, 2, 2)
        end
    end

    Draw.printShadow("Back", menu_x, menu_y + (#self.options + 1) * 32, 2, "left", 640)

    -- Draw the scrollbar background
    Draw.setColor({1, 1, 1, 0.5})
    love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.scroll_y)

    local scrollbar_height = (height / total_height) * height
    local scrollbar_y = (-self.scroll_y / (total_height - height)) * (height - scrollbar_height)

    Draw.popScissor()
    Draw.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.scroll_y, 4, scrollbar_height)

    local option = self.options[self.selected_option]
    local text
    if option then
        text = option.description
    else
        text = "Return to the mod creation menu"
    end
    Draw.setColor(COLORS.silver)

    local width, wrapped = menu_font:getWrap(text, 580)
    for i, line in ipairs(wrapped) do
        Draw.printShadow(line, 0, 480 + (32 * i) - (32 * (#wrapped + 1)), 2, "center", 640)
    end

    Draw.setColor(1, 1, 1)
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuModConfig:registerOptions()
    self.options = {}

    self:registerOption("enableStorage",          "Enable Storage",            "Extra 48-slot item storage",                                                         "selection", {nil, true, false})
    self:registerOption("enableRecruits",         "Enable Recruits",           "Enable recruit messages and menu",                                                   "selection", {nil, true, false})
    self:registerOption("smallSaveMenu",          "Small Save Menu",           "Single-file save menu with no storage/recruits options",                             "selection", {nil, true, false})
    self:registerOption("lessEquipments",         "Less Equipments",           "Reduces the amount of available weapons and armor slots in the inventory",           "selection", {nil, true, false})
    self:registerOption("partyActions",           "X-Actions",                 "Whether X-Actions appear in spell menu by default",                                  "selection", {nil, true, false})
    self:registerOption("growStronger",           "Grow Stronger",             "Stat increases after defeating an enemy with violence",                              "selection", {nil, true, false})
    self:registerOption("growStrongerChara",      "Grow Stronger Character",   "The character who grows stronger if they're in the party",                           "selection", {nil, false, "kris", "ralsei", "susie", "noelle"}) -- unhardcode
    self:registerOption("susieStyle",             "Susie Style",               "What sprite set Susie should use",                                                   "selection", {nil, 1, 2})
    self:registerOption("ralseiStyle",            "Ralsei Style",              "What sprite set Ralsei should use",                                                  "selection", {nil, 1, 2})
    self:registerOption("oldTensionBar",          "Old Tension Bar",           "Whether the Tension Bar uses blocky corners or not.",                                "selection", {nil, true, false})
    self:registerOption("oldUIPositions",         "Old UI Positions",          "Whether to use Chapter 1 positions of UI elements or not.",                          "selection", {nil, true, false})
    self:registerOption("oldGameOver",            "Old Game Over",             "Whether to use Chapter 1 game over or not.",                                         "selection", {nil, true, false})
    self:registerOption("targetSystem",           "Targeting System",          "Whether battles should use the targeting system or not",                             "selection", {nil, true, false})
    self:registerOption("soulInvBetweenWaves",    "Keep Soul Invulnerability", "Whether the soul invulnerability will carry between waves in battles",               "selection", {nil, true, false})
    self:registerOption("speechBubble",           "Speech Bubble Style",       "The default style for enemy speech bubbles",                                         "selection", {nil, "round", "cyber"}) -- unhardcode
    self:registerOption("enemyAuras",             "Enemy Aura",                "The red aura around enemies",                                                        "selection", {nil, true, false})
    self:registerOption("mercyMessages",          "Mercy Messages",            "Seeing +X% when an enemy's mercy goes up",                                           "selection", {nil, true, false})
    self:registerOption("mercyBar",               "Mercy Bar",                 "Whether the mercy bar should appear or not",                                         "selection", {nil, true, false})
    self:registerOption("enemyBarPercentages",    "Stat Bar Percentages",      "Whether the HP and Mercy bars should show percentages",                              "selection", {nil, true, false})
    self:registerOption("prioritySpareableText",  "Priority Spareable Text",   "Whether enemies' spareable text should be prioritized over tired / low-health text", "selection", {nil, true, false})
    self:registerOption("pushBlockInputLock",     "Push Block Input Locking",  "Whether pushing a block should freeze the player",                                   "selection", {nil, true, false})
    self:registerOption("keepTensionAfterBattle", "Keep Tension After Battle", "Whether TP should be kept after battle instead of reset",                            "selection", {nil, true, false})
    self:registerOption("overworldSpells",        "Overworld Spells",          "Whether spells should be usable in the overworld",                                   "selection", {nil, true, false})
    self:registerOption("damageUnderflowFix",     "Damage Underflow Fix",      "If disabled, negative enemy damage heals the enemy",                                 "selection", {nil, true, false})
end

function MainMenuModConfig:registerOption(id, name, description, type, options)
    table.insert(self.options, {
        id = id,
        name = name,
        description = description,
        type = type,
        options = options,
        selected = 1
    })
end

return MainMenuModConfig