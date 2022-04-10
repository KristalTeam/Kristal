local Console, super = Class(Object)

function Console:init()
    super:init(self, 0, 0)
    self.layer = 10000000

    self.height = 12

    self.font_size = 16
    self.font_name = "main"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.history = {
        {"Welcome to ", {0.5, 1, 1}, "KRISTAL", {1, 1, 1}, "! This is the debug console. You can enter Lua here to be ran!"},
        "",
    }

    self.command_history = {}

    self.input = {""}

    self.is_open = false

    self.history_index = 0

    self.cursor_x = 0
    self.cursor_y = 1
    self.cursor_y_tallest = 1

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

function Console:print(text, x, y)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(r / 2, g / 2, b / 2, a / 2)

    love.graphics.print(text, x + 1, y)
    love.graphics.print(text, x - 1, y)
    love.graphics.print(text, x, y + 1)
    love.graphics.print(text, x, y - 1)

    love.graphics.setColor(r, g, b, a)

    love.graphics.print(text, x, y)
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
        y_offset = y_offset - #Utils.split(Utils.coloredToString(text), "\n", false)
    end

    for line, text in ipairs(self.history) do
        self:print(text, 8, y_offset * 16)
        y_offset = y_offset + #Utils.split(Utils.coloredToString(text), "\n", false)
        if y_offset >= self.height then
            break
        end
    end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, input_pos, 640, #self.input * 16)

    love.graphics.setColor(1, 1, 1, 1)
    for i, text in ipairs(self.input) do
        self:print("> " .. text, 8, input_pos + (i - 1) * 16)
    end

    love.graphics.setColor(1, 0, 1, 1)
    local cursor_pos = self.font:getWidth("> ")
    if self.cursor_x > 0 then
        cursor_pos = self.font:getWidth(string.sub(self.input[self.cursor_y], 1, utf8.offset(self.input[self.cursor_y], self.cursor_x))) + cursor_pos
    end

    if self.flash_timer < 0.5 then
        if self.cursor_x == utf8.len(self.input[self.cursor_y]) then
            self:print("_", 8 + cursor_pos, input_pos + ((self.cursor_y - 1) * 16))
        else
            self:print("|", 8 + cursor_pos - 1, input_pos + ((self.cursor_y - 1) * 16))
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    super:draw(self)
end

function Console:textinput(t)
    if not self.is_open then return end
    self:insertString(t)
end

function Console:insertString(str)
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
    self.cursor_y = self.cursor_y + #split - 1
    --self.cursor_x = self.cursor_y + utf8.len(str)
end

function Console:push(str)
    table.insert(self.history, str)
end

function Console:log(str)
    print("[CONSOLE]" .. tostring(str))
    self:push(str)
end

function Console:warn(str)
    print("[WARNING]" .. tostring(str))
    self:push({{1, 1, 0.5}, "[WARNING] " .. tostring(str)})
end

function Console:error(str)
    print("[ERROR]" .. tostring(str))
    self:push({{1, 0.5, 0.5}, "[ERROR] " .. tostring(str)})
end

function Console:stripError(str)
    return string.match(str, '.+:%d+: (.+)')
end

function Console:run(str)
    if str ~= self.command_history[#self.command_history] then
        table.insert(self.command_history, str)
    end
    self.history_index = #self.command_history + 1
    local run_string = ""
    for i, line in ipairs(str) do
        if i == #str then
            run_string = run_string .. line
        else
            run_string = run_string .. line .. "\n"
        end
    end
    self:push({{0.8, 0.8, 0.8}, "> " .. run_string})
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

    if (key == "v") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        self:insertString(love.system.getClipboardText())
    elseif key == "return" then
        if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            self:insertString("\n")
        else
            self:run(self.input)
            self.input = {""}
            self.cursor_x = 0
            self.cursor_y = 1
            self.flash_timer = 0
        end
    elseif key == "tab" then
        self:insertString("    ")
    elseif key == "backspace" then
        self.flash_timer = 0
        if self.cursor_x == 0 and self.cursor_y == 1 then return end

        if self.cursor_x == 0 then
            self.cursor_y = self.cursor_y - 1
            self.cursor_x = utf8.len(self.input[self.cursor_y])
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
            end
            self.input[self.cursor_y] = string_1 .. string_2
        end
    elseif key == "up" then
        self.flash_timer = 0
        if self.cursor_y <= 1 then
            self.cursor_y = 1
            if #self.command_history == 0 then return end
            if self.history_index > 1 then
                self.history_index = self.history_index - 1
                self.input = self.command_history[self.history_index]
                self.cursor_x = utf8.len(self.input[#self.input])
                self.cursor_y = #self.input
            end
        else
            self.cursor_y = self.cursor_y - 1
            self.cursor_x = utf8.len(self.input[self.cursor_y])
        end
    elseif key == "down" then
        self.flash_timer = 0
        if self.cursor_y == #self.input then
            if #self.command_history == 0 then return end
            if self.history_index == #self.command_history + 1 then

            else
                self.history_index = self.history_index + 1
                self.input = self.command_history[self.history_index] or {""}
                self.cursor_x = utf8.len(self.input[#self.input])
                self.cursor_y = #self.input
            end
            self.cursor_x = utf8.len(self.input[self.cursor_y])
        else
            self.cursor_y = self.cursor_y + 1
            self.cursor_x = utf8.len(self.input[self.cursor_y])
        end
    elseif key == "left" then
        self.flash_timer = 0
        if self.cursor_x > 0 then
            self.cursor_x = self.cursor_x - 1
        else
            if self.cursor_y ~= 1 then
                self.cursor_y = self.cursor_y - 1
                self.cursor_x = utf8.len(self.input[self.cursor_y])
            end
        end
        self.flash_timer = 0
    elseif key == "right" then
        if self.cursor_x < utf8.len(self.input[self.cursor_y]) then
            self.cursor_x = self.cursor_x + 1
        else
            if self.cursor_y ~= #self.input then
                self.cursor_y = self.cursor_y + 1
                self.cursor_x = 0
            end
        end
    end
end

return Console