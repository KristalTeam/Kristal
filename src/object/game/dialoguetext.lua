local DialogueText = newClass(Text)

function DialogueText:init(text, x, y, char_type, font)
    --super:init(self, x, y, font)
    Text.init(self, text, x, y, char_type or ShadedChar, font)
end

function DialogueText:setText(text)
    for _,v in ipairs(self.chars) do
        self:remove(v)
    end
    self.chars = {}

    self.text = text

    self.nodes = self:textToNodes(text)

    local i = 1
    while i <= #self.nodes do
        local current_node = self.nodes[i]
        self:processNode(current_node)
        self.state.current_node = self.state.current_node + 1
        i = i + 1
        -- If the current mode is a typewriter...
        if current_node.type == "character" and not self.state.skipping then
            break
        end
    end
end

function DialogueText:update()
    local dt = love.timer.getDelta()
    self.state.progress = self.state.progress + (dt * 30 * self.state.speed)

    if self.state.typing then
        while (math.floor(self.state.progress) > self.state.typed_characters) or self.state.instant do
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

function DialogueText:processModifier(node)
    --super:processModifier(self, node)
    Text.processModifier(self,node)

    if node.type == "typer_mod" then
        if node.command == "speed" then
            self.state.speed = tonumber(node.arguments[1])
        elseif node.command == "instant" then
            self.state.instant = true
        elseif node.command == "stopinstant" then
            self.state.instant = false
        elseif node.command == "wait" then
            self.state.progress = self.state.progress - tonumber(node.arguments[1])
        end
    end
end

return DialogueText