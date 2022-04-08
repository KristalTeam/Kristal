local Text, super = Class(Object)

Text.COMMANDS = {"color", "font", "style", "shake"}

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

    self.draw_every_frame = false
    self.nodes_to_draw = {}

    self.custom_commands = {}

    self.font = font or "main"
    self.font_size = nil
    self.style = style
    if self.style == "GONER" then
        self.draw_every_frame = true
    end
    self.wrap = true
    self.canvas = love.graphics.newCanvas(w, h)
    self.line_offset = 0
    self.last_shake = 0

    self.timer = 0

    Kristal.callEvent("registerTextCommands", self)

    self:resetState()

    self:setText(text, false)
end

function Text:onAdd(stage)
    super:onAdd(self, stage)
    self:drawNodesAfterCreation()
end

function Text:drawNodesAfterCreation()
    self:drawToCanvas(function()
        for i = 1, #self.nodes do
            local current_node = self.nodes[i]
            self:processNode(current_node)
            self.state.current_node = self.state.current_node + 1
        end
    end, true)
end

function Text:resetState()
    self.state = {
        color = {1, 1, 1, 1},
        font = self.font,
        font_size = self.font_size,
        style = self.style,
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
        typing_sound = "",
        noskip = false,
        spacing = 0,
        shake = 0,
        last_shake = self.timer,
        offset_x = 0,
        offset_y = 0,
        newline = false
    }
end

function Text:update(dt)
    self.timer = self.timer + DTMULT
end

function Text:setText(text, draw)
    if draw == nil then
        draw = true
    end
    self:resetState()

    self.text = text

    self.nodes_to_draw = {}
    self.nodes, self.display_text = self:textToNodes(text)

    if self.width ~= self.canvas:getWidth() or self.height ~= self.canvas:getHeight() then
        self.canvas = love.graphics.newCanvas(self.width, self.height)
    end

    if draw then
        self:drawNodesAfterCreation()
    end
end

function Text:getFont()
    return Assets.getFont(self.font, self.font_size)
end

