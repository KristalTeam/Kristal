---@class DialogueText : Text
---@overload fun(...) : DialogueText
local DialogueText, super = Class(Text)

DialogueText.COMMANDS = { "voice", "noskip", "speed", "instant", "stopinstant", "wait", "func", "talk", "sound", "next" }

function DialogueText:init(text, x, y, w, h, options)
    if type(w) == "table" then
        options = w
        w, h = SCREEN_WIDTH, SCREEN_HEIGHT
    end
    options = options or {}

    options["font"] = options["font"] or "main_mono"
    options["style"] = options["style"] or (Game:isLight() and "none" or "dark")
    options["line_offset"] = options["line_offset"] or 8

    self.custom_command_wait = {}
    if type(text) == "string" then
        text = { text }
    end
    self.fast_skipping_timer = 0
    self.played_first_sound = false
    super.init(self, text, x or 0, y or 0, w or SCREEN_WIDTH, h or SCREEN_HEIGHT, options)
    self.skippable = true
    self.skip_speed = false
    self.talk_sprite = nil
    self.last_talking = false
    self.functions = {}
    self.text_table = text

    self.can_advance = true
    self.auto_advance = false
    self.advance_callback = nil
    self.line_callback = nil
    self.line_index = 1

    self.done = false

    self.should_advance = false
end

function DialogueText:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Node count: " .. #self.nodes)
    table.insert(info, "Progress: " .. math.floor(self.state.progress))
    table.insert(info, "Current node: " .. self.state.current_node)
    table.insert(info, "Waiting: " .. self.state.waiting)
    table.insert(info, "Typed characters: " .. self.state.typed_characters)
    return info
end

function DialogueText:resetState()
    super.resetState(self)
    self.state["typing_sound"] = "default"
end

function DialogueText:processInitialNodes()
    self:drawToCanvas(function ()
                          local i = 1
                          while i <= #self.nodes do
                              local current_node = self.nodes[i]
                              self:processNode(current_node, false)
                              self.state.current_node = self.state.current_node + 1
                              self.state.progress = self.state.typed_characters
                              i = i + 1
                              -- If the current mode is a typewriter...
                              if not self.state.skipping and not self:isNodeInstant(current_node) then
                                  break
                              end
                          end
                      end, true)
end

function DialogueText:setText(text, callback, line_callback)
    for _, sprite in ipairs(self.sprites) do
        sprite:remove()
    end
    self.sprites = {}

    self.advance_callback = callback or nil
    self.line_callback = line_callback or nil
    if self.line_callback then
        self.line_callback(self.line_index)
    end
    self:resetState()
    self:updateTalkSprite(false)

    if self.fast_skipping_timer >= 1 then
        self.fast_skipping_timer = self.fast_skipping_timer - 1
    end

    if type(text) == "string" then
        text = { text }
    end

    self.text_table = text or {}
    self.text = self.text_table[1] or ""

    self.last_talking = false

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

    self.played_first_sound = false

    self.done = false

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

function DialogueText:advance()
    self.line_index = self.line_index + 1
    if #self.text_table <= 1 then
        if not self.done then
            self.done = true
            self.line_index = 1
            if self.advance_callback then
                self.advance_callback()
            end
        end
    else
        table.remove(self.text_table, 1)
        self:setText(self.text_table, self.advance_callback, self.line_callback)
    end
end

function DialogueText:update()
    local speed = self.state.speed

    if not OVERLAY_OPEN then
        if Input.pressed("menu") then
            self.fast_skipping_timer = 1
        end

        local input = self.can_advance and
            (Input.pressed("confirm") or (Input.down("menu") and self.fast_skipping_timer >= 1))

        if input or self.auto_advance or self.should_advance then
            self.should_advance = false
            if not self.state.typing then
                self:advance()
            end
        end

        if Input.down("menu") then
            if self.fast_skipping_timer < 1 then
                self.fast_skipping_timer = self.fast_skipping_timer + DTMULT
            end
        else
            self.fast_skipping_timer = 0
        end

        if self.skippable and ((Input.down("cancel") and not self.state.noskip) or (Input.down("menu") and not self.state.noskip)) then
            if not self.skip_speed then
                self.state.skipping = true
            else
                speed = speed * 2
            end
        end
    end

    if self.state.waiting == 0 then
        self.state.progress = self.state.progress + (DT * 30 * speed)
    else
        self.state.waiting = math.max(0, self.state.waiting - DT)
    end

    if self.state.typing then
        self:drawToCanvas(function ()
            while (math.floor(self.state.progress) > self.state.typed_characters) or self.state.skipping do
                local current_node = self.nodes[self.state.current_node]

                if current_node == nil then
                    self.state.typing = false
                    break
                end

                self:playTextSound(current_node)
                self:processNode(current_node, false)

                if self.state.skipping then
                    self.state.progress = self.state.typed_characters
                end

                self.state.current_node = self.state.current_node + 1
            end
        end)
    end

    self:updateTalkSprite(self.state.talk_anim and self.state.typing)

    super.update(self)

    self.last_talking = self.state.talk_anim and self.state.typing
