local DialogueText = newClass(Object)

DialogueText.COLORS = {
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

function DialogueText:init(text, x, y, font)
    super:init(self, x, y)

    self.font = font or "main"
    self.chars = {}
    self.type = "typewriter" -- typewriter, instant

    self.state = {
        color = nil,
        current_x = 0,
        current_y = 0,
        typed_characters = 0,
        progress = 1,
        current_node = 1,
        typing = true,
        speed = 1
    }


    self:setText(text)
end

function DialogueText:textToNodes(input_string)
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
                ["character"] = current_char
            })
        end
        i = i + 1
    end
    return nodes
end

function DialogueText:setText(text)
    for _,v in ipairs(self.chars) do
        self:remove(v)
    end
    self.chars = {}

    self.text = text

    self.nodes = self:textToNodes(text)

    if self.type == "typewriter" then

        -- We need to process until the first character.
        local i = 1
        while i <= #self.nodes do
            local current_node = self.nodes[i]
            self:processNode(current_node)
            self.state.current_node = self.state.current_node + 1
            i = i + 1
            if current_node.type == "character" then
                break
            end
        end
    else
        -- dunno tbh. workin on typewriters rn.
    end
end

function DialogueText:processNode(node)
    if node.type == "character" then
        self.state.typed_characters = self.state.typed_characters + 1
        if node.character == "\n" then
            self.state.current_x = 0
            self.state.current_y = self.state.current_y + 36 -- TODO: unhardcode
            -- We don't want to wait on a newline, so...
            self.state.progress = self.state.progress + 1
        else
            local char = DialogueChar(node.character, self.state.current_x, self.state.current_y, self.state.color)
            table.insert(self.chars, char)
            self:add(char)
            self.state.current_x = self.state.current_x + char:getWidth()
        end
    elseif node.type == "render_mod" then
        if node.command == "color" then
            if DialogueText.COLORS[node.arguments[1]] then
                -- Did they input a valid color name? Let's use it.
                self.state.color = DialogueText.COLORS[node.arguments[1]]
            elseif node.arguments[1] == "reset" then
                -- They want to reset the color.
                self.state.color = nil
            elseif #node.arguments[1] == 6 then
                -- It's 6 letters long, assume hashless hex
                self.state.color = utils.hexToRgb("#" .. node.arguments[1])
            elseif #node.arguments[1] == 7 then
                -- It's 7 letters long, assume hex
                self.state.color = utils.hexToRgb(node.arguments[1])
            else
                print("??")
            end
        end
    elseif node.type == "typer_mod" then
        if node.command == "speed" then
            self.state.speed = tonumber(node.arguments[1])
        end
    end
    print(utils.dump(node))
end

function DialogueText:update()
    local dt = love.timer.getDelta()
    self.state.progress = self.state.progress + (dt * 30 * self.state.speed)

    if self.state.typing then
        while math.floor(self.state.progress) > self.state.typed_characters do
            local current_node = self.nodes[self.state.current_node]

            if current_node == nil then
                self.state.typing = false
                break
            end

            self:processNode(current_node)
            self.state.current_node = self.state.current_node + 1
        end
    end
end

return DialogueText