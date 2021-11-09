local DialogueText, super = Class(Text)

DialogueText.COMMANDS = {"voice", "noskip", "speed", "instant", "stopinstant", "wait"}

function DialogueText:init(text, x, y, w, h, font, style)
    super:init(self, text, x or 0, y or 0, w or SCREEN_WIDTH, h or SCREEN_HEIGHT, font or "main_mono", style or "dark")
end

function DialogueText:resetState()
    super:resetState(self)
    self.state["typing_sound"] = "default"
end

function DialogueText:setText(text)
    self:resetState()

    self.text = text

    self.nodes = self:textToNodes(text)

    if self.width ~= self.canvas:getWidth() or self.height ~= self.canvas:getHeight() then
        self.canvas = love.graphics.newCanvas(self.width, self.height)
    end

    self:drawToCanvas(function()
        local i = 1
        while i <= #self.nodes do
            local current_node = self.nodes[i]
            self:processNode(current_node)
            self.state.current_node = self.state.current_node + 1
            i = i + 1
            -- If the current mode is a typewriter...
            if not self.state.skipping and not self:isNodeInstant(current_node) then
                break
            end
        end
    end, true)
end

function DialogueText:update(dt)
    if self.state.waiting == 0 then
        self.state.progress = self.state.progress + (dt * 30 * self.state.speed)
    else
        self.state.waiting = math.max(0, self.state.waiting - dt)
    end

    if Input.down("cancel") then
        self.state.skipping = true
    end

    if self.state.typing then
        self:drawToCanvas(function()
            while (math.floor(self.state.progress) > self.state.typed_characters) or self.state.skipping do
                local current_node = self.nodes[self.state.current_node]

                if current_node == nil then
                    self.state.typing = false
                    break
                end

                self:playTextSound(current_node)
                self:processNode(current_node)

                if self.state.skipping then
                    self.state.progress = self.state.typed_characters
                end

                self.state.current_node = self.state.current_node + 1
            end
        end)
    end

    super:update(self, dt)
end

function DialogueText:playTextSound(current_node)
    if self.state.skipping then
        return
    end

    if current_node.type ~= "character" then
        return
    end

    if(current_node.character:match("%W")) then
        -- Non-alphanumeric character, return
        return
    end

    if (self.state.typing_sound ~= nil) and (self.state.typing_sound ~= "") then
        Assets.playSound("voice/"..self.state.typing_sound)
    end
end

function DialogueText:isNodeInstant(node)
    if node.type == "character" then
        return false
    elseif node.type == "modifier" and node.command == "wait" then
        return false
    end
    return true
end

function DialogueText:isModifier(command)
    return Utils.containsValue(DialogueText.COMMANDS, command) or super:isModifier(self, command)
end

function DialogueText:processModifier(node)
    super:processModifier(self, node)

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
            self.state.typed_characters = self.state.typed_characters + 1
        else
            self.state.progress = self.state.progress - tonumber(delay)
        end
    elseif node.command == "voice" then
        if node.arguments[1] == "reset" then
            self.state.typing_sound = "default"
        else
            self.state.typing_sound = node.arguments[1]
        end
    end
end

return DialogueText