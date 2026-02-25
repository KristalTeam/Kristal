--- This module handles text input.
---
--- Unlike a lot of other games and projects, this module is designed to make text input seamless, like a tranditional text editor.
--- This involves moving the cursor around, selecting and inserting text, and using the clipboard.
---
--- Many keybinds are implemented. Cut, copy and paste are supported, as well as selecting all text.
--- Ctrl+arrows are also implemented for word navigation.
---
--- Multi-line input fields are supported, as well as single-line fields which submit on enter.
--- The system is also UTF-8 aware.
---@class TextInput
---
---@field input string[] # A *reference* to an input table.
---
---@field active boolean # Whether text input is active or not.
---@field submit_callback fun()? # A callback that is called when the input is submitted.
---@field up_limit_callback fun()? # A callback that is called when the cursor reaches the top of the input.
---@field down_limit_callback fun()? # A callback that is called when the cursor reaches the bottom of the input.
---@field pressed_callback (fun(key:string):boolean|nil)? # A callback that is called when a key is pressed.
---@field text_callback fun(text:string)? # A callback that is called when text is inputted.
---
---@field multiline boolean # Whether this input is multiline.
---@field enter_submits boolean # Whether pressing enter submits the input.
---@field clear_after_submit boolean # Whether the input should be cleared after submitting.
---@field text_restriction (fun(char:string):string|boolean)? # A function which restricts (and transforms) the text input.
---@field allow_overtyping boolean # Whether overtyping is allowed.
---
---@field selecting boolean # Whether selection is active or not.
---@field overtyping boolean # Whether overtyping is active or not.
---
---@field flash_timer number # A timer for flashing the cursor.
---@field return_grace_timer number # The timer that blocks immediate return submission.
---
---@field cursor_x integer # The current cursor X position.
---@field cursor_x_tallest integer # The "tallest" (furthest to the right) cursor X position (used for multiline).
---@field cursor_y integer # The current cursor Y position.
---@field cursor_select_x integer # The X position of where a selection started.
---@field cursor_select_y integer # The Y position of where a selection started.
---
local TextInput = {}

--- Initialize the text input system.
---@internal
function TextInput.init()
    TextInput.input = { "" }

    TextInput.active = false

    TextInput.submit_callback = nil
    TextInput.up_limit_callback = nil
    TextInput.down_limit_callback = nil
    TextInput.pressed_callback = nil
    TextInput.text_callback = nil

    TextInput.setOptions(nil)
    TextInput.reset()
end

---@class TextInput.inputOptions
---@field multiline boolean? # Whether the input is multiline. Defaults to true.
---@field enter_submits boolean? # Whether pressing enter submits the input. Defaults to false.
---@field clear_after_submit boolean? # Whether the input should be cleared after submitting. Defaults to true.
---@field allow_overtyping boolean? # Whether overtyping is allowed. Defaults to false.
---@field text_restriction (fun(char:string):string|boolean)? # A function which restricts (and transforms) the text input.

--- Set the system's options.
---
--- This does not reset the system, and should be used alongside {@link TextInput.reset}, or anything which calls it.
---@param options TextInput.inputOptions? # The new options to use. If nil, the default options are used.
function TextInput.setOptions(options)
    options = options or {} --[[@as TextInput.inputOptions]]
    -- Our defaults should allow text editor-like input
    if options.multiline == nil then options.multiline = true end
    if options.enter_submits == nil then options.enter_submits = false end
    if options.clear_after_submit == nil then options.clear_after_submit = true end
    if options.allow_overtyping == nil then options.allow_overtyping = false end

    TextInput.multiline = options.multiline
    TextInput.enter_submits = options.enter_submits
    TextInput.clear_after_submit = options.clear_after_submit
    TextInput.text_restriction = options.text_restriction
    TextInput.allow_overtyping = options.allow_overtyping
end

---@param tbl string[]
---@param options TextInput.inputOptions?
function TextInput.attachInput(tbl, options)
    Kristal.showCursor()
    TextInput.active = true
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    TextInput.updateInput(tbl)

    TextInput.setOptions(options)
    TextInput.reset()

    TextInput.submit_callback = nil
    TextInput.up_limit_callback = nil
    TextInput.down_limit_callback = nil
    TextInput.pressed_callback = nil
    TextInput.text_callback = nil
end

---@param tbl string[]
function TextInput.updateInput(tbl)
    TextInput.input = tbl
