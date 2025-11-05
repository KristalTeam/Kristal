---@class MainMenuControls : StateClass
---
---@field menu MainMenu
---
---@field control_menu "keyboard"|"gamepad"
---
---@field selected_option number
---@field selected_bind number
---
---@field selecting_key boolean
---@field rebinding boolean
---
---@field rebinding_shift boolean
---@field rebinding_ctrl boolean
---@field rebinding_alt boolean
---@field rebinding_cmd boolean
---
---@field scroll_target_y number
---@field scroll_y number
---
---@overload fun(menu:MainMenu) : MainMenuControls
local MainMenuControls, super = Class(StateClass)

function MainMenuControls:init(menu)
    self.menu = menu

    self.control_menu = "keyboard"

    self.pages = {}
    self.hidden_pages = {}
    self.selected_page = 1

    self.selected_option = 1
    self.selected_bind = 1

    self.selecting_key = false
    self.rebinding = false

    self.rebinding_shift = false
    self.rebinding_alt = false
    self.rebinding_ctrl = false
    self.rebinding_cmd = false

    self.scroll_target_y = 0
    self.scroll_y = 0

    self.scroll_direction = "right"
    self.scroll_timer = 0
end

function MainMenuControls:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("keyreleased", self.onKeyReleased)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

function MainMenuControls:registerMainPage()
    local page = {}

    page.title = "KRISTAL"
    page.mod = "KRISTAL"
    page.entries = {}

    for _, keybind in ipairs(Input.order) do
        table.insert(
            page.entries,
            { keybind = keybind, name = (Input.getBindName(keybind) or keybind:gsub("_", " ")):upper() }
        )
    end

    table.insert(self.pages, page)
end

function MainMenuControls:registerModPages()
    for mod_id, keys in pairs(Input.mod_keybinds) do
        local page = {}
        local mod = Kristal.Mods.getMod(mod_id)
        if mod["hideKeybinds"] then
            goto continue
        end

        page.title = tostring(mod.name):upper()
        page.mod = mod_id
        page.entries = {}

        for _, keybind in ipairs(keys) do
            table.insert(page.entries,
                         { keybind = keybind, name = (Input.getBindName(keybind) or keybind:gsub("_", " ")):upper() })
        end

        table.insert(self.pages, page)
        ::continue::
    end
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuControls:onEnter(old_state, control_menu, target_mod)
    self.control_menu = control_menu or self.control_menu

    self.pages = {}
    self.hidden_pages = {}
    -- Reload the pages every time we enter incase there is a new keybind
    self:registerMainPage()
    self:registerModPages()

    self.selected_option = 1
    self.selected_bind = 1
    self.selected_page = 1

    self.target_mod = nil
    if target_mod then
        for i, page in ipairs(self.pages) do
            if page.mod == target_mod then
                self.target_mod = target_mod
                self.selected_page = i
            end
        end
        if not self.target_mod then
            Assets.playSound("ui_cant_select")
            self.menu:popState()
        end
    end

    self.selecting_key = false
    self.rebinding = false

    self.rebinding_shift = false
    self.rebinding_alt = false
    self.rebinding_ctrl = false
    self.rebinding_cmd = false

    self.scroll_target_y = 0
    self.scroll_y = 0

    self.scroll_direction = "right"
    self.scroll_timer = 0

    self.menu.heart_target_x = 152
    self.menu.heart_target_y = 129 + 0 * 32
end