end

function DialogueText:updateTalkSprite(typing)
    if self.talk_sprite then
        local can_talk, talk_speed = true, 0.25
        if self.talk_sprite:includes(ActorSprite) then
            if typing and not self.last_talking then
                self.talk_sprite.actor:onTalkStart(self, self.talk_sprite)
            end
            can_talk, talk_speed = self.talk_sprite:canTalk()
        end
        if can_talk then
            if typing and not self.talk_sprite.playing then
                self.talk_sprite:play(talk_speed, true)
            elseif self.last_talking and not typing then
                if self.talk_sprite.playing then
                    self.talk_sprite:stop()
                end
                if self.talk_sprite:includes(ActorSprite) then
                    self.talk_sprite.actor:onTalkEnd(self, self.talk_sprite)
                end
            end
        elseif self.last_talking and not typing then
            if self.talk_sprite:includes(ActorSprite) then
                self.talk_sprite.actor:onTalkEnd(self, self.talk_sprite)
            end
        end
    end
end

function DialogueText:playTextSound(current_node)
    if self.state.skipping and (Input.down("cancel") or self.played_first_sound) then
        return
    end

    if current_node.type ~= "character" then
        return
    end

    local no_sound = { "\n", " ", "^", "!", ".", "?", ",", ":", "/", "\\", "|", "*" }

    if (Utils.containsValue(no_sound, current_node.character)) then
        return
    end

    if (self.state.typing_sound ~= nil) and (self.state.typing_sound ~= "") then
        self.played_first_sound = true
        if Kristal.callEvent(KRISTAL_EVENT.onTextSound, self.state.typing_sound, current_node) then
            return
        end
        Assets.playSound("voice/" .. self.state.typing_sound)
    end
end

function DialogueText:isNodeInstant(node)
    if node.type == "character" then
        return false
    elseif node.type == "modifier" then
        if self.custom_command_wait[node.command] then
            return false
        elseif node.command == "wait" then
            return false
        elseif node.command == "image" then
            return false
        elseif node.command == "button" then
            return false
        end
    end
    return true
end

function DialogueText:isModifier(command)
    return Utils.containsValue(DialogueText.COMMANDS, command) or super.isModifier(self, command)
end

function DialogueText:registerCommand(command, func, options)
    options = options or {}
    super.registerCommand(self, command, func, options)
    self.custom_command_wait[command] = options["instant"] ~= false
end

function DialogueText:processCustomCommand(node, dry)
    local result = super.processCustomCommand(self, node, dry)
    if self.custom_command_wait[node.command] then
        self.state.typed_characters = self.state.typed_characters + 1
    end
    return result
end

function DialogueText:processModifier(node, dry)
    super.processModifier(self, node, dry)

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
            self.state.waiting = tonumber(delay:sub(1, -1)) / 30
            self.state.typed_characters = self.state.typed_characters + 1
        end
    elseif node.command == "image" then
        self.state.typed_characters = self.state.typed_characters + 1
        if not dry then
            self:playTextSound({ character = "a", type = "character" })
        end
    elseif node.command == "voice" then
        if node.arguments[1] == "reset" then
            self.state.typing_sound = "default"
        elseif node.arguments[1] == "none" then
            self.state.typing_sound = nil
        else
            self.state.typing_sound = node.arguments[1]
        end
    elseif node.command == "noskip" then
        if node.arguments[1] then
            self.state.noskip = self:isTrue(node.arguments[1])
        else
            self.state.noskip = true
        end
    elseif node.command == "func" then
        if dry then return end -- Functions shouldn't be used to modify state so never run them if dry
        local func = tonumber(node.arguments[1]) or node.arguments[1]
        if self.functions[func] then
            local args = {}
            for i = 2, #node.arguments do
                table.insert(args, node.arguments[i])
            end
            self.functions[func](self, unpack(args))
        end
    elseif node.command == "talk" then
        self.state.talk_anim = self:isTrue(node.arguments[1])
    elseif node.command == "sound" then
        if not dry then
            Assets.playSound(node.arguments[1], tonumber(node.arguments[2] or "1"), tonumber(node.arguments[3] or "1"))
        end
    elseif node.command == "next" then
        if not dry then
            self.should_advance = true
        end
    elseif node.command == "button" then
        self.state.typed_characters = self.state.typed_characters + 1
        if not dry then
            self:playTextSound({ character = "a", type = "character" })
        end
    end
end

function DialogueText:addFunction(id, func)
    if id then
        self.functions[id] = func
    else
        table.insert(self.functions, func)
    end
end

function DialogueText:isTyping()
    return self.state.typing
end

function DialogueText:isDone()
    return self.done
end

return DialogueText
