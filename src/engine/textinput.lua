---@class TextInput
---
---@field input string[]
---
---@field active boolean
---
---@field multiline boolean
---@field enter_submits boolean
---@field clear_after_submit boolean
---@field text_restriction (fun(char:string):string|boolean)?
---
---@field submit_callback fun()?
---@field up_limit_callback fun()?
---@field down_limit_callback fun()?
---@field pressed_callback (fun(key:string):boolean|nil)?
---@field text_callback fun(text:string)?
---
---@field selecting boolean
---
---@field flash_timer number
---
---@field cursor_x number
---@field cursor_x_tallest number
---@field cursor_y number
---@field cursor_select_x number
---@field cursor_select_y number
---
local TextInput = {}
local self = TextInput

self.input = {""} -- A *reference* to an input table.

self.active = false

self.submit_callback = nil
self.up_limit_callback = nil
self.down_limit_callback = nil
self.pressed_callback = nil
self.text_callback = nil

---@param tbl string[]
---@param options TextInput.inputOptions?
function TextInput.attachInput(tbl, options)
    Kristal.showCursor()
    self.active = true
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    self.updateInput(tbl)

    self.reset(options)

    self.submit_callback = nil
    self.up_limit_callback = nil
    self.down_limit_callback = nil
    self.pressed_callback = nil
    self.text_callback = nil
end

---@param tbl string[]
function TextInput.updateInput(tbl)
    self.input = tbl
end

function TextInput.endInput()
    if not Kristal.DebugSystem or not Kristal.DebugSystem:selectionOpen() then
        Kristal.hideCursor()
    end
    self.active = false
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)
end

function TextInput.clear()
    Utils.clear(self.input)
    self.input[1] = ""
    self.reset(false)
end

---@class TextInput.inputOptions
---@field multiline boolean?
---@field enter_submits boolean?
---@field clear_after_submit boolean?
---@field text_restriction (fun(char:string):string|boolean)?

---@param options TextInput.inputOptions|boolean|nil
function TextInput.reset(options)
    if options ~= false then
        options = options or {} --[[@as TextInput.inputOptions]]
        -- Our defaults should allow text editor-like input
        if options.multiline          == nil then options.multiline          = true  end
        if options.enter_submits      == nil then options.enter_submits      = false end
        if options.clear_after_submit == nil then options.clear_after_submit = true  end
        self.multiline = options.multiline
        self.enter_submits = options.enter_submits
        self.clear_after_submit = options.clear_after_submit
        self.text_restriction = options.text_restriction
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
        Kristal.Console:warn("No submit callback set!")
    end
    if self.clear_after_submit then
        self.clear()
    end
end


function TextInput.onTextInput(t)
    if not self.active then return end
    self.insertString(t)
    if self.text_callback then self.text_callback(t) end
end

---@return "selecting"|"stopped"|"not_selecting"
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

---@param key string
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
            local string_1
            local string_2

            if Input.ctrl() then
                local starting_position, ending_position = self.ctrlLeft()
                starting_position = starting_position + 1
                ending_position = ending_position + 1
                string_1 = Utils.sub(self.input[self.cursor_y], 1, starting_position)
                string_2 = Utils.sub(self.input[self.cursor_y], ending_position, -1)
            else

                string_1 = Utils.sub(self.input[self.cursor_y], 1, self.cursor_x)
                string_2 = Utils.sub(self.input[self.cursor_y], self.cursor_x + 1, -1)
            end

            string_1 = Utils.sub(string_1, 1, -2)
            self.cursor_x = utf8.len(string_1)
            self.cursor_x_tallest = self.cursor_x

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
            if Input.ctrl() then
                -- Loop from our current position to the end of the line.
                local starting_position, ending_position = self.ctrlRight()
                if starting_position ~= 0 then
                    string_1 = Utils.sub(self.input[self.cursor_y], 1, starting_position)
                    string_2 = Utils.sub(self.input[self.cursor_y], ending_position, -1)
                else
                    string_1 = ""
                    string_2 = Utils.sub(self.input[self.cursor_y], ending_position, -1)
                end
            else
                if self.cursor_x ~= 0 then
                    string_1 = Utils.sub(self.input[self.cursor_y], 1, self.cursor_x)
                    string_2 = Utils.sub(self.input[self.cursor_y], self.cursor_x + 1, -1)
                else
                    string_1 = ""
                    string_2 = self.input[self.cursor_y]
                end
            end

            -- remove the first UTF-8 character.
            string_2 = Utils.sub(string_2, 2, -1)

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

            local starting_position, ending_position = self.ctrlLeft()
            self.cursor_x = starting_position
            self.cursor_x_tallest = starting_position
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

            local starting_position, ending_position = self.ctrlRight()
            self.cursor_x = ending_position
            self.cursor_x_tallest = ending_position
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

