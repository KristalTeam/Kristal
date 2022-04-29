local TextInput = {}
local self = TextInput

self.input = {""} -- A *reference* to an input table.

self.active = false

self.submit_callback = nil
self.up_limit_callback = nil
self.down_limit_callback = nil

function TextInput.attachInput(tbl, options)
    Game.lock_input = true -- TODO: Instead of using lock_input, other thing should check if text input is active.
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
    Game.lock_input = false
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
    self.insertString(t)
end

function TextInput.onKeyPressed(key)
    
    if (key == "c") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        love.system.setClipboardText(self.getSelectedText())
    elseif (key == "x") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        love.system.setClipboardText(self.getSelectedText())
        self.removeSelection()
    elseif (key == "v") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        self.insertString(love.system.getClipboardText())
    elseif (key == "a") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        self.selectAll()
    elseif key == "return" then
        local shift = (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"))

        if self.enter_submits then
            if self.multiline and shift then
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
        self.flash_timer = 0

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
            if self.up_limit_callback then
                self.up_limit_callback()
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

function TextInput.update()
    self.flash_timer = self.flash_timer + DT
    if self.flash_timer > 1 then
        self.flash_timer = self.flash_timer - 1
    end
end

function TextInput.sendCursorToEnd()
    self.cursor_x = utf8.len(self.input[#self.input])
    self.cursor_x_tallest = self.cursor_x
    self.cursor_y = #self.input
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

self.reset()

return self