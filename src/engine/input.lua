local Input = {}
local self = Input

Input.key_down = {}
Input.key_pressed = {}
Input.key_released = {}

Input.aliases = {}

Input.order = {
    "down", "right", "up", "left", "confirm", "cancel", "menu", "console", "debug_menu", "object_selector", "fast_forward"
}

Input.key_groups = {
    ["shift"] = {"lshift", "rshift"},
    ["ctrl"]  = {"lctrl",  "rctrl"},
    ["alt"]   = {"lalt",   "ralt"},
    ["cmd"]   = {"lgui",   "rgui"}
}

Input.group_for_key = {
    ["lshift"] = "shift",
    ["rshift"] = "shift",
    ["lctrl"]  = "ctrl",
    ["rctrl"]  = "ctrl",
    ["lalt"]   = "alt",
    ["ralt"]   = "alt",
    ["lgui"]   = "cmd",
    ["rgui"]   = "cmd"
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
        ["console"] = {"`"},
        ["debug_menu"] = {{"shift", "`"}},
        ["object_selector"] = {{"ctrl", "o"}},
        ["fast_forward"] = {{"ctrl", "g"}}
    }

    if (reset == nil) or (reset == false) then
        if love.filesystem.getInfo("keybinds.json") then
            local user_binds = JSON.decode(love.filesystem.read("keybinds.json"))
            for k,v in pairs(user_binds) do
                local new_bind = {}
                for _,key in ipairs(v) do
                    local split = Utils.split(key, "+")
                    if #split > 1 then
                        table.insert(new_bind, split)
                    else
                        table.insert(new_bind, key)
                    end
                end
                defaults[k] = new_bind
            end
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
    local saved_binds = {}
    for k,v in pairs(Input.aliases) do
        local new_bind = {}
        for _,key in ipairs(v) do
            if type(key) == "table" then
                table.insert(new_bind, table.concat(key, "+"))
            else
                table.insert(new_bind, key)
            end
        end
        saved_binds[k] = new_bind
    end
    love.filesystem.write("keybinds.json", JSON.encode(saved_binds))
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
            if Utils.equal(lkey, key) then
                if (#self.aliases[aliasname] == 1 and not old_key) or (aliasname == alias and index > #self.aliases[alias]) then
                    return false
                elseif old_key ~= nil then
                    self.aliases[aliasname][keyindex] = old_key
                else
                    table.remove(self.aliases[aliasname], keyindex)
                end
            end
        end
    end
    self.aliases[alias][index] = key
    return true
end

function Input.clear(key, clear_down)
    if key then
        if self.aliases[key] then
            for _,k in ipairs(self.aliases[key]) do
                local keys = type(k) == "table" and k or {k}
                for _,l in ipairs(keys) do
                    self.key_pressed[l] = false
                    self.key_released[l] = false
                    if clear_down then
                        self.key_down[l] = false
                    end
                end
            end
            return false
        elseif self.key_groups[key] then
            for _,k in ipairs(self.key_groups[key]) do
                self.key_pressed[k] = false
                self.key_released[k] = false
                if clear_down then
                    self.key_down[k] = false
                end
            end
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
    if self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if type(k) == "string" and Input.keyDown(k) then
                return true
            elseif type(k) == "table" then
                local success = true
                for _,l in ipairs(k) do
                    if not Input.keyDown(l) then
                        success = false
                    end
                end
                if success then
                    return true
                end
            end
        end
        return false
    else
        return Input.keyDown(key)
    end
end

function Input.keyDown(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_down[k] then
                return true
            end
        end
    end
    return self.key_down[key]
end

function Input.pressed(key)
    if self.aliases[key] then
        for _,k in ipairs(self.aliases[key] or {}) do
            if type(k) == "string" and Input.keyPressed(k) then
                return true
            elseif type(k) == "table" then
                local any_pressed = false
                local any_up = false
                for _,l in ipairs(k) do
                    if Input.keyPressed(l) then
                        any_pressed = true
                    elseif Input.keyUp(l) then
                        any_up = true
                    end
                end
                if any_pressed and not any_up then
                    return true
                end
            end
        end
        return false
    else
        return Input.keyPressed(key)
    end
end

function Input.keyPressed(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_pressed[k] then
                return true
            end
        end
    end
    return self.key_pressed[key]
end

function Input.processKeyPressedFunc(key)
    -- Should this function still be called?
    return Input.keyPressed(key)
    -- This is only a single function call right now, but might need to be expanded in the future
end

function Input.released(key)
    if self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if type(k) == "string" and Input.keyReleased(k) then
                return true
            elseif type(k) == "table" then
                local any_released = false
                local any_up_not_released = false
                for _,l in ipairs(k) do
                    if Input.keyReleased(l) then
                        any_released = true
                    elseif Input.keyUp(l) then
                        any_up_not_released = true
                    end
                end
                if any_released and not any_up_not_released then
                    return true
                end
            end
        end
        return false
    else
        return Input.keyReleased(key)
    end
end

function Input.keyReleased(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_released[k] then
                return true
            end
        end
        return false
    end
    return self.key_released[key]
end

function Input.up(key)
    if self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if type(k) == "string" and Input.keyDown(k) then
                return false
            elseif type(k) == "table" then
                local success = true
                for _,l in ipairs(k) do
                    if not Input.keyDown(l) then
                        success = false
                    end
                end
                if success then
                    return false
                end
            end
        end
        return true
    else
        return Input.keyUp(key)
    end
end

function Input.keyUp(key)
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_down[k] then
                return false
            end
        end
    end
    return not self.key_down[key]
end

function Input.is(alias, key)
    if self.group_for_key[key] then
        key = self.group_for_key[key]
    end
    for _,k in ipairs(self.aliases[alias] or {}) do
        if type(k) == "string" and k == key then
            return true
        elseif type(k) == "table" then
            local success = true
            for _,l in ipairs(k) do
                if l ~= key and not Input.keyDown(l) then
                    success = false
                end
            end
            if success then
                return true
            end
        end
    end
    return false
end

function Input.getText(alias)
    local name = self.aliases[alias] and self.aliases[alias][1] or alias
    name = self.key_groups[alias] and self.key_groups[alias][1] or name
    if type(name) == "table" then
        name = table.concat(name, "+")
    end
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

function Input.gui()
    return self.down("gui")
end

function Input.isConfirm(key)
    return Input.is("confirm", key)
end

function Input.isCancel(key)
    return Input.is("cancel", key)
end

function Input.isMenu(key)
    return Input.is("menu", key)
end

function Input.getMousePosition(x, y, relative)
    local x = x or love.mouse.getX()
    local y = y or love.mouse.getY()
    local off_x, off_y = Kristal.getSideOffsets()
    local floor = math.floor
    if relative then
        floor = Utils.round
        off_x, off_y = 0, 0
    end
    return floor((x - off_x) / Kristal.getGameScale()),
           floor((y - off_y) / Kristal.getGameScale())
end

return self