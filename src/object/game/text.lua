local Text, super = newClass(Object)

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

function Text:init(text, x, y, char_type, font)
    super:init(self, x, y)

    self.char_type = char_type or TextChar
    self.font = font or "main"
    self.chars = {}

    self:resetState()

    self:setText(text)
end

function Text:resetState()
    self.state = {
        color = {1, 1, 1, 1},
        current_x = 0,
        current_y = 0,
        typed_characters = 0,
        progress = 1,
        current_node = 1,
        typing = true,
        speed = 1,
        skipping = false,
        asterisk_mode = false,
        typed_string = ""
    }
end

function Text:setText(text)
    for _,v in ipairs(self.chars) do
        self:remove(v)
    end
    self.chars = {}
    self:resetState()

    self.text = text

    self.nodes = self:textToNodes(text)

    for i = 1, #self.nodes do
        local current_node = self.nodes[i]
        self:processNode(current_node)
        self.state.current_node = self.state.current_node + 1
    end
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
                    local split = utils.splitFast(current_modifier, ":")
                    local command = split[1]
                    local arguments = {}
                    if #split > 1 then
                        arguments = utils.splitFast(split[2], ",")
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

function Text:processNode(node)
    if node.type == "character" then
        self.state.typed_characters = self.state.typed_characters + 1
        self.state.typed_string = self.state.typed_string .. node.character
        if self.state.typed_string == "* " then
            self.state.asterisk_mode = true
        end
        if node.character == "\n" then
            self.state.current_x = 0
            if self.state.asterisk_mode then
                self.state.current_x = (16 * 2) -- TODO: unhardcode
            end
            self.state.current_y = self.state.current_y + 36 -- TODO: unhardcode
            -- We don't want to wait on a newline, so...
            self.state.progress = self.state.progress + 1
        else
            if node.character == "*" then
                if self.state.asterisk_mode and self.state.current_x == (16 * 2) then -- TODO: PLEASE UNHARDCODE
                    self.state.current_x = 0
                end
            end
            local char = self.char_type(node.character, self.state.current_x, self.state.current_y, self.state.color)
            table.insert(self.chars, char)
            self:add(char)
            self.state.current_x = self.state.current_x + char.width
        end
    else
        self:processModifier(node)
    end
    --print(utils.dump(node))
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
                self.state.color = utils.hexToRgb("#" .. node.arguments[1])
            elseif #node.arguments[1] == 7 then
                -- It's 7 letters long, assume hex
                self.state.color = utils.hexToRgb(node.arguments[1])
            end
        end
    end
end

return Text