end

function TextInput.endInput()
    if not Kristal.DebugSystem or not Kristal.DebugSystem:selectionOpen() then
        Kristal.hideCursor()
    end
    TextInput.active = false
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)
end

function TextInput.clear()
    TableUtils.clear(TextInput.input)
    TextInput.input[1] = ""
    TextInput.reset()
end

--- Reset the text input system.
---
--- This does NOT change the system's options.
function TextInput.reset()
    TextInput.selecting = false
    TextInput.overtyping = false

    -- Let's handle flashing cursors here, since they change based on text state
    -- If the user doesn't want it, then they don't have to draw it
    TextInput.flash_timer = 0

    -- Most inputs will be entered through the confirm keybind, of which return
    -- is a default bind. As this key can also be used to close the input, we
    -- need a tiny timer that "blocks" return presses from submitting the text
    -- immediately (only used to block text submission)
    TextInput.return_grace_timer = 2

    TextInput.cursor_x = 0
    TextInput.cursor_x_tallest = 0
    TextInput.cursor_y = 1
    TextInput.cursor_select_x = 0
    TextInput.cursor_select_y = 0

    TextInput.sendCursorToEnd()
end

--- This is internally called when you submit your input.
---
--- If you want to run custom code on submit, use the submit callback.
---@internal
function TextInput.submit()
    if TextInput.submit_callback then
        TextInput.submit_callback()
    else
        Kristal.Console:warn("No submit callback set!")
    end
    if TextInput.clear_after_submit then
        TextInput.clear()
    end
end

--- The listener for when the program receives text input.
---@internal
function TextInput.onTextInput(t)
    if not TextInput.active then return end
    TextInput.insertString(t)
    if TextInput.text_callback then TextInput.text_callback(t) end
end

---@return "selecting"|"stopped"|"not_selecting"
function TextInput.checkSelecting()
    if Input.shift() then
        if not TextInput.selecting then
            TextInput.cursor_select_x = TextInput.cursor_x
            TextInput.cursor_select_y = TextInput.cursor_y
            TextInput.selecting = true
        end
        return "selecting"
    end

    -- Return false if we *just* stopped selecting
    if TextInput.selecting then
        TextInput.selecting = false
        return "stopped"
    end
    return "not_selecting"
end

