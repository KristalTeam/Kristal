---@class Console : Object
---@overload fun(...) : Console
local Console, super = Class(Object)

function Console:init()
    super.init(self, 0, 0)

    self.logger = Logger("Console", ConsoleFormats.YELLOW)

    self.layer = 10000000 - 1

    self.height = 12

    self.font_size = 16
    self.font_name = "main_mono"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.history = {}

    self.read_offset = 0

    self:push({"Welcome to ", { 0.5, 1, 1, 1 }, "KRISTAL", COLORS.white, "! This is the debug console."})
    self:push({"You can enter Lua here to be ran! Use ", COLORS.ltgray, "help()", COLORS.white, " to open the help menu."})
    self:push("")

    self.command_history = {}

    self.input = { "" }

    self.is_open = false

    self.history_index = 0

    self:close()

    self.env = self:createEnv()

    Logging.registerListener(ConsoleOutputListener())
end

function Console:update()
    self.env:update()

    local delta = Input.getScrollDeltaY()

    if delta ~= 0 then
        -- Specifically mouse wheel is clamped

        self.read_offset = self.read_offset - delta
        self.read_offset = math.max(self.read_offset, -#self.history + self.height)
        self.read_offset = math.min(self.read_offset, 0)
    end
end

function Console:createEnv()
    local env = {}

    function env.update()

    end

    function env.print(...)
        local arg = { n = select("#", ...), ... }
        local print_string = ""

        for i = 1, arg.n do
            local str = arg[i]
            if type(str) == "table" then
                str = TableUtils.dump(str)
            end
            print_string = print_string .. tostring(str)
            if i ~= arg.n then
                print_string = print_string .. "    "
            end
        end
        self.logger:debug(print_string)
    end

    function env.help()
        local yellow = { 1, 1, 0.5, 1 }
        local gray = COLORS.ltgray
        local white = COLORS.white

        self:push({ { 0.5, 1, 1, 1 }, "KRISTAL", white, " help menu:"})
        self:push({ yellow, "Commands:"})
        self:push({"clear()", gray, " - Clears the console."})
        self:push({"stack()", gray, " - Shows the stack traceback."})
        self:push({"move(", yellow, "int", white, ")", gray, " - Move the cursor ", yellow, "int", gray, " amount of lines."})
        self:push({"moveTo(", yellow, "int", white, ")", gray, " - Move the cursor to line ", yellow, "int", gray, "."})
        self:push({"resetPos()", gray, " - Move the cursor to the last line."})
        self:push({"giveItem(", yellow, "str", white, ")", gray, " - Attempts to give item with ID ", yellow, "str", gray, "."})
        self:push({""})
        self:push({yellow, "Controls:"})
        self:push({"Arrow keys / scroll wheel", gray, " - Move cursor."})
        self:push({"Up/Down", gray, " - Move through command history."})
        self:push({"Ctrl + Up/Down", gray, " - Scroll the console."})
        self:push({"Shift + Enter", gray, " - New line."})
    end

    function env.clear()
        self.history = {}
    end

    function env.stack()
        self.logger:warn(debug.traceback())
    end

    function env.move(amt)
        self.read_offset = self.read_offset + (amt or 0)
    end

    function env.moveTo(line)
        self.read_offset = -#self.history + (line or 0)
    end

    function env.resetPos()
        self.read_offset = 0
    end

    function env.giveItem(str)
        local success, result_text = Game.inventory:tryGiveItem(str)
        if success then
            self.logger:info("Item has been added")
        else
            self.logger:warn("Unable to add item (inventory full?)")
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

function Console:onRemoveFromStage()
    TextInput.endInput()
end

function Console:open()
    self.is_open = true
    OVERLAY_OPEN = true
    self.history_index = #self.command_history + 1

    TextInput.attachInput(self.input, {
        multiline = true,
        enter_submits = true,
    })
    TextInput.submit_callback = function() self:onSubmit() end
    TextInput.up_limit_callback = function() self:onUpLimit() end
    TextInput.down_limit_callback = function() self:onDownLimit() end
    TextInput.pressed_callback = function(key) self:onConsoleKeyPressed(key) end
    TextInput.escape_callback = function() self:close() end
end

function Console:onUpLimit()
    if Input.ctrl() then
        self.read_offset = self.read_offset - 1
        return
    end
    if #self.command_history == 0 then return end
    if self.history_index > 1 then
        self.history_index = self.history_index - 1
        self.input = TableUtils.copy(self.command_history[self.history_index] or { "" })
        TextInput.updateInput(self.input)
        TextInput.selecting = false
        TextInput.sendCursorToEnd()
    end
end

function Console:onDownLimit()
    if Input.ctrl() then
        self.read_offset = self.read_offset + 1
        return
    end
    if #self.command_history == 0 then return end
    if self.history_index == #self.command_history + 1 then
        -- Empty
    else
        self.history_index = self.history_index + 1
        self.input = TableUtils.copy(self.command_history[self.history_index] or { "" })
        TextInput.updateInput(self.input)
        TextInput.selecting = false
        TextInput.sendCursorToEnd()
    end
    TextInput.sendCursorToEndOfLine()
end

function Console:onSubmit()
    self:run(self.input)
    self.env.resetPos()
end

function Console:close()
    self.is_open = false
    OVERLAY_OPEN = false
    TextInput.endInput()
end

function Console:print(text, x, y, align)
    if text == nil then
        return
    end
    align = align or 'left'

    local x_offset = 0

    if align == 'right' then
        love.graphics.setColor(1, 0, 1, 1)
        x = SCREEN_WIDTH - x
        for _, line in ipairs(text) do
            x_offset = x_offset + self.font:getWidth(line)
            x = x - self.font:getWidth(line)
        end
    end

    for _, line in ipairs(text) do
        Draw.setColor(self.color)
        if type(line) == "table" then
            self.color = line
        else
            if align == 'right' then
                x_offset = x_offset - self.font:getWidth(line)
            end
            self:printOutlined(line, x + x_offset, y)
            if align == 'left' then
                x_offset = x_offset + self.font:getWidth(line)
            end
        end
    end
end

function Console:printOutlined(text, x, y )
    if y < 0 then
        return
    end

    local r, g, b, a = love.graphics.getColor()
    Draw.setColor(r / 2, g / 2, b / 2, a / 2)

    love.graphics.print(text, x + 1, y)
    love.graphics.print(text, x - 1, y)
    love.graphics.print(text, x, y + 1)
    love.graphics.print(text, x, y - 1)

    Draw.setColor(r, g, b, a)

    love.graphics.print(text, x, y)
end

function Console:draw()
    if not self.is_open then return end

    local line_height = 18
    love.graphics.setFont(self.font)

    Draw.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, 480)

    local input_pos = (self.height + 1) * line_height

    Draw.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, (self.height) * line_height)

    Draw.setColor(1, 1, 1, 1)

    local y_offset = self.height

    self.color = { 1, 1, 1, 1 }

    for line = #self.history - self.height, #self.history do
        --local lines = Utils.split(self.history[line] or "", "\n", false)
        y_offset = y_offset - 1
    end

    for line = #self.history - self.height, #self.history do
        self.color = { 1, 1, 1, 1 }
        self:print(self.history[line + self.read_offset] or { COLORS.gray, "~" }, 8, y_offset * line_height)
        y_offset = y_offset + 1
    end

    self.color = { 1, 1, 1, 1 }
    self:print({("Line %d of %d"):format(# self.history + self.read_offset, #self.history)}, 8, y_offset * line_height, 'right')
    --y_offset = y_offset + 1

    self.color = { 1, 1, 1, 1 }

    Draw.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, input_pos, SCREEN_WIDTH, #self.input * line_height)

    TextInput.draw({
        prefix_width = self.font:getWidth("> "),
        get_prefix = function(place)
            if place == "start" then return "┌ " end
            if place == "middle" then return "│ " end
            if place == "end" then return "└ " end
            if place == "single" then return "> " end
            return "  "
        end,
        x = 8,
        y = input_pos,
        print = function(text, x, y)
            self:print({ text }, x, y)
        end,
        font = self.font
    })

    Draw.setColor(1, 1, 1, 1)

    -- FOR DEBUGGING HISTORY:
    --[[offset = 0
    for i, v in ipairs(self.command_history) do
        if i == self.history_index then
            Draw.setColor(1, 0, 0, 1)
        else
            Draw.setColor(1, 1, 1, 1)
        end
        for j, text in ipairs(v) do
            offset = offset + 1
            self:print(text, 8, 200 + ((offset) * 16), true)
        end
    end]]

    super.draw(self)
end

-- begin mini text engine

--- An internal class for keeping track of the state of text wrapping in the console.
---@class ConsoleTextState
---@field lines table The lines of text that have been wrapped so far
---@field line table The current line of text being built
---@field width number The width of the current line
---@field max_width number The maximum width of any line so far
---@field color table? The current color being used for text
---@field pending_space string The whitespace that has been seen but not yet added to the current line
---@field wrap_limit number The maximum width of a line before wrapping
---@field font love.Font The font being used


---@param state ConsoleTextState
local function finish_line(state)
    state.max_width = math.max(state.max_width, state.width)
    table.insert(state.lines, state.line)

    state.line = {}

    if state.color then
        table.insert(state.line, state.color)
    end

    state.width = 0
    state.pending_space = ""
end

---@param state ConsoleTextState
---@param text string
local function add_piece(state, text)
    if text == "" then
        return
    end

    table.insert(state.line, text)
    state.width = state.width + state.font:getWidth(text)
end

---@param state ConsoleTextState
---@param word string
local function hard_wrap(state, word)
    local remaining = word

    while remaining ~= "" do
        local available = state.wrap_limit - state.width

        if available <= 0 then
            finish_line(state)
            available = state.wrap_limit
        end

        local piece_width = 0
        local last_valid_byte = 0

        for byte_start, codepoint in utf8.codes(remaining) do
            local character = utf8.char(codepoint)
            local character_width = state.font:getWidth(character)

            if piece_width + character_width > available then
                break
            end

            piece_width = piece_width + character_width
            last_valid_byte = byte_start + #character - 1
        end

        -- okay so this character is wider than the available space
        if last_valid_byte == 0 then
            local next_char_boundary = utf8.offset(remaining, 2) or (#remaining + 1)
            local character = remaining:sub(1, next_char_boundary - 1)

            add_piece(state, character)
            remaining = remaining:sub(next_char_boundary)

            if remaining ~= "" then
                finish_line(state)
            end
        else
            local piece = remaining:sub(1, last_valid_byte)
            add_piece(state, piece)
            remaining = remaining:sub(last_valid_byte + 1)

            if remaining ~= "" then
                finish_line(state)
            end
        end
    end
end

---@param state ConsoleTextState
---@param word string
local function add_word(state, word)
    if word == "" then
        return
    end

    local space_width = state.font:getWidth(state.pending_space)
    local word_width = state.font:getWidth(word)

    -- word fits on current line
    if state.width + space_width + word_width <= state.wrap_limit then
        add_piece(state, state.pending_space)

        state.pending_space = ""

        add_piece(state, word)
        return
    end

    -- word doesnt fit on this line, but it will on a new line
    if word_width <= state.wrap_limit then
        state.pending_space = ""
        finish_line(state)
        add_piece(state, word)
        return
    end

    -- word is too large, so hard-wrap
    state.pending_space = ""

    if state.width > 0 then
        finish_line(state)
    end

    hard_wrap(state, word)
end

--- add text to the console, handling whitespace and wrapping
---@param state ConsoleTextState
---@param text string
---@param preserve_leading_space boolean
local function add_text(state, text, preserve_leading_space)
    local pos = 1

    while pos <= #text do
        local whitespace_start, whitespace_end = text:find("%s+", pos)

        if whitespace_start == pos then
            local whitespace = text:sub(whitespace_start, whitespace_end)

            if preserve_leading_space and state.width == 0 then
                -- whitespace follows an explicit newline, so keep it
                add_piece(state, whitespace)
            else
                -- dont commit whitespace until we know the next word fits on this line
                state.pending_space = state.pending_space .. whitespace
            end

            pos = whitespace_end + 1
        else
            local word_end = text:find("%s", pos) or (#text + 1)
            local word = text:sub(pos, word_end - 1)

            add_word(state, word)

            preserve_leading_space = false
            pos = word_end
        end
    end
end

--- responsible for adding text to the console, handling newlines and wrapping
---@param state ConsoleTextState
---@param text string
local function add_formatted_text(state, text)
    local start = 1
    local after_newline = false

    while true do
        local newline = text:find("\n", start, true)

        if not newline then
            add_text(state, text:sub(start), after_newline)
            break
        end

        add_text(state, text:sub(start, newline - 1), after_newline)

        -- explicit newline, so preserve whitespace
        state.pending_space = ""
        finish_line(state)

        after_newline = true
        start = newline + 1
    end
end

---
--- Like LÖVE's `Font:getWrap`, but keeps formatting
---
---@param tbl table The text to wrap, as a table of strings and formatting tables.
---@param wrap_limit number The width to wrap at.
---@return number width The width of the wrapped text
---@return table lines The wrapped text, as a table of lines, each line being a table of strings and formatting tables.
function Console:getWrappedLines(tbl, wrap_limit)
    -- okay begin the horrors
    -- this is a mini text wrapping engine

    ---@type ConsoleTextState
    local state = {
        lines = {},
        line = {},
        width = 0,
        max_width = 0,
        color = nil,
        pending_space = "",
        wrap_limit = wrap_limit,
        font = self.font
    }

    for _, part in ipairs(tbl) do
        if type(part) == "table" then
            state.color = part
            table.insert(state.line, part)
        else
            add_formatted_text(state, part)
        end
    end

    -- whitespace at the end of the input should be kept
    if state.pending_space ~= "" then
        add_piece(state, state.pending_space)
    end

    state.max_width = math.max(state.max_width, state.width)
    table.insert(state.lines, state.line)

    return state.max_width, state.lines
end

function Console:push(str)
    if str == nil then
        return
    end

    if type(str) == "table" then
        -- This is a fancy formatting table, so let's wrap it

        local _, wrappedtext = self:getWrappedLines(str, SCREEN_WIDTH - 16)
        for _, line in ipairs(wrappedtext) do
            table.insert(self.history, line)
        end

        return
    end

    local _, lines = self.font:getWrap(str, SCREEN_WIDTH - 16)

    for _, line in ipairs(lines) do
        table.insert(self.history, { line })
    end
end

function Console:parseLegacyFormatting(str)
    local color = {}
    local text = { color }
    local current = ""
    local in_modifier = false
    local modifier_text = ""
    local disable_modifiers = false

    ---@diagnostic disable-next-line: undefined-field
    for char in str:gmatch(utf8.charpattern) do
        if char == "[" and (not disable_modifiers) then
            table.insert(text, current)
            current = ""
            in_modifier = true
        elseif char == "]" and in_modifier then
            current = ""
            in_modifier = false
            local modifier = StringUtils.split(modifier_text, ":", false)
            if modifier[1] == "color" then
                color = { 1, 1, 1, 1 }
                if modifier[2] then
                    if StringUtils.startsWith(modifier[2], "#") then
                        color = ColorUtils.hexToRGB(modifier[2])
                    elseif modifier[2] == "cyan" then
                        color = { 0.5, 1, 1, 1 }
                    elseif modifier[2] == "white" then
                        color = { 1, 1, 1, 1 }
                    elseif modifier[2] == "yellow" then
                        color = { 1, 1, 0.5, 1 }
                    elseif modifier[2] == "red" then
                        color = { 1, 0.5, 0.5, 1 }
                    elseif modifier[2] == "gray" then
                        color = { 0.8, 0.8, 0.8, 1 }
                    end
                end

                table.insert(text, color)
            elseif modifier[1] == "nomods" then
                disable_modifiers = true
            else
                modifier_text = "[" .. modifier_text .. "]"
                table.insert(text, modifier_text)
            end
            modifier_text = ""
        elseif in_modifier then
            modifier_text = modifier_text .. char
        else
            current = current .. char
        end
    end

    table.insert(text, current)

    return text
end

---@deprecated
function Console:log(str)
    Kristal.markDeprecated(2, "Kristal.Console:log", "method", "replaced", "Logging.info")

    print("[CONSOLE] " .. tostring(str))
    self:push(self:parseLegacyFormatting(str))
end

---@deprecated
function Console:warn(str)
    Kristal.markDeprecated(2, "Kristal.Console:warn", "method", "replaced", "Logging.warn")

    print("[WARNING] " .. tostring(str))
    self:push(self:parseLegacyFormatting("[color:yellow][WARNING] " .. tostring(str)))
end

---@deprecated
function Console:error(str)
    Kristal.markDeprecated(2, "Kristal.Console:error", "method", "replaced", "Logging.error")

    print("[ERROR] " .. tostring(str))
    self:push(self:parseLegacyFormatting("[color:red][ERROR] " .. tostring(str)))
end

function Console:stripError(str)
    return string.match(str, '.+:%d+: (.+)')
end

function Console:run(str)
    if not Utils.equal(str, self.command_history[#self.command_history]) then
        table.insert(self.command_history, TableUtils.copy(str))
    end
    self.history_index = #self.command_history + 1
    local run_string = ""
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
            run_string     = run_string .. line
        else
            run_string     = run_string .. line .. "\n"
        end

        self:push({ COLORS.ltgray, prefix, line })
    end

    if StringUtils.startsWith(run_string, "=") then
        run_string = "print(" .. StringUtils.sub(run_string, 2) .. ")"
    end
    local status, err = pcall(function() self:unsafeRun(run_string) end)
    if (not status) and err then
        self.logger:error(self:stripError(err))
        print(err)
    end
end

function Console:unsafeRun(str)
    local chunk, err = loadstring(str)
    if chunk then
        rawset(self.env, "selected", Kristal.DebugSystem.object)
        rawset(self.env, "_", Kristal.DebugSystem.object)
        setfenv(chunk, self.env)
        local ret = chunk()
        if ret ~= nil then
            self.logger:debug()
        end
    else
        self.logger:error(self:stripError(err))
    end
end

function Console:onConsoleKeyPressed(key)
    if not Input.shouldProcess(key) then return end

    if Input.is("console", key) and not Input.shift() then
        Input.clear("console")
        if self.is_open then
            self:close()
        else
            return true
        end
        return true
    end
end

return Console