---@return number start_position, number end_position
function TextInput.ctrlLeft()
    local starting_position = self.cursor_x
    local ending_position = self.cursor_x

    local first_char = Utils.sub(self.input[self.cursor_y], starting_position, starting_position)
    local was_part = self.isPartOfWord(first_char)

    -- Loop from our current position to the start of the line.
    local hit = false
    for i = ending_position, 0, -1 do
        if i == 0 then
            starting_position = 0
            break
        end
        local char = Utils.sub(self.input[self.cursor_y], i, i)

        if (self.isPartOfWord(char) ~= was_part) then hit = true end

        if hit then
            hit = false
            if starting_position ~= i then
                starting_position = i
                break
            end
        end
    end
    return starting_position, ending_position
end

---@return number start_position, number end_position
function TextInput.ctrlRight()
    local starting_position, ending_position = self.cursor_x, self.cursor_x

    local first_char = Utils.sub(self.input[self.cursor_y], starting_position + 1, starting_position + 1)
    local was_part = self.isPartOfWord(first_char)

    local hit = false
    for i = starting_position, utf8.len(self.input[self.cursor_y]) do
        if i == utf8.len(self.input[self.cursor_y]) then
            ending_position = i
            break
        end
        local char = Utils.sub(self.input[self.cursor_y], i + 1, i + 1)

        if (self.isPartOfWord(char) ~= was_part) then hit = true end

        if hit then
            hit = false
            if ending_position ~= i then
                ending_position = i
                break
            end
        end
    end
    return starting_position, ending_position
end

---@param char string
---@return boolean
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

---@param special_indenting boolean?
function TextInput.sendCursorToStartOfLine(special_indenting)
    if self.cursor_x == 0 then
        self.cursor_x_tallest = 0
        return
    end

    if special_indenting then
        -- Loop through the utf8 string and find the end of an indent
        local last_space = 0
        for i = 1, utf8.len(self.input[self.cursor_y]) do
            local char = Utils.sub(self.input[self.cursor_y], i, i)
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
        self.input[start_y] = Utils.sub(self.input[start_y], 1, start_x) .. Utils.sub(self.input[start_y], end_x + 1)
    else
        local old_input = Utils.copy(self.input)
        Utils.clear(self.input)
        for i = 1, start_y - 1 do
            table.insert(self.input, old_input[i])
        end

        for i = start_y, end_y do
            local text = old_input[i]
            if i == start_y then
                text = Utils.sub(text, 1, start_x)
                table.insert(self.input, text)
            elseif i == end_y then
                text = Utils.sub(text, end_x + 1)
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

---@return string
function TextInput.getSelectedText()
    if not self.selecting then return "" end

    local text = ""
    if self.cursor_y == self.cursor_select_y then
        if self.cursor_x > self.cursor_select_x then
            text = Utils.sub(self.input[self.cursor_y], self.cursor_select_x + 1, self.cursor_x)
        else
            text = Utils.sub(self.input[self.cursor_y], self.cursor_x + 1, self.cursor_select_x)
        end
    else
        if self.cursor_y < self.cursor_select_y then
            text = Utils.sub(self.input[self.cursor_y], self.cursor_x + 1)
            for i = self.cursor_y + 1, self.cursor_select_y - 1 do
                text = text .. "\n" .. self.input[i]
            end
            text = text .. "\n" .. Utils.sub(self.input[self.cursor_select_y], 1, self.cursor_select_x)
        else
            text = Utils.sub(self.input[self.cursor_select_y], self.cursor_select_x + 1)
            for i = self.cursor_select_y + 1, self.cursor_y - 1 do
                text = text .. "\n" .. self.input[i]
            end
            text = text .. "\n" .. Utils.sub(self.input[self.cursor_y], 1, self.cursor_x)
        end
    end

    return text
end


