---@class Console : Object
---@overload fun(...) : Console
local Console, super = Class(Object)

function Console:init()
    super.init(self, 0, 0)
    self.layer = 10000000 - 1

    self.height = 12

    self.font_size = 16
    self.font_name = "main_mono"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.history = {}

    self:push("Welcome to [color:cyan]KRISTAL[color:reset]! This is the debug console.")
    self:push("You can enter Lua here to be ran! Use [color:gray]clear()[color:reset] to clear the console.")
    self:push("")

    self.command_history = {}

    self.input = {""}

    self.is_open = false

    self.history_index = 0

    self:close()

    self.env = self:createEnv()
end

function Console:update()
    self.env:update()
end

function Console:createEnv()
    local env = {}

    function env.update()

    end

    function env.print(...)
        local arg = {...}
        local print_string = ""

        for i, str in ipairs(arg) do
            if type(str) == "table" then
                str = Utils.dump(str)
            end
            print_string = print_string .. tostring(str)
            if i ~= #arg then
                print_string = print_string  .. "    "
            end
        end
        self:log(print_string)
    end

    function env.clear()
        self.history = {}
    end

    function env.stack()
        self:warn(debug.traceback())
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
end

function Console:onUpLimit()
    if #self.command_history == 0 then return end
    if self.history_index > 1 then
        self.history_index = self.history_index - 1
        self.input = Utils.copy(self.command_history[self.history_index] or {""})
        TextInput.updateInput(self.input)
        TextInput.selecting = false
        TextInput.sendCursorToEnd()
    end
end

function Console:onDownLimit()
    if #self.command_history == 0 then return end
    if self.history_index == #self.command_history + 1 then
        -- Empty
    else
        self.history_index = self.history_index + 1
        self.input = Utils.copy(self.command_history[self.history_index] or {""})
        TextInput.updateInput(self.input)
        TextInput.selecting = false
        TextInput.sendCursorToEnd()
    end
    TextInput.sendCursorToEndOfLine()
end

function Console:onSubmit()
    self:run(self.input)
end

function Console:close()
    self.is_open = false
    OVERLAY_OPEN = false
    TextInput.endInput()
end

function Console:print(text, x, y)

    if text == nil then return end

    local x_offset = 0

    local color = {1, 1, 1, 1}

    for _,line in ipairs(text) do
        Draw.setColor(color)
        if type(line) == "table" then
            color = line
        else
            self:printOutlined(line, x + x_offset, y)
            x_offset = x_offset + self.font:getWidth(line)
        end
    end
end

function Console:printOutlined(text, x, y)
    if y < 0 then return end
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
    love.graphics.setFont(self.font)

    Draw.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    local input_pos = (self.height + 1) * 16

    Draw.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 640, self.height * 16)

    Draw.setColor(1, 1, 1, 1)

    local y_offset = self.height

    for line = #self.history - self.height, #self.history do
        --local lines = Utils.split(self.history[line] or "", "\n", false)
        y_offset = y_offset - 1
    end

    for line = #self.history - self.height, #self.history do
        self:print(self.history[line] or {""}, 8, y_offset * 16)
        y_offset = y_offset + 1
    end


    Draw.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, input_pos, 640, #self.input * 16)

    TextInput.draw({
        prefix_width = self.font:getWidth("> "),
        get_prefix = function(place)
            if place == "start"  then return "┌ " end
            if place == "middle" then return "│ " end
            if place == "end"    then return "└ " end
            if place == "single" then return "> " end
            return "  "
        end,
        x = 8,
        y = input_pos,
        print = function(text, x, y)
            self:print({text}, x, y)
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

function Console:push(str)
    if str == nil then return end

    for _,line in ipairs(Utils.split(str, "\n", false)) do
        local text = {}
        local current = ""
        local in_modifier = false
        local modifier_text = ""

        ---@diagnostic disable-next-line: undefined-field
        for char in line:gmatch(utf8.charpattern) do
            if char == "[" then
                table.insert(text, current)
                current = ""
                in_modifier = true
            elseif char == "]" and in_modifier then
                current = ""
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
                    table.insert(text, color)
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

        table.insert(self.history, text)
    end
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
        table.insert(self.command_history, Utils.copy(str))
    end
    self.history_index = #self.command_history + 1
    local run_string = ""
    local history_string = ""
    for i, line in ipairs(str) do
        local prefix = "[color:gray]> "

        if #str > 1 then
            if i == 1 then
                prefix = "[color:gray]┌ "
            elseif i == #str then
                prefix = "[color:gray]└ "
            else
                prefix = "[color:gray]│ "
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
    if Utils.startsWith(run_string, "=") then
        run_string = "print(" .. Utils.sub(run_string, 2) .. ")"
    end
    local status, err = pcall(function() self:unsafeRun(run_string) end)
    if (not status) and err then
        self:error(self:stripError(err))
        print(err)
    end
end

function Console:unsafeRun(str)
    local chunk, err = loadstring(str)
    if chunk then
        self.env.selected = Kristal.DebugSystem.object
        self.env["_"] = Kristal.DebugSystem.object
        setfenv(chunk,self.env)
        self:push(chunk())
    else
        self:error(self:stripError(err))
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