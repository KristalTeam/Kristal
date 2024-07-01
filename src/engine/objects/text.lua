---@class Text : Object
---@overload fun(...) : Text
local Text, super = Class(Object)

Text.COMMANDS = { "color", "font", "style", "shake", "wave", "image", "bind", "button", "offset", "indent", "spacing" }

Text.COLORS = {
    ["red"] = COLORS.red,
    ["blue"] = COLORS.blue,
    ["yellow"] = COLORS.yellow,
    ["green"] = COLORS.lime,
    ["white"] = COLORS.white,
    ["black"] = COLORS.black,
    ["purple"] = COLORS.purple,
    ["maroon"] = COLORS.maroon,
    ["pink"] = { 1, 0.5, 1 },
    ["lime"] = { 0.5, 1, 0.5 }
}

function Text:init(text, x, y, w, h, options)
    if type(w) == "table" then
        options = w
        w, h = SCREEN_WIDTH, SCREEN_HEIGHT
    end

    super.init(self, x, y, w or SCREEN_WIDTH, h or SCREEN_HEIGHT)

    options = options or {}

    self.sprites = {}

    self.draw_every_frame = false
    self.nodes_to_draw = {}

    self.custom_commands = {}
    self.custom_command_dry = {}

    self.font = options["font"] or "main"
    self.font_size = options["font_size"] or nil
    self.text_color = options["color"] or { 1, 1, 1, 1 }
    self.style = options["style"] or "none"
    if self:isStyleAnimated(self.style) then
        self.draw_every_frame = true
    end
    self.wrap = options["wrap"] ~= false
    self.align = options["align"] or "left"
    self.canvas = love.graphics.newCanvas(w, h)
    self.line_offset = options["line_offset"] or 0
    self.last_shake = 0

    self.auto_size = options["auto_size"] or false
    self.indent_string = options["indent_string"] or "* "

    self.preprocess = options["preprocess"] or self.align ~= "left" or self.wrap or self.auto_size

    self.text_width = 0
    self.text_height = 0
    self.alignment_offset = {}
    self.default_width = self.width
    self.default_height = self.height

    self.timer = 0

    Kristal.callEvent(KRISTAL_EVENT.registerTextCommands, self)

    self:resetState()

    self:setText(text)
    self.set_text_without_stage = true
end

function Text:getDebugRectangle()
    if not self.debug_rect then
        return { 0, 0, self:getTextWidth(), self:getTextHeight() }
    end
    return super.getDebugRectangle(self)
end

function Text:getSize()
    return self:getTextWidth(), self:getTextHeight()
end

function Text:getScaledSize()
    return self:getTextWidth() * self.scale_x, self:getTextHeight() * self.scale_y
end

function Text:onAddToStage(stage)
    if self.set_text_without_stage then
        self.set_text_without_stage = false
        self:processInitialNodes()
    end
end

function Text:processInitialNodes()
    self:drawToCanvas(function()
        for i = 1, #self.nodes do
            local current_node = self.nodes[i]
            self:processNode(current_node, false)
            self.state.current_node = self.state.current_node + 1
        end
    end, true)
end

function Text:resetState()
    self.state = {
        color = self.text_color,
        font = self.font,
        font_size = self.font_size,
        style = self.style,
        current_x = 0,
        current_y = 0,
        typed_characters = 0,
        progress = 1,
        current_node = 1,
        typing = true,
        talk_anim = true,
        speed = 1,
        waiting = 0,
        skipping = false,
        indent_string = self.indent_string,
        indent_mode = false,
        indent_length = 0,
        escaping = false,
        typed_string = "",
        typing_sound = "",
        noskip = false,
        spacing = 0,
        shake = 0,
        last_shake = self.timer,
        wave_distance = 0,
        wave_offset = 0,
        wave_direction = 0,
        offset_x = 0,
        offset_y = 0,
        newline = false,
        max_width = 0,
        max_height = 0,
        current_line = 1,
        line_lengths = { 0 },
    }
end

function Text:update()
    self.timer = self.timer + DTMULT
    self.state.wave_direction = self.state.wave_direction + (20 * DTMULT)
    super.update(self)
end