---@param key string
function TextInput.onKeyPressed(key)
    if not TextInput.active then return end
    TextInput.flash_timer = 0
    if TextInput.pressed_callback then
        if TextInput.pressed_callback(key) then
            return
        end
    end
    if (key == "c") and Input.ctrl() then
        love.system.setClipboardText(TextInput.getSelectedText())
    elseif (key == "x") and Input.ctrl() then
        love.system.setClipboardText(TextInput.getSelectedText())
        TextInput.removeSelection()
    elseif (key == "v") and Input.ctrl() then
        TextInput.insertString(love.system.getClipboardText())
    elseif (key == "a") and Input.ctrl() then
        TextInput.selectAll()
    elseif key == "return" then
        if TextInput.enter_submits then
            if TextInput.multiline and Input.shift() then
                TextInput.insertString("\n")
            else
                if TextInput.return_grace_timer > 0 then Input.clear("return", true) return end
                TextInput.submit()
            end
        else
            if TextInput.multiline then
                TextInput.insertString("\n")
            end
        end
    elseif key == "tab" then
        TextInput.insertString("    ")
    elseif key == "backspace" then
        if TextInput.selecting then
            TextInput.removeSelection()
            return
        end

        if TextInput.cursor_x == 0 and TextInput.cursor_y == 1 then return end

        if TextInput.cursor_x == 0 then
            TextInput.cursor_y = TextInput.cursor_y - 1
            TextInput.cursor_x = StringUtils.len(TextInput.getCurrentLine())
            TextInput.cursor_x_tallest = TextInput.cursor_x
            TextInput.input[TextInput.cursor_y] = TextInput.getCurrentLine() .. TextInput.input[TextInput.cursor_y + 1]
            table.remove(TextInput.input, TextInput.cursor_y + 1)
        else
            local string_1
            local string_2

            local line = TextInput.getCurrentLine()

            if Input.ctrl() then
                local delete_end = TextInput.cursor_x
                local delete_start = TextInput.getPreviousWordStart() + 1


                -- Get characters before and after the deletion range
                string_1 = StringUtils.sub(line, 1, delete_start - 1)
                string_2 = StringUtils.sub(line, delete_end + 1)
            else
                string_1 = StringUtils.sub(line, 1, TextInput.cursor_x)
                string_2 = StringUtils.sub(line, TextInput.cursor_x + 1)
            end

            string_1 = StringUtils.sub(string_1, 1, -2)
            TextInput.cursor_x = StringUtils.len(string_1)
            TextInput.cursor_x_tallest = TextInput.cursor_x

            TextInput.input[TextInput.cursor_y] = string_1 .. string_2
        end
    elseif key == "delete" then
        if TextInput.selecting then
            TextInput.removeSelection()
            return
        end

        if TextInput.cursor_x == StringUtils.len(TextInput.getCurrentLine()) and TextInput.cursor_y == #TextInput.input then return end

        if TextInput.cursor_x == StringUtils.len(TextInput.getCurrentLine()) then
            TextInput.input[TextInput.cursor_y] = TextInput.getCurrentLine() .. TextInput.input[TextInput.cursor_y + 1]
            table.remove(TextInput.input, TextInput.cursor_y + 1)
        else
            local line = TextInput.getCurrentLine()

            local string_1
            local string_2

            if Input.ctrl() then
                local start_pos = TextInput.cursor_x
                local end_pos = TextInput.getNextWordEnd()

                if start_pos > 0 then
                    -- Lua strings are 1-based, so adjust indexes accordingly
                    string_1 = StringUtils.sub(line, 1, start_pos)
                    string_2 = StringUtils.sub(line, end_pos + 1)
                else
                    string_1 = ""
                    string_2 = StringUtils.sub(line, end_pos + 1)
                end
            else
                if TextInput.cursor_x ~= 0 then
                    string_1 = StringUtils.sub(line, 1, TextInput.cursor_x)
                    string_2 = StringUtils.sub(line, TextInput.cursor_x + 2)
                else
                    string_1 = ""
                    string_2 = StringUtils.sub(line, 2)
                end
            end

            TextInput.input[TextInput.cursor_y] = string_1 .. string_2
        end
    elseif key == "up" then
        if TextInput.checkSelecting() == "stopped" then
            if TextInput.cursor_y > TextInput.cursor_select_y then
                TextInput.cursor_y = TextInput.cursor_select_y
                TextInput.cursor_x = TextInput.cursor_select_x
                TextInput.cursor_x_tallest = TextInput.cursor_x
            end
        end

        if TextInput.cursor_y <= 1 then
            TextInput.cursor_y = 1
            if TextInput.up_limit_callback then
                TextInput.up_limit_callback()
            end
        else
            TextInput.cursor_y = TextInput.cursor_y - 1
            TextInput.cursor_x = math.min(TextInput.cursor_x_tallest, StringUtils.len(TextInput.getCurrentLine()))
        end
    elseif key == "end" then
        TextInput.checkSelecting()

        if Input.ctrl() then
            TextInput.sendCursorToEnd()
        else
            TextInput.sendCursorToEndOfLine()
        end
    elseif key == "home" then
        TextInput.checkSelecting()

        if Input.ctrl() then
            TextInput.sendCursorToStart()
        else
            TextInput.sendCursorToStartOfLine(true)
        end
    elseif key == "down" then
        if TextInput.checkSelecting() == "stopped" then
            if TextInput.cursor_y < TextInput.cursor_select_y then
                TextInput.cursor_y = TextInput.cursor_select_y
                TextInput.cursor_x = TextInput.cursor_select_x
                TextInput.cursor_x_tallest = TextInput.cursor_x
            end
        end
        if TextInput.cursor_y == #TextInput.input then
            TextInput.cursor_x = StringUtils.len(TextInput.getCurrentLine())
            TextInput.cursor_x_tallest = TextInput.cursor_x
            if TextInput.down_limit_callback then
                TextInput.down_limit_callback()
            end
        else
            TextInput.cursor_y = TextInput.cursor_y + 1
            TextInput.cursor_x = math.min(TextInput.cursor_x_tallest, StringUtils.len(TextInput.getCurrentLine()))
        end
    elseif key == "insert" then
        if TextInput.allow_overtyping then
            TextInput.overtyping = not TextInput.overtyping
        end
    elseif key == "left" then
        if TextInput.checkSelecting() == "stopped" then
            if (TextInput.cursor_y > TextInput.cursor_select_y) or (TextInput.cursor_x > TextInput.cursor_select_x) then
                TextInput.cursor_x = TextInput.cursor_select_x
                TextInput.cursor_y = TextInput.cursor_select_y
                TextInput.cursor_x_tallest = TextInput.cursor_x
            end
            return
        end
        if Input.ctrl() then
            -- If we're at the start of a line, move to the end of the previous line.
            if TextInput.cursor_x == 0 then
                if TextInput.cursor_y == 1 then return end
                TextInput.cursor_y = TextInput.cursor_y - 1
                TextInput.cursor_x = StringUtils.len(TextInput.getCurrentLine())
            else
                TextInput.cursor_x = TextInput.getPreviousWordStart()
            end

            -- Maintain column position for vertical movement
            TextInput.cursor_x_tallest = TextInput.cursor_x
        else
            -- Not holding CTRL, just move to the left like normal
            if TextInput.cursor_x > 0 then
                TextInput.cursor_x = TextInput.cursor_x - 1
            else
                if TextInput.cursor_y ~= 1 then
                    TextInput.cursor_y = TextInput.cursor_y - 1
                    TextInput.cursor_x = StringUtils.len(TextInput.getCurrentLine())
                end
            end
        end
    elseif key == "right" then
        if TextInput.checkSelecting() == "stopped" then
            if (TextInput.cursor_y < TextInput.cursor_select_y) or (TextInput.cursor_x < TextInput.cursor_select_x) then
                TextInput.cursor_x = TextInput.cursor_select_x
                TextInput.cursor_y = TextInput.cursor_select_y
                TextInput.cursor_x_tallest = TextInput.cursor_x
            end
            return
        end
        if Input.ctrl() then
            -- If we're at the start of a line, move to the end of the previous line.
            if TextInput.cursor_x == StringUtils.len(TextInput.getCurrentLine()) then
                if TextInput.cursor_y == #TextInput.input then return end
                TextInput.cursor_y = TextInput.cursor_y + 1
                TextInput.cursor_x = 0
            end

            local position = TextInput.getNextWordEnd()
            TextInput.cursor_x = position
            TextInput.cursor_x_tallest = position
        else
            if TextInput.cursor_x < StringUtils.len(TextInput.getCurrentLine()) then
                TextInput.cursor_x = TextInput.cursor_x + 1
            else
                if TextInput.cursor_y ~= #TextInput.input then
                    TextInput.cursor_y = TextInput.cursor_y + 1
                    TextInput.cursor_x = 0
                end
            end
        end
        TextInput.cursor_x_tallest = TextInput.cursor_x
    end
