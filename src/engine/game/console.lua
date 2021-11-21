local Console, super = Class(Object)

function Console:init()
    super:init(self, 0, 0)
    self.layer = 10000000

    self.height = 12

    self.font_size = 16
    self.font_name = "main"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.history = {
        "Welcome to KRISTAL! This is the debug console. You can enter Lua here to be ran!",
        ""
    }

    self.input = ""

    self.is_open = false

    self:close()

    self.env = self:createEnv()
end

function Console:createEnv()
    local env = {}

    function env.print(str)
        print(str)
        self:log(str)
    end

    function env.giveItem(str)
        local success, result_text = Game.inventory:tryGiveItem(str)
        if success then
            self:log("Item has been added")
        else
            self:log("Unable to add item (inventory full?)")
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

    super:draw(self)
end

function Console:textinput(t)
    if not self.is_open then return end
    self.input = self.input .. t
end

function Console:push(str)
    table.insert(self.history, str)
end

function Console:log(str)
    self:push(str)
end

function Console:run(str)
    self:push("> " .. str)
    local status, error = pcall(function() self:unsafeRun(str) end)
    if not status then
        self:push(error)
    end
end

function Console:unsafeRun(str)
    local chunk, error = loadstring(str)
    if chunk then
        setfenv(chunk,self.env)
        self:push(chunk())
    else
        self:push(error)
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

    if key == "return" then
        self:run(self.input)
        self.input = ""
    end
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(self.input, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            self.input = string.sub(self.input, 1, byteoffset - 1)
        end
    end
end

return Console