---@param str string
function TextInput.insertString(str)

    if self.text_restriction then
        local newstr = ""
        for i = 1, utf8.len(str) do
            local char = Utils.sub(str, i, i)
            local rest = self.text_restriction(char)
            if rest then
                if type(rest) == "string" then
                    newstr = newstr .. rest
                else
                    newstr = newstr .. char
                end
            end
        end
        str = newstr
    end

    if str == "" then return end

    if self.selecting then
        self.removeSelection()
    end

    self.flash_timer = 0
    local string_1 = Utils.sub(self.input[self.cursor_y], 1, self.cursor_x)
    local string_2 = Utils.sub(self.input[self.cursor_y],    self.cursor_x + 1, -1)

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

---@class TextInput.drawOptions
---@field x number?
---@field y number?
---@field font love.Font?
---@field get_prefix (fun(prefix:"single"|"start"|"end"|"middle"):string)?
---@field print fun(text:string, x:number, y:number)?

---@param options TextInput.drawOptions
function TextInput.draw(options)
    local off_x = options["x"] or 0
    local off_y = options["y"] or 0
    local font = options["font"] or Assets.getFont("main_mono", 16)
    local get_prefix = options["get_prefix"] or function(prefix) return "" end
    local print_func = options["print"] or love.graphics.print

    local base_off = (options["prefix_width"] or 0) + off_x

    local cursor_pos_x = base_off
    if self.cursor_x > 0 then
        cursor_pos_x = font:getWidth(Utils.sub(self.input[self.cursor_y], 1, self.cursor_x)) + cursor_pos_x
    end
    local cursor_pos_y = off_y + ((self.cursor_y - 1) * font:getHeight())

    if self.selecting then
        Draw.setColor(0, 0.5, 0.5, 1)

        local cursor_sel_x = base_off
        if self.cursor_select_x > 0 then
            cursor_sel_x = font:getWidth(Utils.sub(self.input[self.cursor_select_y], 1, self.cursor_select_x)) + cursor_sel_x
        end
        local cursor_sel_y = off_y + ((self.cursor_select_y - 1) * font:getHeight())


        if self.cursor_select_y == self.cursor_y then
            local x = cursor_sel_x
            local y = cursor_sel_y + font:getHeight()
            local width = cursor_pos_x - x
            local height = cursor_pos_y + font:getHeight() - y - font:getHeight()

            love.graphics.rectangle("fill", x, y, width, height)
        else
            local in_front = false
            if self.cursor_y > self.cursor_select_y then
                in_front = true
            end

            if in_front then
                love.graphics.rectangle("fill", cursor_sel_x, cursor_sel_y, math.max(font:getWidth(self.input[self.cursor_select_y]) - cursor_sel_x + base_off, 1), font:getHeight())
                love.graphics.rectangle("fill", base_off, cursor_pos_y, cursor_pos_x - base_off, font:getHeight())

                for i = self.cursor_select_y + 1, self.cursor_y - 1 do
                    love.graphics.rectangle("fill", base_off, off_y + (font:getHeight() * (i - 1)), math.max(font:getWidth(self.input[i]), 1), font:getHeight())
                end
            else
                love.graphics.rectangle("fill", cursor_pos_x, cursor_pos_y, math.max(font:getWidth(self.input[self.cursor_y]) - cursor_pos_x + base_off, 1), font:getHeight())
                love.graphics.rectangle("fill", base_off, cursor_sel_y, cursor_sel_x - base_off, font:getHeight())

                for i = self.cursor_y + 1, self.cursor_select_y - 1 do
                    love.graphics.rectangle("fill", base_off, off_y + (font:getHeight() * (i - 1)), math.max(font:getWidth(self.input[i]), 1), font:getHeight())
                end
            end
        end
    end

    Draw.setColor(1, 1, 1, 1)
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
        print_func(prefix, off_x, off_y + (i - 1) * font:getHeight())
        print_func(text, base_off, off_y + (i - 1) * font:getHeight())
    end

    Draw.setColor(1, 0, 1, 1)
    if (TextInput.flash_timer < 0.5) and self.active then
        if self.cursor_x == utf8.len(self.input[self.cursor_y]) then
            print_func("_", cursor_pos_x, cursor_pos_y)
        else
            print_func("|", cursor_pos_x, cursor_pos_y)
        end
    end
end

self.reset()

return self