end

--- The update function, to update the cursor timer.
---@internal
function TextInput.update()
    TextInput.flash_timer = TextInput.flash_timer + DT
    if TextInput.flash_timer > 1 then
        TextInput.flash_timer = TextInput.flash_timer - 1
    end

    TextInput.return_grace_timer = MathUtils.approach(TextInput.return_grace_timer, 0, DTMULT)
end

--- Get the start of the previous word.
---@return integer position # The start position of the previous word.
function TextInput.getPreviousWordStart()
    local position = TextInput.cursor_x
    local line = TextInput.getCurrentLine()

    -- We're already at the start of the line
    if position == 0 then
        return 0
    end

    local function get_char(pos)
        return StringUtils.sub(line, pos, pos)
    end

    -- Step 1: Pass whitespace immediately left of cursor
    while position > 0 and TextInput.isWhitespace(get_char(position)) do
        position = position - 1
    end

    -- Step 2: If we're not at the start, figure out what kind of word part we're in
    local current_type = TextInput.isPartOfWord(get_char(position))

    -- Step 3: Move left while the character matches the current type
    while position > 0 and TextInput.isPartOfWord(get_char(position)) == current_type do
        position = position - 1
    end

    return position
end

--- Get the end of the next word.
---@return integer position # The end position of the next word.
function TextInput.getNextWordEnd()
    local position = TextInput.cursor_x
    local line = TextInput.getCurrentLine()
    local line_len = StringUtils.len(line)

    if position >= line_len then
        return position
    end

    local function get_char(pos)
        return StringUtils.sub(line, pos, pos)
    end

    -- Step 1: Identify character type at cursor (or next char)
    local current_type = TextInput.isPartOfWord(get_char(position + 1))

    -- Step 2: Move right while characters are of the same type
    while position < line_len and TextInput.isPartOfWord(get_char(position + 1)) == current_type do
        position = position + 1
    end

    -- Step 3: Skip whitespace after that word
    while position < line_len and TextInput.isWhitespace(get_char(position + 1)) do
        position = position + 1
    end

    return position
