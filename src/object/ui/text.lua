local Text, super = Class(Object)

Text.COLORS = {
    ["red"] = COLORS.red,
    ["blue"] = COLORS.blue,
    ["yellow"] = COLORS.yellow,
    ["green"] = COLORS.lime,
    ["white"] = COLORS.white,
    ["black"] = COLORS.black,
    ["purple"] = COLORS.purple,
    ["maroon"] = COLORS.maroon,
    ["pink"] = {1, 0.5, 1},
    ["lime"] = {0.5, 1, 0.5}
}

function Text:init(text, x, y, w, h, font, style)
    super:init(self, x, y, w or SCREEN_WIDTH, h or SCREEN_HEIGHT)

    self.font = font or "main"
    self.style = style
    self.wrap = true
    self.canvas = love.graphics.newCanvas(w, h)
    self.line_offset = 0

    self:resetState()

    self:setText(text)
end

function Text:resetState()
    self.state = {
        color = {1, 1, 1, 1},
        font = self.font,
        current_x = 0,
        current_y = 0,
        typed_characters = 0,
        progress = 1,
        current_node = 1,
        typing = true,
        speed = 1,
        waiting = 0,
        skipping = false,
        asterisk_mode = false,
        escaping = false,
        typed_string = "",
        typing_sound = ""
    }
end

function Text:setText(text)
    self:resetState()

    self.text = text

    self.nodes = self:textToNodes(text)

    if self.width ~= self.canvas:getWidth() or self.height ~= self.canvas:getHeight() then
        self.canvas = love.graphics.newCanvas(self.width, self.height)
    end

    self:drawToCanvas(function()
        for i = 1, #self.nodes do
            local current_node = self.nodes[i]
            self:processNode(current_node)
            self.state.current_node = self.state.current_node + 1
        end
    end, true)
end

function Text:getFont()
    return Assets.getFont(self.font)
end

