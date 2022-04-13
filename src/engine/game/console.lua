local Console, super = Class(Object)

function Console:init()
    super:init(self, 0, 0)
    self.layer = 10000000

    self.height = 12

    self.font_size = 16
    self.font_name = "console"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.history = {
        "Welcome to [color:cyan]KRISTAL[color:white]! This is the debug console.",
        "You can enter Lua here to be ran! Use clear() to clear the console.",
        "",
    }

    self.command_history = {}

    self.input = {""}

    self.is_open = false

    self.history_index = 0

    self.cursor_x = 0
    self.cursor_y = 1

    self.cursor_select_x = 0
    self.cursor_select_y = 0
    self.selecting = false

    self.cursor_x_tallest = 1

    self.flash_timer = 0

    self:close()

    self.env = self:createEnv()
end

function Console:createEnv()
    local env = {}

    function env.print(str)
        if type(str) == "table" then
            if getmetatable(str) then
                self:warn("Cannot print metatable")
                return
            else
                str = Utils.dump(str)
            end
        end
        self:log(tostring(str))
    end

    function env.clear()
        self.history = {}
    end

    function env.giveItem(str)
        local success, result_text = Game.inventory:tryGiveItem(str)
        if success then
            self:log("Item has been added")
        else
            self:warn("Unable to add item (inventory full?)")
        end
    end

    setmetatable(env, {
        __index = function(t, k)
            return _G[k]
        end,
        __newindex = function(t, k, v)
            _G[k] = v
        end
    })

    return env
end