end

---@param char string
---@return boolean
function TextInput.isWhitespace(char)
    return char == " " or char == "\t"
end

---@param char string
---@return boolean
---@internal
function TextInput.isPartOfWord(char)
    if char == "_" then return true end -- underscores are commonly used so we'll allow them in words
    if char == "-" then return true end -- same with dashes
    if char:match("%W") then return false end -- not alphanumeric, so not part of a word
    return true -- alphanumeric, so part of a word
end

--- Sends the cursor to the end of the input.
function TextInput.sendCursorToEnd()
    TextInput.cursor_y = #TextInput.input
    TextInput.sendCursorToEndOfLine()
end

--- Sends the cursor to the end of the current line.
function TextInput.sendCursorToEndOfLine()
    TextInput.cursor_x = StringUtils.len(TextInput.getCurrentLine())
    TextInput.cursor_x_tallest = TextInput.cursor_x
end

--- Sends the cursor to the start of the input.
function TextInput.sendCursorToStart()
    TextInput.cursor_x = 0
    TextInput.cursor_x_tallest = 0
    TextInput.cursor_y = 1
end

--- Sends the cursor to the start of the line. If to_indent is true, it will first go to the end of the indent.
---@param to_indent boolean? # Whether or not the cursor should go to the end of an indent first. Defaults to false.
function TextInput.sendCursorToStartOfLine(to_indent)
    if TextInput.cursor_x == 0 then
        TextInput.cursor_x_tallest = 0
        return
    end

    if to_indent then
        -- Loop through the utf8 string and find the end of an indent
        local last_space = 0
        for i = 1, StringUtils.len(TextInput.getCurrentLine()) do
            local char = StringUtils.sub(TextInput.getCurrentLine(), i, i)
            if TextInput.isWhitespace(char) then
                last_space = i
            else
                break
            end
        end
        -- We're not at the end of an indent, so send the cursor to it
        if TextInput.cursor_x ~= last_space then
            TextInput.cursor_x = last_space
            TextInput.cursor_x_tallest = TextInput.cursor_x
            return
        -- We're at the end of an indent, let's just go to the start
        end
    end
    TextInput.cursor_x = 0
    TextInput.cursor_x_tallest = 0
end

