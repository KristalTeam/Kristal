local TextInput = {}
local self = TextInput

self.input = {""} -- A *reference* to an input table.

self.active = false

self.submit_callback = nil
self.up_limit_callback = nil
self.down_limit_callback = nil
self.pressed_callback = nil

function TextInput.attachInput(tbl, options)
    Kristal.showCursor()
    Game.lock_movement = true -- TODO: Instead of using lock_movement, other thing should check if text input is active.
    self.active = true
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    self.updateInput(tbl)

    self.reset(options)
end

function TextInput.updateInput(tbl)
    self.input = tbl
end

function TextInput.endInput()
    if not Kristal.DebugSystem or not Kristal.DebugSystem:mouseOpen() then
        Kristal.hideCursor()
    end
    Game.lock_movement = false
    self.active = false
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)
end

function TextInput.clear()
    Utils.clear(self.input)
    self.input[1] = ""
    self.reset(false)
end

function TextInput.reset(options)
    if options ~= false then
        options = options or {}
        -- Our defaults should allow text editor-like input
        self.multiline = options.multiline or true
        self.enter_submits = options.enter_submits or false
    end

    self.selecting = false

    -- Let's handle flashing cursors here, since they change based on text state
    -- If the user doesn't want it, then they don't have to draw it
    self.flash_timer = 0

    self.cursor_x = 0
    self.cursor_x_tallest = 0
    self.cursor_y = 1
    self.cursor_select_x = 0
    self.cursor_select_y = 0

    self.sendCursorToEnd()
end

function TextInput.submit()
    if self.submit_callback then
        self.submit_callback()
    else
        print("WARNING: No submit callback set!")
    end
    self.clear()
end


function TextInput.onTextInput(t)
    if not self.active then return end
    self.insertString(t)
end

function TextInput.checkSelecting()
    if Input.shift() then
        if not self.selecting then
            self.cursor_select_x = self.cursor_x
            self.cursor_select_y = self.cursor_y
            self.selecting = true
        end
        return "selecting"
    end

    -- Return false if we *just* stopped selecting
    if self.selecting then
        self.selecting = false
        return "stopped"
    end
    return "not_selecting"
end