function Text:textToNodes(input_string)
    -- Very messy function to split text into text nodes.
    local nodes = {}
    local display_text = ""
    local last_char = ""
    local i = 1
    while i <= #input_string do
        local current_char = input_string:sub(i,i)
        local leaving_modifier = false
        if current_char == "[" and last_char ~= "\\" then  -- We got a [, time to see if it's a modifier
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

                    if self:isModifier(command) then
                        table.insert(nodes, {
                            ["type"] = "modifier",
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
            display_text = display_text..current_char
        end
        last_char = current_char
        i = i + 1
    end
    return nodes, display_text
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
    Draw.popScissor()
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
                self.state.current_x = font:getWidth("* ") + self.state.spacing
            end
            local spacing = Assets.getFontData(self.font) or {}
            self.state.current_y = self.state.current_y + (spacing.lineSpacing or font:getHeight()) + self.line_offset
            -- We don't want to wait on a newline, so...
            self.state.newline = true
            self.state.progress = self.state.progress + 1
        elseif node.character == "\\" and not self.state.escaping then
            self.state.escaping = true
            self.state.newline = false
            self.state.typed_characters = self.state.typed_characters - 1
        elseif not self.state.escaping then
            if node.character == "*" then
                if self.state.asterisk_mode and self.state.newline then
                    self.state.current_x = 0
                    self.state.newline = false
                end
            end
            --print("INSERTING " .. node.character .. " AT " .. self.state.current_x .. ", " .. self.state.current_y)
            local w, h = self:drawChar(node, self.state)
            table.insert(self.nodes_to_draw, {node, Utils.copy(self.state)})
            self.state.current_x = self.state.current_x + w + self.state.spacing
        else
            self.state.newline = false
            self.state.escaping = false
            if node.character == "\\" or node.character == "*" or node.character == "[" or node.character == "]" then
                local w, h = self:drawChar(node, self.state)
                table.insert(self.nodes_to_draw, {node, self.state})
                self.state.current_x = self.state.current_x + w + self.state.spacing
            end
        end
    elseif node.type == "modifier" then
        if self.custom_commands[node.command] then
            self:processCustomCommand(node)
        else
            self:processModifier(node)
        end
    end
    --print(Utils.dump(node))
end

function Text:isModifier(command)
    return Utils.containsValue(Text.COMMANDS, command) or self.custom_commands[command]
end

function Text:processModifier(node)
    if self.custom_commands[node.command] then
        self:processCustomCommand(node)
    elseif node.command == "color" then
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
    elseif node.command == "shake" then
        self.state.shake = tonumber(node.arguments[1])
        self.draw_every_frame = true
    elseif node.command == "style" then
        if node.arguments[1] == "reset" then
            self.state.style = "none"
        else
            self.state.style = node.arguments[1]
            if self.state.style == "GONER" then
                self.draw_every_frame = true
            end
        end
    end
end

function Text:registerCommand(command, func)
    self.custom_commands[command] = func
end

function Text:processCustomCommand(node)
    return self.custom_commands[node.command](self, node)
end

function Text:drawChar(node, state, use_color)
    local font = Assets.getFont(state.font, state.font_size)
    local width, height = font:getWidth(node.character), font:getHeight()

    if state.shake >= 0 then
        if self.timer - state.last_shake >= (1 * DTMULT) then
            state.last_shake = self.timer
            state.offset_x = Utils.round(Utils.random(-state.shake, state.shake))
            state.offset_y = Utils.round(Utils.random(-state.shake, state.shake))
        end
    end

    local x, y = state.current_x + state.offset_x, state.current_y + state.offset_y
    love.graphics.setFont(font)

    -- The base color, either the draw color or (1,1,1,1) depending on
    -- if the text is drawing to a canvas
    local cr,cg,cb,ca
    if use_color then
        cr, cg, cb, ca = self:getDrawColor()
    else
        cr, cg, cb, ca = 1, 1, 1, 1
    end
    -- The current state color
    local sr, sg, sb, sa = unpack(state.color)
    sa = sa or 1

    -- The current color multiplied by the base color
    local mr, mg, mb, ma = sr*cr, sg*cg, sb*cb, sa*ca

    if state.style == nil or state.style == "none" then
        love.graphics.setColor(mr,mg,mb,ma)
        love.graphics.print(node.character, x, y)
    elseif state.style == "menu" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(node.character, x+2, y+2)
        love.graphics.setColor(mr,mg,mb,ma)
        love.graphics.print(node.character, x, y)
    elseif state.style == "dark" then
        local canvas = Draw.pushCanvas(width, height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(node.character)
        Draw.popCanvas()

        local shader = Kristal.Shaders["GradientV"]

        local last_shader = love.graphics.getShader()

        local white = state.color[1] == 1 and state.color[2] == 1 and state.color[3] == 1

        if white then
            love.graphics.setShader(shader)
            shader:sendColor("from", white and COLORS.dkgray or state.color)
            shader:sendColor("to", white and COLORS.navy or state.color)
            --love.graphics.setColor(cr, cg, cb, ca * (white and 1 or 0.3))
            local mult = white and 1 or 0.3
            love.graphics.setColor(cr*mult, cg*mult, cb*mult, ca)
        else
            --love.graphics.setColor(mr, mg, mb, ma * 0.3)
            love.graphics.setColor(mr*0.3, mg*0.3, mb*0.3, ma)
        end
        love.graphics.draw(canvas, x+1, y+1)

        if not white then
            love.graphics.setShader(shader)
            shader:sendColor("from", COLORS.white)
            shader:sendColor("to", white and COLORS.white or state.color)
        else
            love.graphics.setShader(last_shader)
        end
        love.graphics.setColor(cr,cg,cb,ca)
        love.graphics.draw(canvas, x, y)

        if not white then
            love.graphics.setShader(last_shader)
        end
    elseif state.style == "dark_menu" then
        love.graphics.setColor(0.25, 0.125, 0.25)
        love.graphics.print(node.character, x+2, y+2)
        love.graphics.setColor(mr,mg,mb,ma)
        love.graphics.print(node.character, x, y)
    elseif state.style == "GONER" then

        local specfade = 1 -- This is unused for now!
        -- It's used in chapter 1, though... so let's keep it around.
        love.graphics.setColor(mr,mg,mb, ma*specfade)
        love.graphics.print(node.character, x, y)
        love.graphics.setColor(mr,mg,mb, ma*((0.3 + (math.sin((self.timer / 14)) * 0.1)) * specfade))
        love.graphics.print(node.character, x + 2, y)
        love.graphics.print(node.character, x - 2, y)
        love.graphics.print(node.character, x, y + 2)
        love.graphics.print(node.character, x, y - 2)
        love.graphics.setColor(mr,mg,mb, ma*((0.08 + (math.sin((self.timer / 14)) * 0.04)) * specfade))
        love.graphics.print(node.character, x + 2, y)
        love.graphics.print(node.character, x - 2, y)
        love.graphics.print(node.character, x, y + 2)
        love.graphics.print(node.character, x, y - 2)
        love.graphics.setColor(mr,mg,mb,ma)
    end
    return width, height
end

function Text:isTrue(text)
    text = string.lower(text)
    return (text == "true") or (text == "1") or (text == "yes") or (text == "on")
end

function Text:draw()
    if self.draw_every_frame then
        for i, node in ipairs(self.nodes_to_draw) do
            self:drawChar(node[1], node[2], true)
        end
    else
        --love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(self.canvas)
        --love.graphics.setBlendMode("alpha")
    end

    super:draw(self)
end

return Text