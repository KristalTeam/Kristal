local DialogueText, super = Class(Text)

function DialogueText:init(text, x, y, char_type, font)
    super:init(self, text, x or 0, y or 0, char_type or ShadedChar, font)
end

function DialogueText:setText(text)
    for _,v in ipairs(self.chars) do
        self:removeChild(v)
    end

    self.chars = {}
    self:resetState()

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

function DialogueText:update(dt)
    if self.state.waiting == 0 then
        self.state.progress = self.state.progress + (dt * 30 * self.state.speed)
    else
        self.state.waiting = math.max(0, self.state.waiting - dt)
    end

    if love.keyboard.isDown("x") then
        self.state.skipping = true
    end

    if self.state.typing then
        while (math.floor(self.state.progress) > self.state.typed_characters) or self.state.skipping do
            local current_node = self.nodes[self.state.current_node]

            if current_node == nil then
                self.state.typing = false
                break
            end

            self:processNode(current_node)

            if self.state.skipping then
                self.state.progress = self.state.typed_characters
            end

            self.state.current_node = self.state.current_node + 1
        end
    end

    self:updateChildren(dt)
end

function DialogueText:processModifier(node)
    super:processModifier(self, node)

    if node.type == "typer_mod" then
        if node.command == "speed" then
            self.state.speed = tonumber(node.arguments[1])
        elseif node.command == "instant" then
            self.state.skipping = true
        elseif node.command == "stopinstant" then
            self.state.skipping = false
        elseif node.command == "wait" then
            local delay = node.arguments[1]
            if delay:sub(-1) == "s" then
                self.state.waiting = tonumber(delay:sub(1, -2))
            else
                self.state.progress = self.state.progress - tonumber(delay)
            end
        end
    end
end

return DialogueText