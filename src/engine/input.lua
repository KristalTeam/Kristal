local Input = {}
local self = Input

Input.key_down = {}
Input.key_pressed = {}
Input.key_released = {}

Input.aliases = {}

Input.order = {
    "down", "right", "up", "left", "confirm", "cancel", "menu"
}

Input.key_groups = {
    ["shift"] = {"lshift", "rshift"},
    ["ctrl"]  = {"lctrl",  "rctrl"},
    ["alt"]   = {"lalt",   "ralt"}
}

Input.group_for_key = {
    ["lshift"] = "shift",
    ["rshift"] = "shift",
    ["lctrl"]  = "ctrl",
    ["rctrl"]  = "ctrl",
    ["lalt"]   = "alt",
    ["ralt"]   = "alt"
}

function Input.getKeysFromAlias(key)
    return Input.aliases[key]
end

function Input.loadBinds(reset)
    local defaults = {
        ["up"] = {"up"},
        ["down"] = {"down"},
        ["left"] = {"left"},
        ["right"] = {"right"},
        ["confirm"] = {"z", "return"},
        ["cancel"] = {"x", "shift"},
        ["menu"] = {"c", "ctrl"},
    }

    if (reset == nil) or (reset == false) then
        if love.filesystem.getInfo("keybinds.json") then
            Utils.merge(defaults, JSON.decode(love.filesystem.read("keybinds.json")))
        end
    end

    Input.aliases = Utils.copy(defaults)
end

function Input.orderedNumberToKey(number)
    if number <= #Input.order then
        return Input.order[number]
    else
        local index = #Input.order + 1
        for name, value in pairs(Input.aliases) do
            if not Utils.containsValue(Input.order, name) then
                if index == number then
                    return name
                end
                index = index + 1
            end
        end
        return nil
    end
end

function Input.saveBinds()
    love.filesystem.write("keybinds.json", JSON.encode(Input.aliases))
end

function Input.setBind(alias, index, key)
    if key == "escape" then
        if #self.aliases[alias] > 1 then
            table.remove(self.aliases[alias], index)
            return true
        else
            return false
        end
    end

    if self.group_for_key[key] then
        key = self.group_for_key[key]
    end

    local old_key = self.aliases[alias][index]

    for aliasname, lalias in pairs(self.aliases) do
        for keyindex, lkey in ipairs(lalias) do
            if lkey == key then
                if index > #self.aliases[alias] then
                    return false
                else
                    self.aliases[aliasname][keyindex] = old_key
                end
            end
        end
    end
    self.aliases[alias][index] = key
    return true
end

function Input.clear(key, clear_down)
    if key then
        if self.key_groups[key] then
            for _,k in ipairs(self.key_groups[key]) do
                self.key_pressed[k] = false
                self.key_released[k] = false
                if clear_down then
                    self.key_down[k] = false
                end
            end
        elseif self.aliases[key] then
            for _,k in ipairs(self.aliases[key]) do
                self.key_pressed[k] = false
                self.key_released[k] = false
                if clear_down then
                    self.key_down[k] = false
                end
            end
            return false
        else
            self.key_pressed[key] = false
            self.key_released[key] = false
            if clear_down then
                self.key_down[key] = false
            end
        end
    else
        self.key_pressed = {}
        self.key_released = {}
        if clear_down then
            self.key_down = {}
        end
    end
end

function Input.onKeyPressed(key)
    self.key_down[key] = true
    self.key_pressed[key] = true
end

function Input.onKeyReleased(key)
    self.key_down[key] = false
    self.key_released[key] = true
end

function Input.down(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if Input.keyDown(k) then
                return true
            end
        end
    elseif self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if Input.keyDown(k) then
                return true
            end
        end
        return false
    else
        return Input.keyDown(key)
    end
end

function Input.keyDown(key)
    return self.key_down[key]
end

function Input.pressed(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if Input.keyPressed(k) then
                return true
            end
        end
    elseif self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if Input.keyPressed(k) then
                return true
            end
        end
        return false
    else
        return Input.keyPressed(key)
    end
end

function Input.keyPressed(key)
    return self.key_pressed[key]
end

function Input.processKeyPressedFunc(key)
    -- Should this function still be called?
    return Input.pressed(key)
    -- This is only a single function call right now, but might need to be expanded in the future
end

function Input.released(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_released[k] then
                return true
            end
        end
    elseif self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if self.key_released[k] then
                return true
            end
        end
        return false
    else
        return self.key_released[key]
    end
end

function Input.keyReleased(key)
    return self.key_released[key]
end

function Input.up(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_down[k] then
                return false
            end
        end
    elseif self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if self.key_down[k] then
                return false
            end
        end
        return true
    else
        return not self.key_down[key]
    end
end

function Input.keyUp(key)
    return not self.key_down[key]
end

function Input.is(alias, key)
    if self.group_for_key[key] then
        return self.aliases[alias] and Utils.containsValue(self.aliases[alias], self.group_for_key[key])
    end
    return self.aliases[alias] and Utils.containsValue(self.aliases[alias], key)
end

function Input.getText(alias)
    local name = self.aliases[alias] and self.aliases[alias][1] or alias
    name = self.key_groups[alias] and self.key_groups[alias][1] or name
    return "["..name:upper().."]"
end

function Input.shift()
    return self.down("shift")
end

function Input.ctrl()
    return self.down("ctrl")
end

function Input.alt()
    return self.down("alt")
end

function Input.isConfirm(key)
    if self.group_for_key[key] then
        if Utils.containsValue(self.aliases["confirm"], self.group_for_key[key]) then
            return true
        end
    end
    return Utils.containsValue(self.aliases["confirm"], key)
end

function Input.isCancel(key)
    if self.group_for_key[key] then
        if Utils.containsValue(self.aliases["cancel"], self.group_for_key[key]) then
            return true
        end
    end
    return Utils.containsValue(self.aliases["cancel"], key)
end

function Input.isMenu(key)
    if self.group_for_key[key] then
        if Utils.containsValue(self.aliases["menu"], self.group_for_key[key]) then
            return true
        end
    end
    return Utils.containsValue(self.aliases["menu"], key)
end

function Input.getMousePosition()
    return love.mouse.getX() / (Kristal.Config["windowScale"] or 1), love.mouse.getY() / (Kristal.Config["windowScale"] or 1)
end

return self