function MainMenuControls:onKeyPressed(key, is_repeat)
    if (not self.rebinding) and (not self.selecting_key) then
        local selected_page = self:getSelectedPage()
        local bind_list = self.control_menu == "gamepad" and Input.gamepad_bindings or Input.key_bindings
        local option_count = TableUtils.getKeyCount(selected_page.entries) + 2
        local page_count = #self.pages
        if self.control_menu == "gamepad" then
            option_count = option_count + 1
        end

        local old_selected = self.selected_option
        if Input.is("up", key) then self.selected_option = self.selected_option - 1 end
        if Input.is("down", key) then self.selected_option = self.selected_option + 1 end
        if self.selected_option < 1 then self.selected_option = is_repeat and 1 or option_count end
        if self.selected_option > option_count then self.selected_option = is_repeat and option_count or 1 end

        if old_selected ~= self.selected_option then
            Assets.stopAndPlaySound("ui_move")
        end

        if not self.target_mod then
            local old_page = self.selected_page
            local page_dir = "right"
            if Input.is("left", key) then
                self.selected_page = self.selected_page - 1; page_dir = "left"
            end
            if Input.is("right", key) then
                self.selected_page = self.selected_page + 1; page_dir = "right"
            end
            if self.selected_page < 1 then self.selected_page = is_repeat and 1 or page_count end
            if self.selected_page > page_count then self.selected_page = is_repeat and page_count or 1 end


            if old_page ~= self.selected_page then
                Assets.stopAndPlaySound("ui_move")
                selected_page = self:getSelectedPage()
                option_count = TableUtils.getKeyCount(selected_page.entries) + 2
                if self.control_menu == "gamepad" then
                    option_count = option_count + 1
                end

                self.selected_option = 1

                self.scroll_direction = page_dir
                self.scroll_timer = 0.1
            end
        end

        if Input.isCancel(key) then
            Assets.stopAndPlaySound("ui_select")
            Input.saveBinds()
            self.menu:popState()
        elseif Input.isConfirm(key) then
            self.rebinding = false
            self.selecting_key = false
            -- Reset to Defaults
            if (self.selected_option == option_count - 1) then
                Input.resetBinds(self.control_menu == "gamepad", selected_page.mod)
                Assets.stopAndPlaySound("ui_select")
                self.selected_option = option_count - 1
                self.menu.heart_target_y = (129 + (self.selected_option) * 32) + self.scroll_target_y
                -- Back
            elseif (self.selected_option == option_count) then
                Assets.stopAndPlaySound("ui_select")
                Input.saveBinds()
                self.menu:popState()
                -- (Gamepad) Configure Deadzone
            elseif self.control_menu == "gamepad" and self.selected_option == option_count - 2 then
                Assets.stopAndPlaySound("ui_select")
                self.menu:pushState("DEADZONE")
            else
                self.rebinding = false
                self.selecting_key = true
                self.selected_bind = 1
                Assets.stopAndPlaySound("ui_select")
            end
        end
    elseif self.selecting_key then
        local table_key = self:getSelectedKey()

        local old = self.selected_bind
        if Input.is("left", key) then self.selected_bind = self.selected_bind - 1 end
        if Input.is("right", key) then self.selected_bind = self.selected_bind + 1 end
        self.selected_bind = math.max(1, math.min(#self:getBoundKeys(table_key), self.selected_bind))

        if old ~= self.selected_bind then
            Assets.stopAndPlaySound("ui_move")
        end

        if Input.isConfirm(key) then
            self.rebinding = true
            self.selecting_key = false
            Assets.stopAndPlaySound("ui_select")
        end
        if Input.isCancel(key) then
            self.rebinding = false
            self.selecting_key = false
            self.selected_bind = 1
            Assets.stopAndPlaySound("ui_select")
        end
    elseif self.rebinding then
        Input.clear(key)

        local gamepad = self.control_menu == "gamepad"
        if not gamepad and key == "lshift" or key == "rshift" then
            self.rebinding_shift = true
        elseif not gamepad and key == "lctrl" or key == "rctrl" then
            self.rebinding_ctrl = true
        elseif not gamepad and key == "lalt" or key == "ralt" then
            self.rebinding_alt = true
        elseif not gamepad and key == "lgui" or key == "rgui" then
            self.rebinding_cmd = true
        else
            local valid_key = true
            local bound_key
            if key ~= "escape" then
                if gamepad ~= StringUtils.startsWith(key, "gamepad:") then
                    valid_key = false
                else
                    bound_key = { key }

                    -- https://ux.stackexchange.com/questions/58185/normative-ordering-for-modifier-key-combinations
                    if self.rebinding_cmd then table.insert(bound_key, 1, "cmd") end
                    if self.rebinding_shift then table.insert(bound_key, 1, "shift") end
                    if self.rebinding_alt then table.insert(bound_key, 1, "alt") end
                    if self.rebinding_ctrl then table.insert(bound_key, 1, "ctrl") end

                    if #bound_key == 1 then
                        bound_key = bound_key[1]
                    end
                end
            else
                bound_key = "escape"
            end

            if valid_key then
                -- rebind!!
                local worked = Input.setBind(self:getSelectedKey(), self.selected_bind, bound_key,
                                             self.control_menu == "gamepad")

                self.rebinding = false
                self.rebinding_shift = false
                self.rebinding_ctrl = false
                self.rebinding_alt = false
                self.rebinding_cmd = false

                self.selected_bind = 1

                if worked then
                    Assets.stopAndPlaySound("ui_select")
                else
                    Assets.stopAndPlaySound("ui_cant_select")
                end
            end
        end
    end
end

function MainMenuControls:onKeyReleased(key)
    if self.rebinding then
        local released_modifier =
            (self.rebinding_ctrl and (key == "lctrl" or key == "rctrl")) or
            (self.rebinding_shift and (key == "lshift" or key == "rshift")) or
            (self.rebinding_alt and (key == "lalt" or key == "ralt")) or
            (self.rebinding_cmd and (key == "lcmd" or key == "rcmd"))

        if released_modifier then
            local bound_key = {}

            -- https://ux.stackexchange.com/questions/58185/normative-ordering-for-modifier-key-combinations
            if self.rebinding_cmd then table.insert(bound_key, 1, "cmd") end
            if self.rebinding_shift then table.insert(bound_key, 1, "shift") end
            if self.rebinding_alt then table.insert(bound_key, 1, "alt") end
            if self.rebinding_ctrl then table.insert(bound_key, 1, "ctrl") end

            if #bound_key == 1 then
                bound_key = bound_key[1]
            end

            -- rebind!!
            local worked = Input.setBind(
                self:getSelectedKey(),
                self.selected_bind,
                bound_key,
                self.control_menu == "gamepad"
            )

            self.rebinding = false
            self.rebinding_shift = false
            self.rebinding_ctrl = false
            self.rebinding_alt = false
            self.rebinding_cmd = false

            self.selected_bind = 1
            self.menu.heart_target_x = 152

            if worked then
                Assets.stopAndPlaySound("ui_select")
            else
                Assets.stopAndPlaySound("ui_cant_select")
            end
        end
    end
end

function MainMenuControls:update()
    local selected_page = self.pages[self.selected_page]
    if self.target_mod then
        local old = self.control_menu
        self.control_menu = Input.usingGamepad() and "gamepad" or "keyboard"
        -- Slightly imperfect at consistency with input switching but it affects about two of the bottom options only
        -- Most importantly though nothing breaks and you cannot go out of the menu bounds
        if old ~= self.control_menu and self.selected_option > TableUtils.getKeyCount(selected_page.entries) + 1 then
            if self.control_menu == "keyboard" then
                self.selected_option = self.selected_option - 1
            else
                self.selected_option = self.selected_option + 1
            end
        end
    end

    -- Update heart position
    local y_off = (self.selected_option - 1) * 32
    if self.selected_option > (TableUtils.getKeyCount(selected_page.entries)) then
        y_off = y_off + 32
    end

    if y_off + self.scroll_target_y < 0 then
        self.scroll_target_y = self.scroll_target_y + (0 - (y_off + self.scroll_target_y))
    end

    if y_off + self.scroll_target_y > (9 * 32) then
        self.scroll_target_y = self.scroll_target_y + ((9 * 32) - (y_off + self.scroll_target_y))
    end

    if not (self.rebinding or self.selecting_key) then
        self.menu.heart_target_x = 152
    else
        self.menu.heart_target_x = 408
    end
    self.menu.heart_target_y = 129 + y_off + self.scroll_target_y

    -- Update scroll position
    if (math.abs((self.scroll_target_y - self.scroll_y)) <= 2) then
        self.scroll_y = self.scroll_target_y
    end
    self.scroll_y = self.scroll_y + ((self.scroll_target_y - self.scroll_y) / 2) * DTMULT

    if self.scroll_timer > 0 then
        self.scroll_timer = MathUtils.approach(self.scroll_timer, 0, DT)
    end
end

function MainMenuControls:draw()
    local selected_page = self:getSelectedPage()
    local font = Assets.getFont("main")

    love.graphics.setFont(font)
    Draw.setColor(COLORS.silver)
    Draw.printShadow("( OPTIONS )", 0, 0, 2, "center", 640)

    Draw.setColor(1, 1, 1)
    Draw.printShadow("" .. self.control_menu:upper() .. " CONTROLS", 0, 48, 2, "center", 640)
    Draw.setColor(COLORS.silver)
    Draw.printShadow("(" .. selected_page.title .. ")", 0, 74, 2, "center", 640)
    Draw.setColor(1, 1, 1)

    local menu_x = 185 - 14
    local menu_y = 110

    local width = 460
    local height = 32 * 10
    local total_height = 32 * (#(selected_page.entries) + (self.control_menu == "gamepad" and 4 or 3))

    Draw.pushScissor()
    Draw.scissor(menu_x, menu_y, width + 10, height + 10)

    menu_y = menu_y + self.scroll_y

    local y_offset = 0

    for _, key in ipairs(selected_page.entries) do
        Draw.printShadow(key.name, menu_x, menu_y + (32 * y_offset))

        self:drawKeyBindMenu(key.keybind, menu_x, menu_y, y_offset)
        y_offset = y_offset + 1
    end

    y_offset = y_offset + 1

    if self.control_menu == "gamepad" then
        Draw.printShadow("Configure Deadzone", menu_x, menu_y + (32 * y_offset))
        y_offset = y_offset + 1
    end

    Draw.printShadow("Reset to defaults", menu_x, menu_y + (32 * y_offset))
    Draw.printShadow("Back", menu_x, menu_y + (32 * (y_offset + 1)))

    if height < total_height then
        -- Draw the scrollbar background (lighter than the others since it's against black)
        Draw.setColor({ 1, 1, 1, 0.5 })
        love.graphics.rectangle("fill", menu_x + width, 0, 4, menu_y + height - self.scroll_y)

        local scrollbar_height = (height / total_height) * height
        local scrollbar_y = (-self.scroll_y / (total_height - height)) * (height - scrollbar_height)

        Draw.popScissor()
        Draw.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", menu_x + width, menu_y + scrollbar_y - self.scroll_y, 4, scrollbar_height)
    else
        Draw.popScissor()
    end

    -- Draw menu arrows
    if #self.pages > 1 and not self.target_mod then
        local l_offset, r_offset = 0, 0
        local mod_width = font:getWidth("(" .. selected_page.title .. ")")

        if self.scroll_timer > 0 then
            if self.scroll_direction == "left" then
                l_offset = -4
            elseif self.scroll_direction == "right" then
                r_offset = 4
            end
        end

        Draw.setColor(COLORS.silver)
        Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), 320 + (mod_width / 2) + 8 + r_offset, 78, 0, 2, 2)
        Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), 320 - (mod_width / 2) - 26 + l_offset, 78, 0, 2, 2)
    end

    Draw.setColor(COLORS.silver)
    Draw.printShadow("CTRL+ALT+SHIFT+T to reset binds.", 0, 480 - 32, 2, "center", 640)
    Draw.setColor(1, 1, 1)
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuControls:drawKeyBindMenu(name, menu_x, menu_y, y_offset)
    local menu_font = Assets.getFont("main")
    local x_offset = 0
    if self.selected_option == (y_offset + 1) then
        for i, v in ipairs(self:getBoundKeys(name)) do
            local drawstr = v:upper()
            if StringUtils.startsWith(v, "gamepad:") then
                drawstr = "     "
            end
            if i < #self:getBoundKeys(name) then
                drawstr = drawstr .. ", "
            end
            if i < self.selected_bind then
                x_offset = x_offset - menu_font:getWidth(drawstr) - 8
            end
        end
    end
    Draw.pushScissor()
    Draw.scissorPoints(380, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    for i, v in ipairs(self:getBoundKeys(name)) do
        local drawstr = v:upper()
        local btn = nil
        if StringUtils.startsWith(v, "gamepad:") then
            drawstr = "     "
            btn = Input.getButtonTexture(v)
        end
        local color = { 1, 1, 1, 1 }
        if self.selecting_key or self.rebinding then
            if self.selected_option == (y_offset + 1) then
                color = { 0.5, 0.5, 0.5, 1 }
            end
        end
        if (self.selected_option == (y_offset + 1)) and (i == self.selected_bind) then
            color = { 1, 1, 1, 1 }
            if self.rebinding then
                color = { 0, 1, 1, 1 }

                if self.rebinding_shift or self.rebinding_ctrl or self.rebinding_alt or self.rebinding_cmd then
                    drawstr = ""

                    if self.rebinding_cmd then drawstr = "CMD+" .. drawstr end
                    if self.rebinding_shift then drawstr = "SHIFT+" .. drawstr end
                    if self.rebinding_alt then drawstr = "ALT+" .. drawstr end
                    if self.rebinding_ctrl then drawstr = "CTRL+" .. drawstr end
                end
            end
        end
        if i < #self:getBoundKeys(name) then
            drawstr = drawstr .. ", "
        end
        Draw.setColor(color)
        Draw.printShadow(drawstr, menu_x + (8 * 32) + x_offset, menu_y + (32 * y_offset))
        if btn then
            Draw.setColor(0, 0, 0, 1)
            Draw.draw(btn, menu_x + (8 * 32) + x_offset + 2, menu_y + (32 * y_offset) + 4, 0, 2, 2)
            Draw.setColor(1, 1, 1, 1)
            Draw.draw(btn, menu_x + (8 * 32) + x_offset, menu_y + (32 * y_offset) + 2, 0, 2, 2)
        end
        x_offset = x_offset + menu_font:getWidth(drawstr) + 8
        Draw.setColor(1, 1, 1)
    end
    Draw.popScissor()
end

function MainMenuControls:getBoundKeys(key)
    local keys = {}
    for _, k in ipairs(Input.getBoundKeys(key, self.control_menu == "gamepad") or {}) do
        if type(k) == "table" then
            table.insert(keys, table.concat(k, "+"))
        else
            table.insert(keys, k)
        end
    end
    if (self.rebinding or self.selecting_key) and (key == self:getSelectedKey()) then
        table.insert(keys, "---")
        return keys
    end
    return keys
end

---@return {title: string, mod:string, entries: {keybind: string, name:string}[]}
function MainMenuControls:getSelectedPage()
    return self.pages[self.selected_page]
end

---@return string? keybind
function MainMenuControls:getSelectedKey()
    local page = self:getSelectedPage()
    local option = self.selected_option
    if option > #page.entries then
        return nil
    end
    return page.entries[option].keybind
end

return MainMenuControls