function TextInput.selectAll()
    TextInput.cursor_select_x = 0
    TextInput.cursor_select_y = 1
    TextInput.cursor_x = StringUtils.len(TextInput.input[#TextInput.input] or "")
    TextInput.cursor_y = #TextInput.input
    TextInput.selecting = true
end


function TextInput.removeSelection()
    if not TextInput.selecting then return end

    local in_front = false
    if TextInput.cursor_y > TextInput.cursor_select_y then
        in_front = true
    elseif TextInput.cursor_y == TextInput.cursor_select_y then
        if TextInput.cursor_x >= TextInput.cursor_select_x then
            in_front = true
        end
    end

    local start_x, start_y, end_x, end_y = 0, 0, 0, 0

    if in_front then
        start_x = TextInput.cursor_select_x
        start_y = TextInput.cursor_select_y
        end_x = TextInput.cursor_x
        end_y = TextInput.cursor_y
    else
        start_x = TextInput.cursor_x
        start_y = TextInput.cursor_y
        end_x = TextInput.cursor_select_x
        end_y = TextInput.cursor_select_y
    end

    if start_y == end_y then
        TextInput.input[start_y] = StringUtils.sub(TextInput.input[start_y] or "", 1, start_x) .. StringUtils.sub(TextInput.input[start_y] or "", end_x + 1)
    else
        local old_input = TableUtils.copy(TextInput.input)
        TableUtils.clear(TextInput.input)
        for i = 1, start_y - 1 do
            table.insert(TextInput.input, old_input[i])
        end

        for i = start_y, end_y do
            local text = old_input[i] or ""
            if i == start_y then
                text = StringUtils.sub(text, 1, start_x)
                table.insert(TextInput.input, text)
            elseif i == end_y then
                text = StringUtils.sub(text, end_x + 1)
                TextInput.input[start_y] = TextInput.input[start_y] .. text
            end
        end

        for i = end_y + 1, #old_input do
            table.insert(TextInput.input, old_input[i])
        end
    end

    TextInput.cursor_x = start_x
    TextInput.cursor_y = start_y
    TextInput.cursor_select_x = start_x
    TextInput.cursor_select_y = start_y
    TextInput.cursor_x_tallest = TextInput.cursor_x
    TextInput.selecting = false
end

---@return string
function TextInput.getCurrentLine()
    if TextInput.cursor_y < 1 or TextInput.cursor_y > #TextInput.input then
        return ""
    end
    return TextInput.input[TextInput.cursor_y] or ""
end

---@return string
function TextInput.getSelectedText()
    if not TextInput.selecting then return "" end

    local text = ""
    if TextInput.cursor_y == TextInput.cursor_select_y then
        if TextInput.cursor_x > TextInput.cursor_select_x then
            text = StringUtils.sub(TextInput.getCurrentLine(), TextInput.cursor_select_x + 1, TextInput.cursor_x)
        else
            text = StringUtils.sub(TextInput.getCurrentLine(), TextInput.cursor_x + 1, TextInput.cursor_select_x)
        end
    else
        if TextInput.cursor_y < TextInput.cursor_select_y then
            text = StringUtils.sub(TextInput.getCurrentLine(), TextInput.cursor_x + 1)
            for i = TextInput.cursor_y + 1, TextInput.cursor_select_y - 1 do
                text = text .. "\n" .. TextInput.input[i]
            end
            text = text .. "\n" .. StringUtils.sub(TextInput.input[TextInput.cursor_select_y] or "", 1, TextInput.cursor_select_x)
        else
            text = StringUtils.sub(TextInput.input[TextInput.cursor_select_y] or "", TextInput.cursor_select_x + 1)
            for i = TextInput.cursor_select_y + 1, TextInput.cursor_y - 1 do
                text = text .. "\n" .. TextInput.input[i]
            end
            text = text .. "\n" .. StringUtils.sub(TextInput.getCurrentLine(), 1, TextInput.cursor_x)
        end
    end

    return text
end

--- Insert a string where the cursor is currently positioned.
---
--- Used for pretty much everything which needs to insert text, like typing, pasting, etc.
---@param str string
function TextInput.insertString(str)

    if TextInput.text_restriction then
        local newstr = ""
        for i = 1, StringUtils.len(str) do
            local char = StringUtils.sub(str, i, i)
            local rest = TextInput.text_restriction(char)
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

    if TextInput.selecting then
        TextInput.removeSelection()
    end

    TextInput.flash_timer = 0
    local string_1 = StringUtils.sub(TextInput.getCurrentLine(), 1, TextInput.cursor_x)
    local string_2 = StringUtils.sub(TextInput.getCurrentLine(), TextInput.cursor_x + 1)

    if TextInput.cursor_x == 0 then
        string_1 = ""
        string_2 = TextInput.getCurrentLine()
    end

    local result
    if not TextInput.overtyping then
        result = string_1 .. str .. string_2
    else
        result = string_1 .. str .. StringUtils.sub(string_2, StringUtils.len(str) + 1)
    end

    local split = StringUtils.split(result, "\n", false)

    split[1] = split[1]:gsub("\n?$",""):gsub("\r","")

    TextInput.input[TextInput.cursor_y] = split[1]

    for i = 2, #split do
        split[i] = split[i]:gsub("\n?$",""):gsub("\r","")
        table.insert(TextInput.input, TextInput.cursor_y + i - 1, split[i])
    end

    if not TextInput.overtyping then
        TextInput.cursor_x = StringUtils.len(split[#split] or "") - StringUtils.len(string_2)
    else
        TextInput.cursor_x = StringUtils.len(split[#split] or "") - StringUtils.len(string_2) + StringUtils.len(str)
    end

    TextInput.cursor_x_tallest = TextInput.cursor_x
    TextInput.cursor_y = TextInput.cursor_y + #split - 1
end

---@class TextInput.drawOptions
---@field x number? # The X position to draw the text input at.
---@field y number? # The Y position to draw the text input at.
---@field font love.Font?
---@field get_prefix (fun(prefix:"single"|"start"|"end"|"middle"):string)?
---@field print fun(text:string, x:number, y:number)?
---@field cursor_color [number, number, number, number?]? # The color of the cursor.

--- Draw the current text input, with the cursor.
---@param options TextInput.drawOptions? # The options table. While optional, it won't be very pretty by default.
function TextInput.draw(options)
    love.graphics.push()

    options = options or {}

    local off_x = options["x"] or 0
    local off_y = options["y"] or 0
    local font = options["font"] or love.graphics.getFont()
    local get_prefix = options["get_prefix"] or function(prefix) return "" end
    local print_func = options["print"] or love.graphics.print
    local cursor_color = options["cursor_color"] or {0, 1, 1, 1}

    local base_off = (options["prefix_width"] or 0) + off_x

    local cursor_pos_x = base_off
    if TextInput.cursor_x > 0 then
        cursor_pos_x = font:getWidth(StringUtils.sub(TextInput.getCurrentLine(), 1, TextInput.cursor_x)) + cursor_pos_x
    end
    local cursor_pos_y = off_y + ((TextInput.cursor_y - 1) * font:getHeight())

    if TextInput.selecting then
        Draw.setColor(0, 0.5, 0.5, 1)

        local cursor_sel_x = base_off
        if TextInput.cursor_select_x > 0 then
            cursor_sel_x = font:getWidth(StringUtils.sub(TextInput.input[TextInput.cursor_select_y], 1, TextInput.cursor_select_x)) + cursor_sel_x
        end
        local cursor_sel_y = off_y + ((TextInput.cursor_select_y - 1) * font:getHeight())


        if TextInput.cursor_select_y == TextInput.cursor_y then
            local x = cursor_sel_x
            local y = cursor_sel_y + font:getHeight()
            local width = cursor_pos_x - x
            local height = cursor_pos_y + font:getHeight() - y - font:getHeight()

            love.graphics.rectangle("fill", x, y, width, height)
        else
            local in_front = false
            if TextInput.cursor_y > TextInput.cursor_select_y then
                in_front = true
            end

            if in_front then
                love.graphics.rectangle("fill", cursor_sel_x, cursor_sel_y, math.max(font:getWidth(TextInput.input[TextInput.cursor_select_y]) - cursor_sel_x + base_off, 1), font:getHeight())
                love.graphics.rectangle("fill", base_off, cursor_pos_y, cursor_pos_x - base_off, font:getHeight())

                for i = TextInput.cursor_select_y + 1, TextInput.cursor_y - 1 do
                    love.graphics.rectangle("fill", base_off, off_y + (font:getHeight() * (i - 1)), math.max(font:getWidth(TextInput.input[i]), 1), font:getHeight())
                end
            else
                love.graphics.rectangle("fill", cursor_pos_x, cursor_pos_y, math.max(font:getWidth(TextInput.getCurrentLine()) - cursor_pos_x + base_off, 1), font:getHeight())
                love.graphics.rectangle("fill", base_off, cursor_sel_y, cursor_sel_x - base_off, font:getHeight())

                for i = TextInput.cursor_y + 1, TextInput.cursor_select_y - 1 do
                    love.graphics.rectangle("fill", base_off, off_y + (font:getHeight() * (i - 1)), math.max(font:getWidth(TextInput.input[i]), 1), font:getHeight())
                end
            end
        end
    end

    Draw.setColor(1, 1, 1, 1)
    for i, text in ipairs(TextInput.input) do
        local prefix = ""
        if #TextInput.input == 1 then
            prefix = get_prefix("single")
        else
            if i == 1 then
                prefix = get_prefix("start")
            elseif i == #TextInput.input then
                prefix = get_prefix("end")
            else
                prefix = get_prefix("middle")
            end
        end
        print_func(prefix, off_x, off_y + (i - 1) * font:getHeight())
        print_func(text, base_off, off_y + (i - 1) * font:getHeight())
    end

    Draw.setColor(cursor_color)
    if TextInput.flash_timer < 0.5 and TextInput.active then
        local char_width = font:getWidth("M")

        love.graphics.setLineWidth((char_width > 8) and 2 or 1)
        love.graphics.setLineStyle("rough")
        love.graphics.setLineJoin("none")


        if TextInput.overtyping or ((not TextInput.selecting) and (TextInput.cursor_x == StringUtils.len(TextInput.getCurrentLine()))) then
            love.graphics.line(cursor_pos_x, cursor_pos_y + font:getHeight(), cursor_pos_x + char_width, cursor_pos_y + font:getHeight())
        else
            love.graphics.line(cursor_pos_x + 1, cursor_pos_y, cursor_pos_x + 1, cursor_pos_y + font:getHeight())
        end
    end

    love.graphics.pop()
end

return TextInput
