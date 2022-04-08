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
        ""
    }

    self.command_history = {}

    self.input = ""

    self.is_open = false

    self.history_index = 0

    self.cursor = 0

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
    self.cursor = utf8.len(self.input)
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

    local y_offset = self.height - #self.history

    for line, text in ipairs(self.history) do
        self:print(text, 8, y_offset * 16)
        y_offset = y_offset + 1
        if y_offset >= self.height then
            break
        end
    end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, input_pos, 640, 16)

    love.graphics.setColor(1, 1, 1, 1)
    self:print("> " .. self.input, 8, input_pos)

    love.graphics.setColor(1, 0, 1, 1)
    local cursor_pos = self.font:getWidth("> ")
    if self.cursor > 0 then
        cursor_pos = self.font:getWidth(string.sub(self.input, 1, utf8.offset(self.input, self.cursor))) + cursor_pos
    end
    self:print("_", 8 + cursor_pos, input_pos)

    love.graphics.setColor(1, 1, 1, 1)
    super:draw(self)
end

function Console:textinput(t)
    if not self.is_open then return end
    self:insertString(t)
end

function Console:insertString(str)
    local string_1 = string.sub(self.input, 1, utf8.offset(self.input, self.cursor))
    local string_2 = string.sub(self.input, utf8.offset(self.input, self.cursor) + 1, -1)

    self.input = string_1 .. str .. string_2
    self.cursor = self.cursor + utf8.len(str)
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
    return string.match(str, '.+:1: (.+)')
end

function Console:run(str)
    if str ~= self.command_history[#self.command_history] then
        table.insert(self.command_history, str)
    end
    self.history_index = #self.command_history + 1
    self:push({{0.8, 0.8, 0.8}, "> " .. str})
    local status, error = pcall(function() self:unsafeRun(str) end)
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
        self:run(self.input)
        self.input = ""
        self.cursor = 0
    elseif key == "backspace" then
        if self.cursor == 0 then return end

        local string_1 = string.sub(self.input, 1, utf8.offset(self.input, self.cursor))
        local string_2 = string.sub(self.input, utf8.offset(self.input, self.cursor) + 1, -1)

        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(string_1, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            string_1 = string.sub(string_1, 1, byteoffset - 1)
            self.cursor = utf8.len(string_1)
        end
        self.input = string_1 .. string_2
    elseif key == "up" then
        if #self.command_history == 0 then return end
        if self.history_index > 1 then
            self.history_index = self.history_index - 1
            self.input = self.command_history[self.history_index]
            self.cursor = utf8.len(self.input)
        end
    elseif key == "down" then
        if #self.command_history == 0 then return end
        if self.history_index < #self.command_history + 1 then
            self.history_index = self.history_index + 1
            self.input = self.command_history[self.history_index]
        end
        if self.history_index == #self.command_history + 1 then
            self.input = ""
        end
        self.cursor = utf8.len(self.input)
    elseif key == "left" then
        if self.cursor > 0 then
            self.cursor = self.cursor - 1
        end
    elseif key == "right" then
        if self.cursor < utf8.len(self.input) then
            self.cursor = self.cursor + 1
        end
    end
end

return Console