function TextInput.onKeyPressed(key)
    if not self.active then return end
    self.flash_timer = 0
    if self.pressed_callback then
        if self.pressed_callback(key) then
            return
        end
    end
    if (key == "c") and Input.ctrl() then
        love.system.setClipboardText(self.getSelectedText())
    elseif (key == "x") and Input.ctrl() then
        love.system.setClipboardText(self.getSelectedText())
        self.removeSelection()
    elseif (key == "v") and Input.ctrl() then
        self.insertString(love.system.getClipboardText())
    elseif (key == "a") and Input.ctrl() then
        self.selectAll()
    elseif key == "return" then
        if self.enter_submits then
            if self.multiline and Input.shift() then
                self.insertString("\n")
            else
                self.submit()
            end
        else
            if self.multiline then
                self.insertString("\n")
            end
        end
    elseif key == "tab" then
        self.insertString("    ")
    elseif key == "backspace" then
        if self.selecting then
            self.removeSelection()
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
            local byteoffset = utf8.offset(string_1, -2)

            if byteoffset then
                -- remove the last UTF-8 character.
                -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
                string_1 = string.sub(string_1, 1, byteoffset)
                self.cursor_x = utf8.len(string_1)
                self.cursor_x_tallest = self.cursor_x
            else
                -- No offset, so assume we only have one character
                string_1 = ""
                self.cursor_x = 0
                self.cursor_x_tallest = 0
            end
            self.input[self.cursor_y] = string_1 .. string_2
        end
    elseif key == "delete" then
        if self.selecting then
            self.removeSelection()
            return
        end

        if self.cursor_x == utf8.len(self.input[self.cursor_y]) and self.cursor_y == #self.input then return end

        if self.cursor_x == utf8.len(self.input[self.cursor_y]) then
            self.input[self.cursor_y] = self.input[self.cursor_y] .. self.input[self.cursor_y + 1]
            table.remove(self.input, self.cursor_y + 1)
        else
            local string_1
            local string_2
            if self.cursor_x ~= 0 then
                string_1 = string.sub(self.input[self.cursor_y], 1, utf8.offset(self.input[self.cursor_y], self.cursor_x))
                string_2 = string.sub(self.input[self.cursor_y],    utf8.offset(self.input[self.cursor_y], self.cursor_x) + 1, -1)
            else
                string_1 = ""
                string_2 = self.input[self.cursor_y]
            end

            -- get the byte offset to the first UTF-8 character in the string.
            local byteoffset = utf8.offset(string_2, 2)

            if byteoffset then
                -- remove the first UTF-8 character.
                -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
                string_2 = string.sub(string_2, byteoffset, -1)
            end
            self.input[self.cursor_y] = string_1 .. string_2
        end
    elseif key == "up" then
        if self.checkSelecting() == "stopped" then
            if self.cursor_y > self.cursor_select_y then
                self.cursor_y = self.cursor_select_y
                self.cursor_x = self.cursor_select_x
                self.cursor_x_tallest = self.cursor_x
            end
        end

        if self.cursor_y <= 1 then
            self.cursor_y = 1
            if self.up_limit_callback then
                self.up_limit_callback()
            end
        else
            self.cursor_y = self.cursor_y - 1
            self.cursor_x = math.min(self.cursor_x_tallest, utf8.len(self.input[self.cursor_y]))
        end
    elseif key == "end" then
        self.checkSelecting()

        if Input.ctrl() then
            self.sendCursorToEnd()
        else
            self.sendCursorToEndOfLine()
        end
    elseif key == "home" then
        self.checkSelecting()

        if Input.ctrl() then
            self.sendCursorToStart()
        else
            self.sendCursorToStartOfLine(true)
        end
    elseif key == "down" then
        if self.checkSelecting() == "stopped" then
            if self.cursor_y < self.cursor_select_y then
                self.cursor_y = self.cursor_select_y
                self.cursor_x = self.cursor_select_x
                self.cursor_x_tallest = self.cursor_x
            end
        end
        if self.cursor_y == #self.input then
            self.cursor_x = utf8.len(self.input[self.cursor_y])
            self.cursor_x_tallest = self.cursor_x
            if self.down_limit_callback then
                self.down_limit_callback()
            end
        else
            self.cursor_y = self.cursor_y + 1
            self.cursor_x = math.min(self.cursor_x_tallest, utf8.len(self.input[self.cursor_y]))
        end
    elseif key == "left" then
        if self.checkSelecting() == "stopped" then
            if (self.cursor_y > self.cursor_select_y) or (self.cursor_x > self.cursor_select_x) then
                self.cursor_x = self.cursor_select_x
                self.cursor_y = self.cursor_select_y
                self.cursor_x_tallest = self.cursor_x
            end
            return
        end
        if Input.ctrl() then
            -- If we're at the start of a line, move to the end of the previous line.
            if self.cursor_x == 0 then
                if self.cursor_y == 1 then return end
                self.cursor_y = self.cursor_y - 1
                self.cursor_x = utf8.len(self.input[self.cursor_y])
            end
            -- Loop from our current position to the start of the line.
            local hit = false
            for i = self.cursor_x, 0, -1 do
                if i == 0 then
                    self.cursor_x = 0
                    self.cursor_x_tallest = 0
                    break
                end
                local offset = utf8.offset(self.input[self.cursor_y], i)
                local char = string.sub(self.input[self.cursor_y], offset, offset)

                if (not self.isPartOfWord(char)) then hit = true end

                if hit then
                    hit = false
                    if self.cursor_x ~= i then
                        self.cursor_x = i
                        self.cursor_x_tallest = self.cursor_x
                        break
                    end
                end
            end
        else
            -- Not holding CTRL, just move to the left linke normal
            if self.cursor_x > 0 then
                self.cursor_x = self.cursor_x - 1
            else
                if self.cursor_y ~= 1 then
                    self.cursor_y = self.cursor_y - 1
                    self.cursor_x = utf8.len(self.input[self.cursor_y])
                end
            end
        end
        self.cursor_x_tallest = self.cursor_x
    elseif key == "right" then
        if self.checkSelecting() == "stopped" then
            if (self.cursor_y < self.cursor_select_y) or (self.cursor_x < self.cursor_select_x) then
                self.cursor_x = self.cursor_select_x
                self.cursor_y = self.cursor_select_y
                self.cursor_x_tallest = self.cursor_x
            end
            return
        end
        if Input.ctrl() then
            -- If we're at the start of a line, move to the end of the previous line.
            if self.cursor_x == utf8.len(self.input[self.cursor_y]) then
                if self.cursor_y == #self.input then return end
                self.cursor_y = self.cursor_y + 1
                self.cursor_x = 0
            end
            -- Loop from our current position to the end of the line.
            local hit = false
            for i = self.cursor_x, utf8.len(self.input[self.cursor_y]) do
                if i == utf8.len(self.input[self.cursor_y]) then
                    self.cursor_x = i
                    self.cursor_x_tallest = i
                    break
                end
                local offset = utf8.offset(self.input[self.cursor_y], i + 1)
                local char = string.sub(self.input[self.cursor_y], offset, offset)

                if (not self.isPartOfWord(char)) then hit = true end

                if hit then
                    hit = false
                    if self.cursor_x ~= i then
                        self.cursor_x = i
                        self.cursor_x_tallest = self.cursor_x
                        break
                    end
                end
            end
        else
            if self.cursor_x < utf8.len(self.input[self.cursor_y]) then
                self.cursor_x = self.cursor_x + 1
            else
                if self.cursor_y ~= #self.input then
                    self.cursor_y = self.cursor_y + 1
                    self.cursor_x = 0
                end
            end
        end
        self.cursor_x_tallest = self.cursor_x
    end