function Text:textToNodes(input_string)
    -- Very messy function to split text into text nodes.
    -- TODO: rewrite this. Please
    local nodes = {}
    local i = 1
    while i <= #input_string do
        local current_char = input_string:sub(i,i)
        local leaving_modifier = false
        if current_char == "[" then  -- We got a [, time to see if it's a modifier
            local j = i + 1
            local current_modifier = ""
            while j <= #input_string do
                if input_string:sub(j, j) == "]" then -- We found a bracket!
                    local old_i = i
                    i = j -- Let's set i so the modifier isn't processed as normal text

                    -- Let's split some values in the modifier!
                    local split = Utils.splitFast(current_modifier, ":")
                    local command = split[1]
                    local arguments = {}
                    if #split > 1 then
                        arguments = Utils.splitFast(split[2], ",")
                    end

                    leaving_modifier = true

                    if command == "color" then
                        table.insert(nodes, {
                            ["type"] = "render_mod",
                            ["command"] = command,
                            ["arguments"] = arguments
                        })
                    elseif command == "noskip" then
                        table.insert(nodes, {
                            ["type"] = "typer_mod",
                            ["command"] = command,
                            ["arguments"] = arguments
                        })
                    elseif command == "speed" then
                        table.insert(nodes, {
                            ["type"] = "typer_mod",
                            ["command"] = command,
                            ["arguments"] = arguments
                        })
                    elseif command == "instant" then
                        table.insert(nodes, {
                            ["type"] = "typer_mod",
                            ["command"] = command,
                            ["arguments"] = arguments
                        })
                    elseif command == "stopinstant" then
                        table.insert(nodes, {
                            ["type"] = "typer_mod",
                            ["command"] = command,
                            ["arguments"] = arguments
                        })
                    elseif command == "wait" then
                        table.insert(nodes, {
                            ["type"] = "typer_mod",
                            ["command"] = command,
                            ["arguments"] = arguments
                        })
                    else
                        -- Whoops, invalid modifier. Let's just parse this like normal text...
                        leaving_modifier = false
                        i = old_i
                    end

                    current_char = input_string:sub(i, i) -- Set current_char to the new value
                    break
                else
                    current_modifier = current_modifier .. input_string:sub(j, j)
                end
                j = j + 1
            end
            -- It didn't find a closing bracket, let's give up
        end
        if leaving_modifier then
            leaving_modifier = false
        else
            table.insert(nodes, {
                ["type"] = "character",
                ["character"] = current_char,
            })
        end
        i = i + 1
    end
    return nodes
end

function Text:drawToCanvas(func, clear)
    Draw.pushCanvas(self.canvas)
    Draw.pushScissor()
    love.graphics.push()
    love.graphics.origin()
    if clear then
        love.graphics.clear()
    end
    func()
    love.graphics.pop()
    Draw.popCanvas()
end

function Text:processNode(node)
    local font = self:getFont()
    if node.type == "character" then
        self.state.typed_characters = self.state.typed_characters + 1
        self.state.typed_string = self.state.typed_string .. node.character
        if self.state.typed_string == "* " then
            self.state.asterisk_mode = true
        end
        if node.character == "\n" then
            self.state.current_x = 0
            if self.state.asterisk_mode then
                self.state.current_x = font:getWidth("* ")
            end
            local spacing = Assets.getFontData(self.font) or {}
            self.state.current_y = self.state.current_y + (spacing.lineSpacing or font:getHeight()) + self.line_offset
            -- We don't want to wait on a newline, so...
            self.state.progress = self.state.progress + 1
        elseif node.character == "\\" and not self.state.escaping then
            self.state.escaping = true
        elseif not self.state.escaping then
            if node.character == "*" then
                if self.state.asterisk_mode and self.state.current_x == font:getWidth("* ") then -- TODO: PLEASE UNHARDCODE
                    self.state.current_x = 0
                end
            end
            --print("INSERTING " .. node.character .. " AT " .. self.state.current_x .. ", " .. self.state.current_y)
            local w, h = self:drawChar(node, self.state)
            self.state.current_x = self.state.current_x + w
        else
            self.state.escaping = false
            if node.character == "\\" or node.character == "*" then
                local w, h = self:drawChar(node, self.state)
                self.state.current_x = self.state.current_x + w
            end
        end
    else
        self:processModifier(node)
    end
    --print(Utils.dump(node))
end

function Text:processModifier(node)
    if node.type == "render_mod" then
        if node.command == "color" then
            if self.COLORS[node.arguments[1]] then
                -- Did they input a valid color name? Let's use it.
                self.state.color = self.COLORS[node.arguments[1]]
            elseif node.arguments[1] == "reset" then
                -- They want to reset the color.
                self.state.color = {1, 1, 1, 1}
            elseif #node.arguments[1] == 6 then
                -- It's 6 letters long, assume hashless hex
                self.state.color = Utils.hexToRgb("#" .. node.arguments[1])
            elseif #node.arguments[1] == 7 then
                -- It's 7 letters long, assume hex
                self.state.color = Utils.hexToRgb(node.arguments[1])
            end
        end
    end
end

function Text:drawChar(node, state)
    local font = Assets.getFont(state.font)
    local width, height = font:getWidth(node.character), font:getHeight()
    local x, y = state.current_x, state.current_y
    love.graphics.setFont(font)
    if self.style == nil or self.style == "none" then
        love.graphics.setColor(unpack(state.color))
        love.graphics.print(node.character, x, y)
    elseif self.style == "menu" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(node.character, x+2, y+2)
        love.graphics.setColor(unpack(state.color))
        love.graphics.print(node.character, x, y)
    elseif self.style == "dark" then
        local canvas = Draw.pushCanvas(width, height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(node.character)
        Draw.popCanvas()

        local shader = Kristal.Shaders["GradientV"]

        local last_shader = love.graphics.getShader()

        local white = state.color[1] == 1 and state.color[2] == 1 and state.color[3] == 1

        if white then
            love.graphics.setShader(shader)
            shader:send("from", white and COLORS.dkgray or state.color)
            shader:send("to", white and COLORS.navy or state.color)
            love.graphics.setColor(1, 1, 1, white and 1 or 0.3)
        else
            love.graphics.setColor(state.color[1], state.color[2], state.color[3], 0.3)
        end
        love.graphics.draw(canvas, x+1, y+1)

        if not white then
            love.graphics.setShader(shader)
            shader:send("from", COLORS.white)
            shader:send("to", white and COLORS.white or state.color)
        else
            love.graphics.setShader(last_shader)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(canvas, x, y)

        if not white then
            love.graphics.setShader(last_shader)
        end
    elseif self.style == "dark_menu" then
        love.graphics.setColor(0.25, 0.125, 0.25)
        love.graphics.print(node.character, x+2, y+2)
        love.graphics.setColor(unpack(state.color))
        love.graphics.print(node.character, x, y)
    end
    return width, height
end

function Text:draw()
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(self.canvas)
    love.graphics.setBlendMode("alpha")

    super:draw(self)
end

return Text