function Console:open()
    self.is_open = true
    self.history_index = #self.command_history + 1
    self.cursor_x = utf8.len(self.input[#self.input])
    self.cursor_x_tallest = self.cursor_x
    self.cursor_y = #self.input
    love.keyboard.setTextInput(true)
    Game.lock_input = true
    love.keyboard.setKeyRepeat(true)
end

function Console:close()
    self.is_open = false
    Game.lock_input = false
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)
end

function Console:update(dt)
    self.flash_timer = self.flash_timer + dt
    if self.flash_timer > 1 then
        self.flash_timer = self.flash_timer - 1
    end
end

function Console:print(text, x, y, ignore_modifiers)
    -- loop through chars in text
    local x_offset = 0

    local in_modifier = false
    local modifier_text = ""

    for char in text:gmatch(utf8.charpattern) do
        --local char = text:sub(utf8.offset(text,i), utf8.offset(text,i))
        if char == "[" and (not ignore_modifiers) then
            in_modifier = true
        elseif char == "]" and (not ignore_modifiers) then
            in_modifier = false
            local modifier = Utils.split(modifier_text, ":", false)
            if modifier[1] == "color" then
                local color = {1, 1, 1, 1}
                if modifier[2] then
                    if Utils.startsWith(modifier[2], "#") then
                        color = Utils.hexToRgb(modifier[2])
                    elseif modifier[2] == "cyan" then
                        color = {0.5, 1, 1, 1}
                    elseif modifier[2] == "white" then
                        color = {1, 1, 1, 1}
                    elseif modifier[2] == "yellow" then
                        color = {1, 1, 0.5, 1}
                    elseif modifier[2] == "red" then
                        color = {1, 0.5, 0.5, 1}
                    elseif modifier[2] == "gray" then
                        color = {0.8, 0.8, 0.8, 1}
                    end
                end
                love.graphics.setColor(color)
            else
                modifier_text = "[" .. modifier_text .. "]"
                for char2 in modifier_text:gmatch(utf8.charpattern) do
                    if char2 then
                        self:printChar(char2, x + x_offset, y)
                        x_offset = x_offset + self.font:getWidth(char2)
                    end
                end
            end
            modifier_text = ""
        elseif in_modifier and (not ignore_modifiers) then
            modifier_text = modifier_text .. char
        else
            if char then
                self:printChar(char, x + x_offset, y)
                x_offset = x_offset + self.font:getWidth(char)
            end
        end
    end
end

function Console:printChar(char, x, y)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(r / 2, g / 2, b / 2, a / 2)

    love.graphics.print(char, x + 1, y)
    love.graphics.print(char, x - 1, y)
    love.graphics.print(char, x, y + 1)
    love.graphics.print(char, x, y - 1)

    love.graphics.setColor(r, g, b, a)

    love.graphics.print(char, x, y)
end

function Console:draw()
    if not self.is_open then return end
    love.graphics.setFont(self.font)

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    local input_pos = (self.height + 1) * 16

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 640, self.height * 16)

    love.graphics.setColor(1, 1, 1, 1)

    local y_offset = self.height
    for line, text in ipairs(self.history) do
        y_offset = y_offset - #Utils.split(text, "\n", false)
    end

    for line, text in ipairs(self.history) do
        local lines = Utils.split(text, "\n", false)
        for line2, text2 in ipairs(lines) do
            self:print(text2, 8, y_offset * 16)
            y_offset = y_offset + 1
        end

        if y_offset >= self.height then
            break
        end
    end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, input_pos, 640, #self.input * 16)


    local base_off = self.font:getWidth("> ") + 8

    local cursor_pos_x = base_off
    if self.cursor_x > 0 then
        cursor_pos_x = self.font:getWidth(string.sub(self.input[self.cursor_y], 1, utf8.offset(self.input[self.cursor_y], self.cursor_x))) + cursor_pos_x
    end
    local cursor_pos_y = input_pos + ((self.cursor_y - 1) * 16)

    if self.selecting then
        love.graphics.setColor(0, 0.5, 0.5, 1)

        local cursor_sel_x = base_off
        if self.cursor_select_x > 0 then
            cursor_sel_x = self.font:getWidth(string.sub(self.input[self.cursor_select_y], 1, utf8.offset(self.input[self.cursor_select_y], self.cursor_select_x))) + cursor_sel_x
        end
        local cursor_sel_y = input_pos + ((self.cursor_select_y - 1) * 16)


        if self.cursor_select_y == self.cursor_y then
            local x = cursor_sel_x
            local y = cursor_sel_y + 16
            local width = cursor_pos_x - x
            local height = cursor_pos_y + 16 - y - 16

            love.graphics.rectangle("fill", x, y, width, height)
        else
            local in_front = false
            if self.cursor_y > self.cursor_select_y then
                in_front = true
            end

            if in_front then
                love.graphics.rectangle("fill", cursor_sel_x, cursor_sel_y, math.max(self.font:getWidth(self.input[self.cursor_select_y]) - cursor_sel_x + base_off, 1), 16)
                love.graphics.rectangle("fill", base_off, cursor_pos_y, cursor_pos_x - base_off, 16)

                for i = self.cursor_select_y + 1, self.cursor_y - 1 do
                    love.graphics.rectangle("fill", base_off, input_pos + (16 * (i - 1)), math.max(self.font:getWidth(self.input[i]), 1), 16)
                end
            else
                love.graphics.rectangle("fill", cursor_pos_x, cursor_pos_y, math.max(self.font:getWidth(self.input[self.cursor_y]) - cursor_pos_x + base_off, 1), 16)
                love.graphics.rectangle("fill", base_off, cursor_sel_y, cursor_sel_x - base_off, 16)

                for i = self.cursor_y + 1, self.cursor_select_y - 1 do
                    love.graphics.rectangle("fill", base_off, input_pos + (16 * (i - 1)), math.max(self.font:getWidth(self.input[i]), 1), 16)
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    for i, text in ipairs(self.input) do
        if #self.input == 1 then
            self:print("> " .. text, 8, input_pos + (i - 1) * 16, true)
        else
            local prefix = ""
            if i == 1 then
                prefix = "┌ "
            elseif i == #self.input then
                prefix = "└ "
            else
                prefix = "│ "
            end
            self:print(prefix .. text, 8, input_pos + (i - 1) * 16, true)
        end
    end

    love.graphics.setColor(1, 0, 1, 1)
    if self.flash_timer < 0.5 then
        if self.cursor_x == utf8.len(self.input[self.cursor_y]) then
            self:print("_", cursor_pos_x, cursor_pos_y, true)
        else
            self:print("|", cursor_pos_x, cursor_pos_y, true)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    -- FOR DEBUGGING HISTORY:
    --[[offset = 0
    for i, v in ipairs(self.command_history) do
        if i == self.history_index then
            love.graphics.setColor(1, 0, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        for j, text in ipairs(v) do
            offset = offset + 1
            self:print(text, 8, 200 + ((offset) * 16), true)
        end
    end]]

    super:draw(self)
end

function Console:selectAll()
    self.cursor_x = 0
    self.cursor_y = 1
    self.cursor_select_x = utf8.len(self.input[#self.input])
    self.cursor_select_y = #self.input
    self.selecting = true
end

function Console:removeSelection()
    if not self.selecting then return end

    local in_front = false
    if self.cursor_y > self.cursor_select_y then
        in_front = true
    elseif self.cursor_y == self.cursor_select_y then
        if self.cursor_x >= self.cursor_select_x then
            in_front = true
        end
    end

    local start_x, start_y, end_x, end_y = 0, 0, 0, 0

    if in_front then
        start_x = self.cursor_select_x
        start_y = self.cursor_select_y
        end_x = self.cursor_x
        end_y = self.cursor_y
    else
        start_x = self.cursor_x
        start_y = self.cursor_y
        end_x = self.cursor_select_x
        end_y = self.cursor_select_y
    end

    if start_y == end_y then
        self.input[start_y] = string.sub(self.input[start_y], 1, start_x) .. string.sub(self.input[start_y], end_x + 1)
    else
        local new_input = {}
        for i = 1, start_y - 1 do
            table.insert(new_input, self.input[i])
        end

        for i = start_y, end_y do
            local text = self.input[i]
            if i == start_y then
                text = string.sub(text, 1, start_x)
                table.insert(new_input, text)
            elseif i == end_y then
                text = string.sub(text, end_x + 1)
                new_input[start_y] = new_input[start_y] .. text
            end
        end

        for i = end_y + 1, #self.input do
            table.insert(new_input, self.input[i])
        end
        self.input = new_input
    end

    self.cursor_x = start_x
    self.cursor_y = start_y
    self.cursor_select_x = start_x
    self.cursor_select_y = start_y
    self.cursor_x_tallest = self.cursor_x
    self.selecting = false
end

function Console:getSelectedText()
    if not self.selecting then return "" end

    local text = ""
    if self.cursor_y == self.cursor_select_y then
        if self.cursor_x > self.cursor_select_x then
            text = string.sub(self.input[self.cursor_y], self.cursor_select_x + 1, self.cursor_x)
        else
            text = string.sub(self.input[self.cursor_y], self.cursor_x + 1, self.cursor_select_x)
        end
    else
        if self.cursor_y < self.cursor_select_y then
            text = string.sub(self.input[self.cursor_y], self.cursor_x + 1)
            for i = self.cursor_y + 1, self.cursor_select_y - 1 do
                text = text .. "\n" .. self.input[i]
            end
            text = text .. "\n" .. string.sub(self.input[self.cursor_select_y], 1, self.cursor_select_x)
        else
            text = string.sub(self.input[self.cursor_select_y], self.cursor_select_x + 1)
            for i = self.cursor_select_y + 1, self.cursor_y - 1 do
                text = text .. "\n" .. self.input[i]
            end
            text = text .. "\n" .. string.sub(self.input[self.cursor_y], 1, self.cursor_x)
        end
    end

    return text
end

function Console:textinput(t)
    if not self.is_open then return end
    self:insertString(t)
end

function Console:insertString(str)

    if self.selecting then
        self:removeSelection()
    end

    self.flash_timer = 0
    local string_1 = string.sub(self.input[self.cursor_y], 1, utf8.offset(self.input[self.cursor_y], self.cursor_x))
    local string_2 = string.sub(self.input[self.cursor_y],    utf8.offset(self.input[self.cursor_y], self.cursor_x) + 1, -1)

    if self.cursor_x == 0 then
        string_1 = ""
        string_2 = self.input[self.cursor_y]
    end

    local split = Utils.split(string_1 .. str .. string_2, "\n", false)

    split[1] = split[1]:gsub("\n?$",""):gsub("\r","");
    self.input[self.cursor_y] = split[1]
    for i = 2, #split do
        split[i] = split[i]:gsub("\n?$",""):gsub("\r","");
        table.insert(self.input, self.cursor_y + i - 1, split[i])
    end

    self.cursor_x = utf8.len(split[#split]) - utf8.len(string_2)
    self.cursor_x_tallest = self.cursor_x
    self.cursor_y = self.cursor_y + #split - 1
    --self.cursor_x = self.cursor_y + utf8.len(str)
end

function Console:push(str)
    table.insert(self.history, str)
end

function Console:log(str)
    print("[CONSOLE] " .. tostring(str))
    self:push(str)
end

function Console:warn(str)
    print("[WARNING] " .. tostring(str))
    self:push("[color:yellow][WARNING] " .. tostring(str))
end

function Console:error(str)
    print("[ERROR] " .. tostring(str))
    self:push("[color:red][ERROR] " .. tostring(str))
end

function Console:stripError(str)
    return string.match(str, '.+:%d+: (.+)')
end

function Console:run(str)
    if not Utils.equal(str, self.command_history[#self.command_history]) then
        table.insert(self.command_history, str)
    end
    self.history_index = #self.command_history + 1
    local run_string = ""
    local history_string = "[color:gray]"
    for i, line in ipairs(str) do
        local prefix = "> "

        if #str > 1 then
            if i == 1 then
                prefix = "┌ "
            elseif i == #str then
                prefix = "└ "
            else
                prefix = "│ "
            end
        end

        if i == #str then
            history_string = history_string .. prefix .. line
            run_string     = run_string     ..           line
        else
            history_string = history_string .. prefix .. line .. "\n"
            run_string     = run_string     ..           line .. "\n"
        end
    end
    self:push(history_string)
    local status, error = pcall(function() self:unsafeRun(run_string) end)
    if not status then
        self:error(self:stripError(error))
    end
end

function Console:unsafeRun(str)
    local chunk, error = loadstring(str)
    if chunk then
        setfenv(chunk,self.env)
        self:push(chunk())
    else
        self:error(self:stripError(error))
    end
end

function Console:keypressed(key)
    if key == "`" then
        if self.is_open then
            self:close()
        else
            self:open()
        end
    end

    if not self.is_open then return end

    if (key == "c") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        love.system.setClipboardText(self:getSelectedText())
    elseif (key == "x") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        love.system.setClipboardText(self:getSelectedText())
        self:removeSelection()
    elseif (key == "v") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        self:insertString(love.system.getClipboardText())
    elseif (key == "a") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        self:selectAll()
    elseif key == "return" then
        if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            self:insertString("\n")
        else
            self:run(self.input)
            self.input = {""}
            self.cursor_x = 0
            self.cursor_x_tallest = 0
            self.cursor_y = 1
            self.cursor_select_x = 0
            self.cursor_select_y = 0
            self.selecting = false
            self.flash_timer = 0
        end
    elseif key == "tab" then
        self:insertString("    ")
    elseif key == "backspace" then
        self.flash_timer = 0

        if self.selecting then
            self:removeSelection()
            return
        end

        if self.cursor_x == 0 and self.cursor_y == 1 then return end

        if self.cursor_x == 0 then
            self.cursor_y = self.cursor_y - 1
            self.cursor_x = utf8.len(self.input[self.cursor_y])
            self.cursor_x_tallest = self.cursor_x
            self.input[self.cursor_y] = self.input[self.cursor_y] .. self.input[self.cursor_y + 1]
            table.remove(self.input, self.cursor_y + 1)
        else
            local string_1 = string.sub(self.input[self.cursor_y], 1, utf8.offset(self.input[self.cursor_y], self.cursor_x))
            local string_2 = string.sub(self.input[self.cursor_y],    utf8.offset(self.input[self.cursor_y], self.cursor_x) + 1, -1)

            -- get the byte offset to the last UTF-8 character in the string.
            local byteoffset = utf8.offset(string_1, -1)

            if byteoffset then
                -- remove the last UTF-8 character.
                -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
                string_1 = string.sub(string_1, 1, byteoffset - 1)
                self.cursor_x = utf8.len(string_1)
                self.cursor_x_tallest = self.cursor_x
            end
            self.input[self.cursor_y] = string_1 .. string_2
        end
    elseif key == "up" then
        if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            if not self.selecting then
                self.cursor_select_x = self.cursor_x
                self.cursor_select_y = self.cursor_y
                self.selecting = true
            end
        else
            if self.selecting then
                self.selecting = false
                if self.cursor_y > self.cursor_select_y then
                    self.cursor_y = self.cursor_select_y
                    self.cursor_x = self.cursor_select_x
                    self.cursor_x_tallest = self.cursor_x
                end
            end
        end

        self.flash_timer = 0
        if self.cursor_y <= 1 then
            self.cursor_y = 1
            if #self.command_history == 0 then return end
            if self.history_index > 1 then
                self.history_index = self.history_index - 1
                self.input = Utils.copy(self.command_history[self.history_index] or {""})
                self.cursor_x = utf8.len(self.input[#self.input])
                self.cursor_x_tallest = self.cursor_x
                self.cursor_y = #self.input
            end
        else
            self.cursor_y = self.cursor_y - 1
            self.cursor_x = math.min(self.cursor_x_tallest, utf8.len(self.input[self.cursor_y]))
        end
    elseif key == "down" then
        if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            if not self.selecting then
                self.cursor_select_x = self.cursor_x
                self.cursor_select_y = self.cursor_y
                self.selecting = true
            end
        else
            if self.selecting then
                self.selecting = false

                if self.cursor_y < self.cursor_select_y then
                    self.cursor_y = self.cursor_select_y
                    self.cursor_x = self.cursor_select_x
                    self.cursor_x_tallest = self.cursor_x
                end
            end
        end
        self.flash_timer = 0
        if self.cursor_y == #self.input then
            if #self.command_history == 0 then return end
            if self.history_index == #self.command_history + 1 then

            else
                self.history_index = self.history_index + 1
                self.input = Utils.copy(self.command_history[self.history_index] or {""})
                self.cursor_x = utf8.len(self.input[#self.input])
                self.cursor_x_tallest = self.cursor_x
                self.cursor_y = #self.input
            end
            self.cursor_x = utf8.len(self.input[self.cursor_y])
            self.cursor_x_tallest = self.cursor_x
        else
            self.cursor_y = self.cursor_y + 1
            self.cursor_x = math.min(self.cursor_x_tallest, utf8.len(self.input[self.cursor_y]))
        end
    elseif key == "left" then
        if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            if not self.selecting then
                self.cursor_select_x = self.cursor_x
                self.cursor_select_y = self.cursor_y
                self.selecting = true
            end
        else
            if self.selecting then
                self.selecting = false
                if (self.cursor_y > self.cursor_select_y) or (self.cursor_x > self.cursor_select_x) then
                    self.cursor_x = self.cursor_select_x
                    self.cursor_y = self.cursor_select_y
                    self.cursor_x_tallest = self.cursor_x
                end
                return
            end
        end
        self.flash_timer = 0
        if self.cursor_x > 0 then
            self.cursor_x = self.cursor_x - 1
        else
            if self.cursor_y ~= 1 then
                self.cursor_y = self.cursor_y - 1
                self.cursor_x = utf8.len(self.input[self.cursor_y])
            end
        end
        self.cursor_x_tallest = self.cursor_x
    elseif key == "right" then
        if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            if not self.selecting then
                self.cursor_select_x = self.cursor_x
                self.cursor_select_y = self.cursor_y
                self.selecting = true
            end
        else
            if self.selecting then
                self.selecting = false
                if (self.cursor_y < self.cursor_select_y) or (self.cursor_x < self.cursor_select_x) then
                    self.cursor_x = self.cursor_select_x
                    self.cursor_y = self.cursor_select_y
                    self.cursor_x_tallest = self.cursor_x
                end
                return
            end
        end
        self.flash_timer = 0
        if self.cursor_x < utf8.len(self.input[self.cursor_y]) then
            self.cursor_x = self.cursor_x + 1
        else
            if self.cursor_y ~= #self.input then
                self.cursor_y = self.cursor_y + 1
                self.cursor_x = 0
            end
        end
        self.cursor_x_tallest = self.cursor_x
    end
end

return Console