end

function TextInput.update()
    self.flash_timer = self.flash_timer + DT
    if self.flash_timer > 1 then
        self.flash_timer = self.flash_timer - 1
    end
end

function TextInput.isPartOfWord(char)
    if char == "_" then return true end -- underscores are commonly used so we'll allow them in words
    if char == "-" then return true end -- same with dashes
    if char:match("%W") then return false end -- not alphanumeric, so not part of a word
    return true -- alphanumeric, so part of a word
end

function TextInput.sendCursorToEnd()
    self.cursor_x = utf8.len(self.input[#self.input])
    self.cursor_x_tallest = self.cursor_x
    self.cursor_y = #self.input
end

function TextInput.sendCursorToEndOfLine()
    self.cursor_x = utf8.len(self.input[self.cursor_y])
    self.cursor_x_tallest = self.cursor_x
end

function TextInput.sendCursorToStart()
    self.cursor_x = 0
    self.cursor_x_tallest = 0
    self.cursor_y = 1
end

function TextInput.sendCursorToStartOfLine(special_identing)
    if cursor_x == 0 then
        cursor_x_tallest = 0
        return
    end

    if special_identing then
        -- Loop through the utf8 string and find the end of an indent
        local last_space = 0
        for i = 1, utf8.len(self.input[self.cursor_y]) do
            local offset = utf8.offset(self.input[self.cursor_y], i)
            local char = string.sub(self.input[self.cursor_y], offset, offset)
            if char == " " then
                last_space = i
            else
                break
            end
        end
        -- We're not at the end of an indent, so send the cursor to it
        if self.cursor_x ~= last_space then
            self.cursor_x = last_space
            self.cursor_x_tallest = self.cursor_x
            return
        -- We're at the end of an indent, let's just go to the start
        end
    end
    self.cursor_x = 0
    self.cursor_x_tallest = 0
end

function TextInput.selectAll()
    self.cursor_x = 0
    self.cursor_y = 1
    self.cursor_select_x = utf8.len(self.input[#self.input])
    self.cursor_select_y = #self.input
    self.selecting = true
end


function TextInput.removeSelection()
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
        local old_input = Utils.copy(self.input)
        Utils.clear(self.input)
        for i = 1, start_y - 1 do
            table.insert(self.input, old_input[i])
        end

        for i = start_y, end_y do
            local text = old_input[i]
            if i == start_y then
                text = string.sub(text, 1, start_x)
                table.insert(self.input, text)
            elseif i == end_y then
                text = string.sub(text, end_x + 1)
                self.input[start_y] = self.input[start_y] .. text
            end
        end

        for i = end_y + 1, #old_input do
            table.insert(self.input, old_input[i])
        end
    end

    self.cursor_x = start_x
    self.cursor_y = start_y
    self.cursor_select_x = start_x
    self.cursor_select_y = start_y
    self.cursor_x_tallest = self.cursor_x
    self.selecting = false
end

function TextInput.getSelectedText()
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


function TextInput.insertString(str)

    if self.selecting then
        self.removeSelection()
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

function TextInput.draw(options)
    local off_x = options["x"] or 0
    local off_y = options["y"] or 0
    local font = options["font"] or Assets.getFont("console")
    local get_prefix = options["get_prefix"] or function() return "" end
    local print_func = options["print"] or love.graphics.print

    local base_off = (options["prefix_width"] or 0) + off_x

    local cursor_pos_x = base_off
    if self.cursor_x > 0 then
        cursor_pos_x = font:getWidth(string.sub(self.input[self.cursor_y], 1, utf8.offset(self.input[self.cursor_y], self.cursor_x))) + cursor_pos_x
    end
    local cursor_pos_y = off_y + ((self.cursor_y - 1) * 16)

    if self.selecting then
        love.graphics.setColor(0, 0.5, 0.5, 1)

        local cursor_sel_x = base_off
        if self.cursor_select_x > 0 then
            cursor_sel_x = font:getWidth(string.sub(self.input[self.cursor_select_y], 1, utf8.offset(self.input[self.cursor_select_y], self.cursor_select_x))) + cursor_sel_x
        end
        local cursor_sel_y = off_y + ((self.cursor_select_y - 1) * 16)


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
                love.graphics.rectangle("fill", cursor_sel_x, cursor_sel_y, math.max(font:getWidth(self.input[self.cursor_select_y]) - cursor_sel_x + base_off, 1), 16)
                love.graphics.rectangle("fill", base_off, cursor_pos_y, cursor_pos_x - base_off, 16)

                for i = self.cursor_select_y + 1, self.cursor_y - 1 do
                    love.graphics.rectangle("fill", base_off, off_y + (16 * (i - 1)), math.max(font:getWidth(self.input[i]), 1), 16)
                end
            else
                love.graphics.rectangle("fill", cursor_pos_x, cursor_pos_y, math.max(font:getWidth(self.input[self.cursor_y]) - cursor_pos_x + base_off, 1), 16)
                love.graphics.rectangle("fill", base_off, cursor_sel_y, cursor_sel_x - base_off, 16)

                for i = self.cursor_y + 1, self.cursor_select_y - 1 do
                    love.graphics.rectangle("fill", base_off, off_y + (16 * (i - 1)), math.max(font:getWidth(self.input[i]), 1), 16)
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    for i, text in ipairs(self.input) do
        local prefix = ""
        if #self.input == 1 then
            prefix = get_prefix("single")
        else
            if i == 1 then
                prefix = get_prefix("start")
            elseif i == #self.input then
                prefix = get_prefix("end")
            else
                prefix = get_prefix("middle")
            end
        end
        print_func(prefix, off_x, off_y + (i - 1) * 16, true)
        print_func(text, base_off, off_y + (i - 1) * 16, true)
    end

    love.graphics.setColor(1, 0, 1, 1)
    if TextInput.flash_timer < 0.5 then
        if self.cursor_x == utf8.len(self.input[self.cursor_y]) then
            print_func("_", cursor_pos_x, cursor_pos_y, true)
        else
            print_func("|", cursor_pos_x, cursor_pos_y, true)
        end
    end
end

self.reset()

return self