function Text:setText(text)
    for _, sprite in ipairs(self.sprites) do
        sprite:remove()
    end
    self.sprites = {}

    self:resetState()

    self.text = text or ""

    if self.align ~= "left" or self.wrap or self.auto_size then
        self.preprocess = true
    end

    if self.auto_size then
        self.width = self.default_width
        self.height = self.default_height
    end

    self.text_width = 0
    self.text_height = 0
    self.alignment_offset = {}

    self.nodes_to_draw = {}
    self.nodes, self.display_text = self:textToNodes(self.text)

    if self.width ~= self.canvas:getWidth() or self.height ~= self.canvas:getHeight() then
        self.canvas = love.graphics.newCanvas(self.width, self.height)
    end

    if self.alignment_offset[1] then
        self.state.current_x = self.state.current_x + self.alignment_offset[1]
    end

    if self.stage then
        self.set_text_without_stage = false
        self:processInitialNodes()
    else
        self.set_text_without_stage = true
    end
end

function Text:getFont()
    return Assets.getFont(self.state.font, self.state.font_size)
end

function Text:getTextWidth()
    return self.preprocess and self.text_width or self.state.max_width
end

function Text:getTextHeight()
    return self.preprocess and self.text_height or self.state.max_height
end

function Text:textToNodes(input_string)
    -- Very messy function to split text into text nodes.

    local old_state = nil
    if self.preprocess then
        old_state = self.state
        self:resetState()
    end
    local last_space = -1
    local last_space_char = -1
    local last_space_state = nil

    local nodes = {}
    local display_text = ""
    local last_char = ""
    local i = 1
    while i <= utf8.len(input_string) do
        local current_char = Utils.sub(input_string, i, i)
        local leaving_modifier = false
        if current_char == "[" and last_char ~= "\\" then -- We got a [, time to see if it's a modifier
            local j = i + 1
            local current_modifier = ""
            while j <= utf8.len(input_string) do
                if Utils.sub(input_string, j, j) == "]" then -- We found a bracket!
                    local old_i = i
                    i = j                                    -- Let's set i so the modifier isn't processed as normal text

                    -- Let's split some values in the modifier!
                    local split = Utils.splitFast(current_modifier, ":")
                    local command = split[1]
                    local arguments = {}
                    if #split > 1 then
                        -- arguments = Utils.splitFast(split[2], ",")
                        local k = 1
                        local k_start = 1
                        local escaping = false
                        local arg = ""
                        while k <= utf8.len(split[2]) do
                            local char = Utils.sub(split[2], k, k)
                            if escaping then
                                escaping = false
                                arg = arg .. char
                            else
                                if char == "\\" then
                                    escaping = true
                                elseif char == "," then
                                    table.insert(arguments, arg)
                                    arg = ""
                                    k_start = k + 1
                                elseif k == utf8.len(split[2]) then
                                    table.insert(arguments, arg .. char)
                                else
                                    arg = arg .. char
                                end
                            end
                            k = k + 1
                        end
                    end

                    leaving_modifier = true

                    -- The bind modifier will either insert text or a different modifer
                    if command == "bind" then
                        local bind_key = Input.getPrimaryBind(arguments[1])

                        -- Only add gamepad button if a gamepad binding exists
                        if bind_key and Input.usingGamepad() then
                            -- We're already processing a modifier, so just change it to the button modifier
                            command = "button"
                            arguments = { bind_key }
                        else
                            -- Writing key text, pretend we're not in a modifier
                            leaving_modifier = false
                            i = old_i

                            -- Cut out the bind modifier from the text and insert the key name
                            local input_text = Input.getText(arguments[1])
                            input_string = Utils.sub(input_string, 1, i - 1) ..
                                input_text .. Utils.sub(input_string, j + 1)
                            current_char = Utils.sub(input_string, i, i)

                            -- Go back and parse the rest like normal text
                            break
                        end
                    end

                    if self:isModifier(command) then
                        local new_node = {
                            ["type"] = "modifier",
                            ["command"] = command,
                            ["arguments"] = arguments
                        }
                        if self.preprocess then
                            local prior_state
                            if self.wrap then
                                prior_state = Utils.copy(self.state, true)
                            end
                            self:processNode(new_node, true)
                            if self.wrap and self.state.current_x > self.width then
                                if last_space == -1 then
                                    self.state = prior_state
                                    local newline_node = {
                                        ["type"] = "character",
                                        ["character"] = "\n",
                                    }
                                    table.insert(nodes, newline_node)
                                    display_text = display_text .. "\n"
                                    self:processNode(newline_node, true)
                                    self:processNode(new_node, true)
                                else
                                    self.state = last_space_state
                                    local newline_node = {
                                        ["type"] = "character",
                                        ["character"] = "\n",
                                    }
                                    nodes[last_space + 1] = newline_node
                                    self:processNode(newline_node, true)
                                    display_text = Utils.stringInsert(display_text, "\n", last_space_char + 1)
                                    for i = last_space + 1, #nodes + 1 do
                                        if nodes[i] then
                                            self:processNode(nodes[i], true)
                                        end
                                    end
                                    self:processNode(new_node, true)
                                    last_space = -1
                                    last_space_char = -1
                                end
                            end
                        end
                        table.insert(nodes, new_node)
                    else
                        -- Whoops, invalid modifier. Let's just parse this like normal text...
                        leaving_modifier = false
                        i = old_i
                    end

                    current_char = Utils.sub(input_string, i, i) -- Set current_char to the new value
                    break
                else
                    current_modifier = current_modifier .. Utils.sub(input_string, j, j)
                end
                j = j + 1
            end
            -- It didn't find a closing bracket, let's give up
        end
        if leaving_modifier then
            leaving_modifier = false
        else
            if self.wrap and (current_char == " " or current_char == "\n") then
                last_space = #nodes
                last_space_char = utf8.len(display_text)
                last_space_state = Utils.copy(self.state, true)
            end
            local new_node = {
                ["type"] = "character",
                ["character"] = current_char,
            }

            local dont_add = false
            if self.preprocess then
                local prior_state
                if self.wrap then
                    prior_state = Utils.copy(self.state, true)
                end
                self:processNode(new_node, true)
                if self.wrap and self.state.current_x > self.width then
                    if last_space == -1 then
                        self.state = prior_state
                        local newline_node = {
                            ["type"] = "character",
                            ["character"] = "\n",
                        }
                        table.insert(nodes, newline_node)
                        display_text = display_text .. "\n"
                        self:processNode(newline_node, true)
                        self:processNode(new_node, true)
                    else
                        self.state = last_space_state
                        local newline_node = {
                            ["type"] = "character",
                            ["character"] = "\n",
                        }
                        nodes[last_space + 1] = newline_node
                        --self:processNode(newline_node, true)
                        display_text = Utils.stringInsert(display_text, "\n", last_space_char + 1)
                        for i = last_space + 1, #nodes + 1 do
                            if nodes[i] then
                                self:processNode(nodes[i], true)
                            end
                        end
                        if current_char == " " then
                            dont_add = true
                        else
                            dont_add = false
                            self:processNode(new_node, true)
                        end
                        last_space = -1
                        last_space_char = -1
                    end
                end
            end

            if not dont_add then
                table.insert(nodes, new_node)
                display_text = display_text .. current_char
            end
        end
        last_char = current_char or ""
        i = i + 1
    end

    if self.preprocess then
        self.text_width = self.state.max_width
        self.text_height = self.state.max_height

        if self.auto_size then
            self.width = math.max(1, self.text_width)
            self.height = math.max(1, self.text_height)
        end

        self.alignment_offset = {}
        for i = 1, #self.state.line_lengths do
            if self.align == "center" then
                self.alignment_offset[i] = (self.width / 2) - (self.state.line_lengths[i] / 2)
            elseif self.align == "right" then
                self.alignment_offset[i] = self.width - self.state.line_lengths[i]
            else
                self.alignment_offset[i] = 0
            end
        end

        self.state = old_state
    end
    return nodes, display_text
end

function Text:drawToCanvas(func, clear)
    Draw.pushCanvas(self.canvas, { stencil = false })
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

function Text:processNode(node, dry)
    local font = self:getFont()
    if node.type == "character" then
        self.state.typed_characters = self.state.typed_characters + 1
        self.state.typed_string = self.state.typed_string .. node.character
        local font_scale = Assets.getFontScale(self.state.font, self.state.font_size)
        if self.state.typed_string == self.state.indent_string then
            self.state.indent_mode = true
            self.state.indent_length = font:getWidth(self.state.indent_string) * font_scale
        end
        if node.character == "\n" then
            self.state.current_x = 0
            if self.state.indent_mode then
                self.state.current_x = self.state.indent_length + self.state.spacing
            end
            local spacing = Assets.getFontData(self.state.font) or {}
            self.state.current_y = self.state.current_y + ((spacing.lineSpacing or font:getHeight()) * font_scale) +
                self.line_offset
            -- We don't want to wait on a newline, so...
            self.state.newline = true
            self.state.progress = self.state.progress + 1
            self.state.current_line = self.state.current_line + 1
            table.insert(self.state.line_lengths, 0)
            if not dry and self.alignment_offset[self.state.current_line] then
                self.state.current_x = self.state.current_x + self.alignment_offset[self.state.current_line]
            end
        elseif node.character == "\\" and not self.state.escaping then
            self.state.escaping = true
            self.state.newline = false
            self.state.typed_characters = self.state.typed_characters - 1
        elseif not self.state.escaping then
            if node.character == Utils.sub(self.state.indent_string, 1, 1) then
                if self.state.indent_mode and self.state.newline then
                    self.state.current_x = 0
                    self.state.newline = false
                end
            end
            --print("INSERTING " .. node.character .. " AT " .. self.state.current_x .. ", " .. self.state.current_y)
            if not dry then
                self:drawChar(node, self.state)
                table.insert(self.nodes_to_draw, { node, Utils.copy(self.state, true) })
            end
            local w, h = self:getNodeSize(node, self.state)
            self.state.current_x = self.state.current_x + w + self.state.spacing
            self.state.max_height = math.max(self.state.max_height, self.state.current_y + h)
        else
            self.state.newline = false
            self.state.escaping = false
            if node.character == "\\" or node.character == Utils.sub(self.state.indent_string, 1, 1) or node.character == "[" or node.character == "]" then
                if not dry then
                    self:drawChar(node, self.state)
                    table.insert(self.nodes_to_draw, { node, Utils.copy(self.state, true) })
                end
                local w, h = self:getNodeSize(node, self.state)
                self.state.current_x = self.state.current_x + w + self.state.spacing
                self.state.max_height = math.max(self.state.max_height, self.state.current_y + h)
            end
        end
    elseif node.type == "modifier" then
        if self.custom_commands[node.command] then
            self:processCustomCommand(node, dry)
        else
            self:processModifier(node, dry)
        end
    end
    -- Update text size
    self.state.max_width = math.max(self.state.max_width, self.state.current_x)
    self.state.max_height = math.max(self.state.max_height, self.state.current_y)

    if self.state.indent_mode then
        for i = 1, #self.state.line_lengths do
            self.state.line_lengths[i] = self.state.max_width
        end
    else
        self.state.line_lengths[self.state.current_line] = self.state.current_x
    end
    --print(Utils.dump(node))
end

function Text:isModifier(command)
    return Utils.containsValue(Text.COMMANDS, command) or self.custom_commands[command]
end

function Text:processModifier(node, dry)
    if self.custom_commands[node.command] then
        self:processCustomCommand(node, dry)
    elseif node.command == "color" then
        if Text.COLORS[node.arguments[1]] then
            -- Did they input a valid color name? Let's use it.
            self.state.color = Text.COLORS[node.arguments[1]]
        elseif node.arguments[1] == "reset" then
            -- They want to reset the color.
            self.state.color = self.text_color
        elseif #node.arguments[1] == 6 then
            -- It's 6 letters long, assume hashless hex
            self.state.color = Utils.hexToRgb("#" .. node.arguments[1])
        elseif #node.arguments[1] == 7 then
            -- It's 7 letters long, assume hex
            self.state.color = Utils.hexToRgb(node.arguments[1])
        end
    elseif node.command == "font" then
        if node.arguments[1] == "reset" then
            self.state.font = self.font
            self.state.font_size = self.font_size
        else
            self.state.font = node.arguments[1]
            self.state.font_size = tonumber(node.arguments[2])
        end
    elseif node.command == "shake" then
        self.state.shake = tonumber(node.arguments[1]) or 1
        self.draw_every_frame = true
    elseif node.command == "wave" then
        -- [wave:0] to disable!
        self.state.wave_distance = tonumber(node.arguments[1]) or 2
        self.state.wave_offset = tonumber(node.arguments[2]) or 30
        self.draw_every_frame = true
    elseif node.command == "style" then
        if node.arguments[1] == "reset" then
            self.state.style = "none"
        else
            self.state.style = node.arguments[1]
            if self:isStyleAnimated(self.state.style) then
                self.draw_every_frame = true
            end
        end
    elseif node.command == "image" then
        local x_offset = tonumber(node.arguments[2]) or 0
        local y_offset = tonumber(node.arguments[3]) or 0
        local x_scale  = tonumber(node.arguments[4]) or 1
        local y_scale  = tonumber(node.arguments[5]) or 1
        local speed    = tonumber(node.arguments[6]) or (1 / 15)

        local texture  = Assets.getFramesOrTexture(node.arguments[1])
        if texture then
            if not dry then
                local y = self.state.current_y + (self:getFont():getHeight() / 2)
                local sprite = Sprite(texture, self.state.current_x + x_offset, y + y_offset)
                sprite:setOrigin(0, 0.5)
                sprite:setScale(x_scale, y_scale)
                sprite.layer = self.layer + 1
                sprite:play(speed, true)
                self:addChild(sprite)
                table.insert(self.sprites, sprite)
            end
            self.state.current_x = self.state.current_x + (texture[1]:getWidth() * x_scale) + self.state.spacing
        end
    elseif node.command == "button" then
        if not dry then
            local texture = "kristal/buttons/" .. Input.getButtonSprite(node.arguments[1])

            local y = self.state.current_y + (self:getFont():getHeight() / 2)
            local sprite = Sprite(texture, self.state.current_x, y)
            sprite:setOrigin(0, 0.5)
            sprite:setScale(2, 2)
            sprite.layer = self.layer + 1
            self:addChild(sprite)
            table.insert(self.sprites, sprite)
        end
        self.state.current_x = self.state.current_x + 32
    elseif node.command == "offset" then
        self.state.current_x = self.state.current_x + tonumber(node.arguments[1])
        self.state.current_y = self.state.current_y + tonumber(node.arguments[2])
    elseif node.command == "indent" then
        self.state.indent_string = node.arguments[1]
    elseif node.command == "spacing" then
        self.state.spacing = tonumber(node.arguments[1])
    end
end

function Text:registerCommand(command, func, options)
    self.custom_commands[command] = func
    self.custom_command_dry[command] = options and options["dry"] or false
end

function Text:processCustomCommand(node, dry)
    if not dry or self.custom_command_dry[node.command] then
        return self.custom_commands[node.command](self, node, dry)
    end
end

function Text:getNodeSize(node, state, include_scale)
    local font = Assets.getFont(state.font, state.font_size)
    local scale = Assets.getFontScale(state.font, state.font_size)
    if include_scale ~= false then
        return math.max(1, font:getWidth(node.character) * scale), font:getHeight() * scale
    else
        return math.max(1, font:getWidth(node.character)), font:getHeight()
    end
end

function Text:setTextColor(r, g, b, a)
    self.text_color = { r or 1, g or 1, b or 1, a or 1 }
    self.state.color = self.text_color
end

function Text:getTextColor(state, use_base_color)
    -- The base color, either the draw color or (1,1,1,1) depending on
    -- if the text is drawing to a canvas
    local cr, cg, cb, ca
    if use_base_color then
        cr, cg, cb, ca = self:getDrawColor()
    else
        cr, cg, cb, ca = 1, 1, 1, 1
    end
    -- The current state color
    local sr, sg, sb, sa = unpack(state.color)
    sa = sa or 1

    -- The current color multiplied by the base color
    return sr * cr, sg * cg, sb * cb, sa * ca
end

function Text:drawChar(node, state, use_color)
    local font = Assets.getFont(state.font, state.font_size)
    local scale = Assets.getFontScale(state.font, state.font_size)

    if state.shake > 0 then
        if self.timer - state.last_shake >= (1 * DTMULT) then
            state.last_shake = self.timer
            state.offset_x = Utils.round(Utils.random(-state.shake, state.shake))
            state.offset_y = Utils.round(Utils.random(-state.shake, state.shake))
        end
    end

    if state.wave_distance > 0 then
        local direction = self.state.wave_direction + (state.wave_offset * state.typed_characters)
        local speed = state.wave_distance

        local xspeed = math.cos(math.rad(-direction)) * speed
        local yspeed = math.sin(math.rad(-direction)) * speed

        state.offset_x = xspeed * 0.7 + 10
        state.offset_y = yspeed * 0.7
    end

    local x, y = state.current_x + state.offset_x, state.current_y + state.offset_y
    love.graphics.setFont(font)


    -- The base color, either the draw color or (1,1,1,1) depending on
    -- if the text is drawing to a canvas
    local cr, cg, cb, ca
    if use_color then
        cr, cg, cb, ca = self:getDrawColor()
    else
        cr, cg, cb, ca = 1, 1, 1, 1
    end
    -- The current color multiplied by the base color
    local mr, mg, mb, ma = self:getTextColor(state, use_color)

    Draw.setColor(mr, mg, mb, ma)

    if Kristal.callEvent(KRISTAL_EVENT.onDrawText, self, node, state, x, y, scale, font, use_color) then
        -- Empty because I don't like logic
    elseif self:processStyle(state.style) then
        -- Empty because I don't like logic
    elseif state.style == nil or state.style == "none" then
        Draw.setColor(mr, mg, mb, ma)
        love.graphics.print(node.character, x, y, 0, scale, scale)
    elseif state.style == "menu" then
        Draw.setColor(0, 0, 0)
        love.graphics.print(node.character, x + 2, y + 2, 0, scale, scale)
        Draw.setColor(mr, mg, mb, ma)
        love.graphics.print(node.character, x, y, 0, scale, scale)
    elseif state.style == "dark" then
        local w, h = self:getNodeSize(node, state)
        local canvas = Draw.pushCanvas(w, h, { stencil = false })
        Draw.setColor(1, 1, 1)
        love.graphics.print(node.character, 0, 0, 0, scale, scale)
        Draw.popCanvas()

        local shader = Kristal.Shaders["GradientV"]

        local last_shader = love.graphics.getShader()

        local white = state.color[1] == 1 and state.color[2] == 1 and state.color[3] == 1

        if white then
            love.graphics.setShader(shader)
            shader:sendColor("from", white and COLORS.dkgray or state.color)
            shader:sendColor("to", white and COLORS.navy or state.color)
            --Draw.setColor(cr, cg, cb, ca * (white and 1 or 0.3))
            local mult = white and 1 or 0.3
            Draw.setColor(cr * mult, cg * mult, cb * mult, ca)
        else
            --Draw.setColor(mr, mg, mb, ma * 0.3)
            Draw.setColor(mr * 0.3, mg * 0.3, mb * 0.3, ma)
        end
        Draw.draw(canvas, x + 1, y + 1)

        if not white then
            love.graphics.setShader(shader)
            shader:sendColor("from", COLORS.white)
            shader:sendColor("to", white and COLORS.white or state.color)
        else
            love.graphics.setShader(last_shader)
        end
        Draw.setColor(cr, cg, cb, ca)
        Draw.draw(canvas, x, y)

        if not white then
            love.graphics.setShader(last_shader)
        end
    elseif state.style == "dark_menu" then
        Draw.setColor(0.25, 0.125, 0.25)
        love.graphics.print(node.character, x + 2, y + 2, 0, scale, scale)
        Draw.setColor(mr, mg, mb, ma)
        love.graphics.print(node.character, x, y, 0, scale, scale)
    elseif state.style == "GONER" then
        local specfade = 1 -- This is unused for now!
        -- It's used in chapter 1, though... so let's keep it around.
        Draw.setColor(mr, mg, mb, ma * specfade)
        love.graphics.print(node.character, x, y, 0, scale, scale)
        Draw.setColor(mr, mg, mb, ma * ((0.3 + (math.sin((self.timer / 14)) * 0.1)) * specfade))
        love.graphics.print(node.character, x + 2, y, 0, scale, scale)
        love.graphics.print(node.character, x - 2, y, 0, scale, scale)
        love.graphics.print(node.character, x, y + 2, 0, scale, scale)
        love.graphics.print(node.character, x, y - 2, 0, scale, scale)
        Draw.setColor(mr, mg, mb, ma * ((0.08 + (math.sin((self.timer / 14)) * 0.04)) * specfade))
        love.graphics.print(node.character, x + 2, y, 0, scale, scale)
        love.graphics.print(node.character, x - 2, y, 0, scale, scale)
        love.graphics.print(node.character, x, y + 2, 0, scale, scale)
        love.graphics.print(node.character, x, y - 2, 0, scale, scale)
        Draw.setColor(mr, mg, mb, ma)
    end
end

function Text:isStyleAnimated(style)
    return style == "GONER" or Kristal.callEvent(KRISTAL_EVENT.isTextStyleAnimated, style, self)
end

function Text:processStyle(style)
    return false
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
        Draw.draw(self.canvas)
        --love.graphics.setBlendMode("alpha")
    end

    if DEBUG_RENDER then
        Draw.setColor(0, 1, 0.5, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 0, 0, self.width, self.height)

        Draw.setColor(0, 1, 0.5, 1)
        love.graphics.rectangle("line", 0, 0, self:getTextWidth(), self:getTextHeight())
    end

    super.draw(self)
end

return Text
