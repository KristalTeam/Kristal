---@class Input
---
---@field active_gamepad love.Joystick
---@field connected_gamepad love.Joystick
---
---@field gamepad_left_x number
---@field gamepad_left_y number
---@field gamepad_right_x number
---@field gamepad_right_y number
---@field gamepad_left_trigger number
---@field gamepad_right_trigger number
---
---@field key_down table<string, boolean>
---@field key_pressed table<string, boolean>
---@field key_repeated table<string, boolean>
---@field key_released table<string, boolean>
---
---@field key_down_timer table<string, number>
---
---@field key_bindings table<string, (string|string[])[]>
---@field gamepad_bindings table<string, (string|string[])[]>
---
---@field stray_key_bindings table<string, (string|string[])[]>
---@field stray_gamepad_bindings table<string, (string|string[])[]>
---
---@field gamepad_locked boolean
---
---@field gamepad_cursor_size number
---@field gamepad_cursor_x number
---@field gamepad_cursor_y number
---
---@field order string[]
---
---@field required_binds table<string, boolean>
---
---@field key_groups table<string, string[]>
---@field group_for_key table<string, string>
---
---@field component_stack Component[]
---
---@field button_sprites table<string, string|{switch:string|nil, ps4:string|nil, xbox:string|nil}>
---
local Input = {}
local self = Input

Input.active_gamepad = nil
Input.connected_gamepad = nil

Input.gamepad_left_x = 0
Input.gamepad_left_y = 0
Input.gamepad_right_x = 0
Input.gamepad_right_y = 0
Input.gamepad_left_trigger = 0
Input.gamepad_right_trigger = 0

Input.key_down = {}
Input.key_pressed = {}
Input.key_repeated = {}
Input.key_released = {}

Input.key_down_timer = {}

Input.key_bindings = {}
Input.gamepad_bindings = {}

Input.stray_key_bindings = {}
Input.stray_gamepad_bindings = {}

Input.gamepad_locked = false

Input.gamepad_cursor_size = 10
Input.gamepad_cursor_x = (love.graphics.getWidth()  / 2) - (Input.gamepad_cursor_size / 2)
Input.gamepad_cursor_y = (love.graphics.getHeight() / 2) - (Input.gamepad_cursor_size / 2)

Input.order = {
    "down", "right", "up", "left", "confirm", "cancel", "menu", "console", "debug_menu", "object_selector", "fast_forward"
}

Input.required_binds = {
    ["down"] = true,
    ["right"] = true,
    ["up"] = true,
    ["left"] = true,
    ["confirm"] = true,
    ["cancel"] = true,
    ["menu"] = true
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

Input.component_stack = {}

---@param stick "left"|"right"
---@param raw? boolean
---@return number x, number y
function Input.getThumbstick(stick, raw)
    local x, y, deadzone
    if stick == "left" then
        x, y = self.gamepad_left_x, self.gamepad_left_y
        deadzone = Kristal.Config["leftStickDeadzone"]
    elseif stick == "right" then
        x, y = self.gamepad_right_x, self.gamepad_right_y
        deadzone = Kristal.Config["rightStickDeadzone"]
    end
    local magnitude = math.sqrt(x * x + y * y)
    if not raw and magnitude > 1 then
        x = x / magnitude
        y = y / magnitude
        magnitude = 1
    end
    if magnitude <= deadzone then
        return 0, 0
    end
    if not raw then
        local magmult = (magnitude - deadzone) / (1 - deadzone)
        x = x * magmult
        y = y * magmult
    end
    return x, y
end

---@return number x, number y
function Input.getLeftThumbstick()
    return Input.getThumbstick("left")
end

---@return number x, number y
function Input.getRightThumbstick()
    return Input.getThumbstick("right")
end

---@return number
function Input.getLeftTrigger()
    return self.gamepad_left_trigger
end

---@return number
function Input.getRightTrigger()
    return self.gamepad_right_trigger
end

---@param key string
---@param gamepad? boolean
---@return (string|string[])[]|nil
function Input.getBoundKeys(key, gamepad)
    if gamepad == nil then
        local key_bindings = Input.key_bindings[key]
        local gamepad_bindings = Input.gamepad_bindings[key]

        if not key_bindings and not gamepad_bindings then
            return nil
        end

        local bindings = {}
        for _,bind in ipairs(key_bindings or {}) do
            table.insert(bindings, bind)
        end
        for _,bind in ipairs(gamepad_bindings or {}) do
            table.insert(bindings, bind)
        end
        return bindings
    elseif gamepad then
        return Input.gamepad_bindings[key]
    else
        return Input.key_bindings[key]
    end
end

---@param gamepad? boolean
function Input.resetBinds(gamepad)
    if gamepad ~= true then
        Input.stray_key_bindings = {}
        Input.key_bindings = {
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
        for _,mod in ipairs(Kristal.Mods.getMods()) do
            if mod.keybinds then
                for _,v in pairs(mod.keybinds) do
                    if v.keys then
                        Input.key_bindings[v.id] = Utils.copy(v.keys)
                    else
                        Input.key_bindings[v.id] = {}
                    end
                end
            end
            if mod.libs then
                for _,lib in pairs(mod.libs) do
                    if lib.keybinds then
                        for _,v in pairs(lib.keybinds) do
                            if v.keys then
                                Input.key_bindings[v.id] = Utils.copy(v.keys)
                            else
                                Input.key_bindings[v.id] = {}
                            end
                        end
                    end
                end
            end
        end
    end

    if gamepad ~= false then
        Input.stray_gamepad_bindings = {}
        Input.gamepad_bindings = {
            ["up"] = {"gamepad:dpup", "gamepad:lsup"},
            ["down"] = {"gamepad:dpdown", "gamepad:lsdown"},
            ["left"] = {"gamepad:dpleft", "gamepad:lsleft"},
            ["right"] = {"gamepad:dpright", "gamepad:lsright"},
            ["confirm"] = {"gamepad:a"},
            ["cancel"] = {"gamepad:b"},
            ["menu"] = {"gamepad:y"},
            ["console"] = {},
            ["debug_menu"] = {},
            ["object_selector"] = {},
            ["fast_forward"] = {},
        }
        for _,mod in ipairs(Kristal.Mods.getMods()) do
            if mod.keybinds then
                for _,v in pairs(mod.keybinds) do
                    if v.gamepad then
                        Input.gamepad_bindings[v.id] = Utils.copy(v.gamepad)
                    else
                        Input.gamepad_bindings[v.id] = {}
                    end
                end
            end
            if mod.libs then
                for _,lib in pairs(mod.libs) do
                    if lib.keybinds then
                        for _,v in pairs(lib.keybinds) do
                            if v.gamepad then
                                Input.gamepad_bindings[v.id] = Utils.copy(v.gamepad)
                            else
                                Input.gamepad_bindings[v.id] = {}
                            end
                        end
                    end
                end
            end
        end
    end
end

function Input.loadBinds()
    Input.resetBinds()

    if love.filesystem.getInfo("keybinds.json") then
        local user_binds = JSON.decode(love.filesystem.read("keybinds.json"))
        for k,v in pairs(user_binds) do
            local key_bind = {}
            local gamepad_bind = {}
            for _,key in ipairs(v) do
                local split = Utils.split(key, "+")
                if #split > 1 then
                    table.insert(key_bind, split)
                elseif Utils.startsWith(key, "gamepad:") then
                    table.insert(gamepad_bind, key)
                else
                    table.insert(key_bind, key)
                end
            end

            if Input.key_bindings[k] then
                Input.key_bindings[k] = key_bind
            else
                Input.stray_key_bindings[k] = key_bind
            end

            if Input.gamepad_bindings[k] then
                Input.gamepad_bindings[k] = gamepad_bind
            else
                Input.stray_gamepad_bindings[k] = gamepad_bind
            end
        end
    end
end

---@param number number
---@return string
function Input.orderedNumberToKey(number)
    if number <= #Input.order then
        return Input.order[number]
    else
        local index = #Input.order + 1
        for name, value in pairs(Input.key_bindings) do
            if not Utils.containsValue(Input.order, name) then
                if index == number then
                    return name
                end
                index = index + 1
            end
        end
        ---@diagnostic disable-next-line: return-type-mismatch
        return nil
    end
end

function Input.saveBinds()
    local all_binds = {}
    for k,v in pairs(Input.key_bindings) do
        all_binds[k] = Utils.copy(v)
    end
    for k,v in pairs(Input.stray_key_bindings) do
        all_binds[k] = Utils.merge(all_binds[k] or {}, v)
    end
    for k,v in pairs(Input.gamepad_bindings) do
        all_binds[k] = Utils.merge(all_binds[k] or {}, v)
    end
    for k,v in pairs(Input.stray_gamepad_bindings) do
        all_binds[k] = Utils.merge(all_binds[k] or {}, v)
    end

    local saved_binds = {}
    for k,v in pairs(all_binds) do
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

---@param alias string
---@param index number
---@param key string
---@param gamepad? boolean
---@return boolean
function Input.setBind(alias, index, key, gamepad)
    local bindings = gamepad and Input.gamepad_bindings or Input.key_bindings

    if key == "escape" then
        if #bindings[alias] > 1 or not Input.required_binds[alias] then
            table.remove(bindings[alias], index)
            return true
        else
            return false
        end
    end

    local is_gamepad_button = Utils.startsWith(key, "gamepad:")
    if is_gamepad_button ~= gamepad or false then
        -- Cannot assign gamepad button to key or vice versa
        return false
    end

    if self.group_for_key[key] then
        key = self.group_for_key[key]
    end

    local old_key = bindings[alias][index]

    for aliasname, lalias in pairs(bindings) do
        for keyindex, lkey in ipairs(lalias) do
            if Utils.equal(lkey, key) then
                if #bindings[aliasname] == 1 and not old_key and Input.required_binds[aliasname] then
                    return false
                elseif aliasname == alias and index > #bindings[alias] then
                    return false
                elseif old_key ~= nil then
                    bindings[aliasname][keyindex] = old_key
                else
                    table.remove(bindings[aliasname], keyindex)
                end
            end
        end
    end

    bindings[alias][index] = key

    return true
end

---@param alias string
---@param gamepad? boolean
---@return string|string[]|nil
function Input.getPrimaryBind(alias, gamepad)
    if gamepad == nil then
        gamepad = Input.usingGamepad()
    end
    local bindings = Input.getBoundKeys(alias, gamepad)
    return bindings and bindings[1] or nil
end

---@param key? string
---@param clear_down? boolean
---@return boolean|nil
function Input.clear(key, clear_down)
    if key then
        local bindings = Input.getBoundKeys(key)
        if bindings then
            for _,k in ipairs(bindings) do
                local keys = type(k) == "table" and k or {k}
                for _,l in ipairs(keys) do
                    self.key_pressed[l] = false
                    self.key_repeated[l] = false
                    self.key_released[l] = false
                    if clear_down then
                        self.key_down[l] = false
                        self.key_down_timer[l] = nil
                    end
                end
            end
            return false
        elseif self.key_groups[key] then
            for _,k in ipairs(self.key_groups[key]) do
                self.key_pressed[k] = false
                self.key_repeated[k] = false
                self.key_released[k] = false
                if clear_down then
                    self.key_down[k] = false
                    self.key_down_timer[k] = nil
                end
            end
        else
            self.key_pressed[key] = false
            self.key_repeated[key] = false
            self.key_released[key] = false
            if clear_down then
                self.key_down[key] = false
                self.key_down_timer[key] = nil
            end
        end
    else
        self.key_pressed = {}
        self.key_repeated = {}
        self.key_released = {}
        if clear_down then
            self.key_down = {}
            self.key_down_timer = {}
        end
    end
end

function love.gamepadaxis(joystick, axis, value)
    local stick_threshold = 0.5
    local trigger_threshold = 0.9

    local threshold = (axis == "triggerleft" or axis == "triggerright") and trigger_threshold or stick_threshold

    if math.abs(value) > threshold then
        Input.active_gamepad = joystick
        Input.connected_gamepad = joystick
    end

	if axis == "leftx" then
        self.gamepad_left_x = value

        local adjusted,_ = Input.getThumbstick("left", true)

        if (adjusted < -threshold) then if not Input.keyDown("gamepad:lsleft" ) then Input.onKeyPressed("gamepad:lsleft" , false) end else if Input.keyDown("gamepad:lsleft" ) then Input.onKeyReleased("gamepad:lsleft" ) end end
        if (adjusted >  threshold) then if not Input.keyDown("gamepad:lsright") then Input.onKeyPressed("gamepad:lsright", false) end else if Input.keyDown("gamepad:lsright") then Input.onKeyReleased("gamepad:lsright") end end

	elseif axis == "lefty" then
        self.gamepad_left_y = value

        local _,adjusted = Input.getThumbstick("left", true)

        if (adjusted < -threshold) then if not Input.keyDown("gamepad:lsup"  ) then Input.onKeyPressed("gamepad:lsup"  , false) end else if Input.keyDown("gamepad:lsup"  ) then Input.onKeyReleased("gamepad:lsup"  ) end end
        if (adjusted >  threshold) then if not Input.keyDown("gamepad:lsdown") then Input.onKeyPressed("gamepad:lsdown", false) end else if Input.keyDown("gamepad:lsdown") then Input.onKeyReleased("gamepad:lsdown") end end

    elseif axis == "rightx" then
        self.gamepad_right_x = value

        local adjusted,_ = Input.getThumbstick("right", true)

        if (adjusted < -threshold) then if not Input.keyDown("gamepad:rsleft" ) then Input.onKeyPressed("gamepad:rsleft" , false) end else if Input.keyDown("gamepad:rsleft" ) then Input.onKeyReleased("gamepad:rsleft" ) end end
        if (adjusted >  threshold) then if not Input.keyDown("gamepad:rsright") then Input.onKeyPressed("gamepad:rsright", false) end else if Input.keyDown("gamepad:rsright") then Input.onKeyReleased("gamepad:rsright") end end

    elseif axis == "righty" then
        self.gamepad_right_y = value

        local _,adjusted = Input.getThumbstick("right", true)

        if (adjusted < -threshold) then if not Input.keyDown("gamepad:rsup"  ) then Input.onKeyPressed("gamepad:rsup"  , false) end else if Input.keyDown("gamepad:rsup"  ) then Input.onKeyReleased("gamepad:rsup"  ) end end
        if (adjusted >  threshold) then if not Input.keyDown("gamepad:rsdown") then Input.onKeyPressed("gamepad:rsdown", false) end else if Input.keyDown("gamepad:rsdown") then Input.onKeyReleased("gamepad:rsdown") end end

    elseif axis == "triggerleft" then
        self.gamepad_left_trigger = value

        if (value > threshold) then if not Input.keyDown("gamepad:lefttrigger") then Input.onKeyPressed("gamepad:lefttrigger", false) end else if Input.keyDown("gamepad:lefttrigger") then Input.onKeyReleased("gamepad:lefttrigger") end end

    elseif axis == "triggerright" then
        self.gamepad_right_trigger = value

        if (value > threshold) then if not Input.keyDown("gamepad:righttrigger") then Input.onKeyPressed("gamepad:righttrigger", false) end else if Input.keyDown("gamepad:righttrigger") then Input.onKeyReleased("gamepad:righttrigger") end end
    end
end

---@param key string
---@param is_repeat boolean
function Input.onKeyPressed(key, is_repeat)
    if not is_repeat then
        self.key_down[key] = true
        self.key_pressed[key] = true

        self.key_repeated[key] = false
        self.key_down_timer[key] = 0
    end

    Kristal.onKeyPressed(key, is_repeat)
end

---@param key string
function Input.onKeyReleased(key)
    self.key_down[key] = false
    self.key_released[key] = true

    self.key_repeated[key] = false
    self.key_down_timer[key] = nil

    Kristal.onKeyReleased(key)
end

---@param x number
---@param y number
function Input.onWheelMoved(x, y)
    Kristal.onWheelMoved(x, y)
end

function Input.update()
    -- Clear input from last frame
    Input.clear()

    for key,down in pairs(self.key_down) do
        if down then
            self.key_down_timer[key] = self.key_down_timer[key] + BASE_DT
            if self.key_down_timer[key] >= KEY_REPEAT_DELAY then
                self.key_repeated[key] = true
                self.key_down_timer[key] = self.key_down_timer[key] - KEY_REPEAT_INTERVAL
                Input.onKeyPressed(key, true)
            end
        end
    end
end

---@return boolean
function Input.usingGamepad()
    return Input.active_gamepad ~= nil
end

---@return boolean
function Input.hasGamepad()
    return Input.connected_gamepad ~= nil
end

function love.joystickadded(joystick)
    Input.connected_gamepad = joystick
    Input.active_gamepad = joystick
end

function love.joystickremoved(joystick)
    if Input.active_gamepad == joystick then
        Input.active_gamepad = nil
    end
    if Input.connected_gamepad == joystick then
        Input.connected_gamepad = love.joystick.getJoysticks()[1]
    end
end

function love.gamepadpressed(joystick, button)
    Input.active_gamepad = joystick
    Input.connected_gamepad = joystick
    Input.onKeyPressed("gamepad:" .. button, false)
end

function love.gamepadreleased(joystick, button)
    Input.onKeyReleased("gamepad:" .. button)
end

function love.wheelmoved(x, y)
    Input.onWheelMoved(x, y)
end

---@param key string
---@return boolean
function Input.down(key)
    local bindings = Input.getBoundKeys(key)
    if bindings then
        for _,k in ipairs(bindings) do
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

---@param key string
---@return boolean
function Input.keyDown(key)
    if self.gamepad_locked and Input.isGamepad(key) then return false end
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_down[k] then
                return true
            end
        end
    end
    return self.key_down[key]
end

---@param key string
---@param repeatable? boolean
---@return boolean
function Input.pressed(key, repeatable)
    local bindings = Input.getBoundKeys(key)
    if bindings then
        for _,k in ipairs(bindings) do
            if type(k) == "string" and Input.keyPressed(k, repeatable) then
                return true
            elseif type(k) == "table" then
                local any_pressed = false
                local any_up = false
                for _,l in ipairs(k) do
                    if Input.keyPressed(l, repeatable) then
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
        return Input.keyPressed(key, repeatable)
    end
end

---@param key string
---@param repeatable? boolean
---@return boolean
function Input.keyPressed(key, repeatable)
    if self.gamepad_locked and Input.isGamepad(key) then return false end
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_pressed[k] or (repeatable and self.key_repeated[k]) then
                return true
            end
        end
    end
    return self.key_pressed[key] or (repeatable and self.key_repeated[key]) or false
end

---@param key string
---@param repeatable? boolean
---@return boolean
function Input.shouldProcess(key, repeatable)
    -- Should this function still be called?
    return Input.keyPressed(key, repeatable)
    -- This is only a single function call right now, but might need to be expanded in the future
end

---@param key string
---@return boolean
function Input.released(key)
    local bindings = Input.getBoundKeys(key)
    if bindings then
        for _,k in ipairs(bindings) do
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

---@param key string
---@return boolean
function Input.keyReleased(key)
    if self.gamepad_locked and Input.isGamepad(key) then return false end
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

---@param key string
---@return boolean
function Input.up(key)
    local bindings = Input.getBoundKeys(key)
    if bindings then
        for _,k in ipairs(bindings) do
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

---@param key string
---@return boolean
function Input.keyUp(key)
    if self.gamepad_locked and Input.isGamepad(key) then return true end
    if self.key_groups[key] then
        for _,k in ipairs(self.key_groups[key]) do
            if self.key_down[k] then
                return false
            end
        end
    end
    return not self.key_down[key]
end

---@param alias string
---@param key string
---@return boolean
function Input.is(alias, key)
    if self.group_for_key[key] then
        key = self.group_for_key[key]
    end
    for _,k in ipairs(Input.getBoundKeys(alias) or {}) do
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

---@param alias string
---@param gamepad? boolean
---@return string
function Input.getText(alias, gamepad)
    local name = Input.getPrimaryBind(alias, gamepad) or "unbound"
    name = self.key_groups[alias] and self.key_groups[alias][1] or name
    if type(name) == "table" then
        name = table.concat(name, "+")
    else
        local is_gamepad, gamepad_button = Utils.startsWith(name, "gamepad:")
        if is_gamepad then
            return "[button:" .. gamepad_button .. "]"
        end
    end
    return "["..name:upper().."]"
end

---@param alias string
---@param gamepad? boolean
---@return love.Image
function Input.getTexture(alias, gamepad)
    local name = Input.getPrimaryBind(alias, gamepad) or "unbound"
    name = self.key_groups[alias] and self.key_groups[alias][1] or name

    local is_gamepad, gamepad_button = Utils.startsWith(name, "gamepad:")
    if is_gamepad then
        return Input.getButtonTexture(gamepad_button)
    end

    return Assets.getTexture("kristal/buttons/unknown")
end

---@return "switch"|"ps4"|"xbox"|nil
function Input.getControllerType()
    if not Input.connected_gamepad then return nil end

    local name = Input.connected_gamepad:getName():lower()

    local con = function(str) return Utils.contains(name, str) end
    if con("nintendo") or con("switch") or con("joy-con") or con("wii") or con("gamecube") or con("nso") or con("nes") then
        return "switch"
    end
    if con("sony") or con("playstation") or con("%f[%a]ps") or con("dualshock") or con("dualsense") or con("dualforce") then
        return "ps4"
    end
    return "xbox"
end

---@param bind string
---@return string? name
function Input.getBindName(bind)
    for k,v in pairs(Kristal.Mods.getMods()) do
        if v.keybinds then
            for _,modBind in pairs(v.keybinds) do
                if modBind.id == bind then
                    return modBind.name
                end
            end
        end
        if v.libs then
            for _,lib in pairs(v.libs) do
                if lib.keybinds then
                    for _,modBind in pairs(lib.keybinds) do
                        if modBind.id == bind then
                            return modBind.name
                        end
                    end
                end
            end
        end
    end
    return nil
end

---@param button string
---@return love.Image
function Input.getButtonTexture(button)
    return Assets.getTexture("kristal/buttons/" .. Input.getButtonSprite(button))
end

Input.button_sprites = {
    ["lsleft"]  = "common/left_stick_left",
    ["lsright"] = "common/left_stick_right",
    ["lsup"]    = "common/left_stick_up",
    ["lsdown"]  = "common/left_stick_down",

    ["rsleft"]  = "common/right_stick_left",
    ["rsright"] = "common/right_stick_right",
    ["rsup"]    = "common/right_stick_up",
    ["rsdown"]  = "common/right_stick_down",

    ["dpleft"]  = {switch = "switch/left",  ps4 = "ps4/dpad_left",  xbox = "xbox/left"},
    ["dpright"] = {switch = "switch/right", ps4 = "ps4/dpad_right", xbox = "xbox/right"},
    ["dpup"]    = {switch = "switch/up",    ps4 = "ps4/dpad_up",    xbox = "xbox/up"},
    ["dpdown"]  = {switch = "switch/down",  ps4 = "ps4/dpad_down",  xbox = "xbox/down"},

    ["a"]       = {switch = "switch/a", ps4 = "ps4/cross",    xbox = "xbox/a"},
    ["b"]       = {switch = "switch/b", ps4 = "ps4/circle",   xbox = "xbox/b"},
    ["x"]       = {switch = "switch/x", ps4 = "ps4/square",   xbox = "xbox/x"},
    ["y"]       = {switch = "switch/y", ps4 = "ps4/triangle", xbox = "xbox/y"},

    ["start"]   = {switch = "switch/plus",  ps4 = "ps4/options", xbox = "xbox/menu"},
    ["back"]    = {switch = "switch/minus", ps4 = "ps4/share",   xbox = "xbox/view"},
    ["guide"]   = {switch = "switch/home",  ps4 = "ps4/ps",      xbox = "xbox/xbox"},

    ["leftshoulder"]  = {switch = "switch/l",           ps4 = "ps4/l1", xbox = "xbox/left_bumper"},
    ["rightshoulder"] = {switch = "switch/r",           ps4 = "ps4/r1", xbox = "xbox/right_bumper"},
    ["lefttrigger"]   = {switch = "switch/zl",          ps4 = "ps4/l2", xbox = "xbox/left_trigger"},
    ["righttrigger"]  = {switch = "switch/zr",          ps4 = "ps4/r2", xbox = "xbox/right_trigger"},
    ["leftstick"]     = {switch = "switch/lStickClick", ps4 = "ps4/l3", xbox = "xbox/left_stick"},
    ["rightstick"]    = {switch = "switch/rStickClick", ps4 = "ps4/r3", xbox = "xbox/right_stick"},
}

---@param button string
---@return string
function Input.getButtonSprite(button)
    --local invert = false

    local controller_type = Input.getControllerType() or "xbox"

    --[[local cb = function(str)
        if invert then
            return str .. "_dark"
        end
        return str
    end]]

    -- Get the button name without the "gamepad:" prefix
    local _, short = Utils.startsWith(button, "gamepad:")

    local sprite = Input.button_sprites[short]

    if type(sprite) == "table" then
        return sprite[controller_type] or "unknown"
    else
        return sprite or "unknown"
    end
end

--[[
    local is_dualshock = (os_type == os_ps4 || obj_gamecontroller.gamepad_type == true)
            var button_sprite = button_questionmark
            var invert = (is_dualshock && (global.typer == 50 || global.typer == 70 || global.typer == 71))
            if isString
            {
                if (control == "A")
                {
                    button_sprite = button_xbox_left
                    if (os_type == os_switch)
                        button_sprite = button_switch_left_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_left_dark : button_ps4_dpad_left)
                    return button_sprite;
                }
                if (control == "D")
                {
                    button_sprite = button_xbox_right
                    if (os_type == os_switch)
                        button_sprite = button_switch_right_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_right_dark : button_ps4_dpad_right)
                    return button_sprite;
                }
                if (control == "W")
                {
                    button_sprite = button_xbox_up
                    if (os_type == os_switch)
                        button_sprite = button_switch_up_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_up_dark : button_ps4_dpad_up)
                    return button_sprite;
                }
                if (control == "S")
                {
                    button_sprite = button_xbox_down
                    if (os_type == os_switch)
                        button_sprite = button_switch_down_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_down_dark : button_ps4_dpad_down)
                    return button_sprite;
                }
                if (control == "Z")
                    button = global.button0
                if (control == "X")
                    button = global.button1
                if (control == "C")
                    button = global.button2
            }
            else
            {
                button = control
                if (control == gp_padl)
                {
                    button_sprite = button_xbox_left
                    if (os_type == os_switch)
                        button_sprite = button_switch_left_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_left_dark : button_ps4_dpad_left)
                    return button_sprite;
                }
                if (control == gp_padr)
                {
                    button_sprite = button_xbox_right
                    if (os_type == os_switch)
                        button_sprite = button_switch_right_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_right_dark : button_ps4_dpad_right)
                    return button_sprite;
                }
                if (control == gp_padu)
                {
                    button_sprite = button_xbox_up
                    if (os_type == os_switch)
                        button_sprite = button_switch_up_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_up_dark : button_ps4_dpad_up)
                    return button_sprite;
                }
                if (control == gp_padd)
                {
                    button_sprite = button_xbox_down
                    if (os_type == os_switch)
                        button_sprite = button_switch_down_0
                    else if is_dualshock
                        button_sprite = (invert ? button_ps4_dpad_down_dark : button_ps4_dpad_down)
                    return button_sprite;
                }
            }
            if (button == gp_face1)
            {
                button_sprite = button_xbox_a
                if is_dualshock
                    button_sprite = button_ps4_cross_0
                if (os_type == os_switch)
                    button_sprite = button_switch_b_0
                return button_sprite;
            }
            if (button == gp_face2)
            {
                button_sprite = button_xbox_b
                if is_dualshock
                    button_sprite = button_ps4_circle_0
                if (os_type == os_switch)
                    button_sprite = button_switch_a_0
                return button_sprite;
            }
            if (button == gp_face3)
            {
                button_sprite = button_xbox_x
                if is_dualshock
                    button_sprite = button_ps4_square_0
                if (os_type == os_switch)
                    button_sprite = button_switch_y_0
                return button_sprite;
            }
            if (button == gp_face4)
            {
                button_sprite = button_xbox_y
                if is_dualshock
                    button_sprite = button_ps4_triangle_0
                if (os_type == os_switch)
                    button_sprite = button_switch_x_0
                return button_sprite;
            }
            if (button == gp_shoulderl)
            {
                button_sprite = button_xbox_left_bumper
                if is_dualshock
                    button_sprite = button_ps4_l1
                if (os_type == os_switch)
                    button_sprite = button_switch_l_0
                return button_sprite;
            }
            if (button == gp_shoulderlb)
            {
                button_sprite = button_xbox_left_trigger
                if is_dualshock
                    button_sprite = button_ps4_l2
                if (os_type == os_switch)
                    button_sprite = button_switch_zl_0
                return button_sprite;
            }
            if (button == gp_shoulderr)
            {
                button_sprite = button_xbox_right_bumper
                if is_dualshock
                    button_sprite = button_ps4_r1
                if (os_type == os_switch)
                    button_sprite = button_switch_r_0
                return button_sprite;
            }
            if (button == gp_shoulderrb)
            {
                button_sprite = button_xbox_right_trigger
                if is_dualshock
                    button_sprite = button_ps4_r2
                if (os_type == os_switch)
                    button_sprite = button_switch_zr_0
                return button_sprite;
            }
            if (button == gp_stickl)
            {
                button_sprite = button_xbox_left_stick
                if is_dualshock
                    button_sprite = button_ps4_l3_0
                if (os_type == os_switch)
                    button_sprite = button_switch_lStickClick_0
                return button_sprite;
            }
            if (button == gp_stickr)
            {
                button_sprite = button_xbox_right_stick
                if is_dualshock
                    button_sprite = button_ps4_r3_0
                if (os_type == os_switch)
                    button_sprite = button_switch_rStickClick_0
                return button_sprite;
            }
            if (button == gp_select)
            {
                button_sprite = button_xbox_menu
                if is_dualshock
                    button_sprite = button_ps4_touchpad
                if (os_type == os_switch)
                    button_sprite = button_switch_minus_0
                return button_sprite;
            }
            if (button == gp_start)
            {
                button_sprite = button_xbox_share
                if is_dualshock
                    return button_ps4_options;
                if (os_type == os_switch)
                    button_sprite = button_switch_plus_0
                return button_sprite;
            }
            if (button == gp_padl)
            {
                button_sprite = button_xbox_left
                if (os_type == os_switch)
                    button_sprite = button_switch_left_0
                else if is_dualshock
                    button_sprite = (invert ? button_ps4_dpad_left_dark : button_ps4_dpad_left)
                return button_sprite;
            }
            if (button == gp_padr)
            {
                button_sprite = button_xbox_right
                if (os_type == os_switch)
                    button_sprite = button_switch_right_0
                else if is_dualshock
                    button_sprite = (invert ? button_ps4_dpad_right_dark : button_ps4_dpad_right)
                return button_sprite;
            }
            if (button == gp_padu)
            {
                button_sprite = button_xbox_up
                if (os_type == os_switch)
                    button_sprite = button_switch_up_0
                else if is_dualshock
                    button_sprite = (invert ? button_ps4_dpad_up_dark : button_ps4_dpad_up)
                return button_sprite;
            }
            if (button == gp_padd)
            {
                button_sprite = button_xbox_down
                if (os_type == os_switch)
                    button_sprite = button_switch_down_0
                else if is_dualshock
                    button_sprite = (invert ? button_ps4_dpad_down_dark : button_ps4_dpad_down)
                return button_sprite;
            }
            return button_sprite;
        }
        
        
]]

---@return boolean
function Input.shift()
    return self.down("shift")
end

---@return boolean
function Input.ctrl()
    return self.down("ctrl")
end

---@return boolean
function Input.alt()
    return self.down("alt")
end

---@return boolean
function Input.gui()
    return self.down("gui")
end

---@param key string
---@return boolean
function Input.isConfirm(key)
    return Input.is("confirm", key)
end

---@param key string
---@return boolean
function Input.isCancel(key)
    return Input.is("cancel", key)
end

---@param key string
---@return boolean
function Input.isMenu(key)
    return Input.is("menu", key)
end

---@param key string
---@param which? "left"|"right"
---@return boolean
function Input.isThumbstick(key, which)
    return ((not which or which == "left") and (
            key == "gamepad:lsleft" or
            key == "gamepad:lsright" or
            key == "gamepad:lsup" or
            key == "gamepad:lsdown")) or
        ((not which or which == "right") and (
            key == "gamepad:rsleft" or
            key == "gamepad:rsright" or
            key == "gamepad:rsup" or
            key == "gamepad:rsdown"))
end

---@param key string
---@return boolean gamepad, string button
function Input.isGamepad(key)
    return Utils.startsWith(key, "gamepad:")
end

---@param x? number
---@param y? number
---@param relative? boolean
---@return number x, number y
function Input.getMousePosition(x, y, relative)
    x = x or love.mouse.getX()
    y = y or love.mouse.getY()
    local off_x, off_y = Kristal.getSideOffsets()
    local floor = math.floor
    if relative then
        floor = Utils.round
        off_x, off_y = 0, 0
    end
    return floor((x - off_x) / Kristal.getGameScale()),
           floor((y - off_y) / Kristal.getGameScale())
end

---@param x? number
---@param y? number
---@param relative? boolean
---@return number x, number y
function Input.getGamepadCursorPosition(x, y, relative)
    x = x or (self.gamepad_cursor_x * Kristal.getGameScale())
    y = y or (self.gamepad_cursor_y * Kristal.getGameScale())
    local off_x, off_y = Kristal.getSideOffsets()
    local floor = math.floor
    if relative then
        floor = Utils.round
        off_x, off_y = 0, 0
    end
    return floor((x - off_x) / Kristal.getGameScale()),
           floor((y - off_y) / Kristal.getGameScale())
end

---@param x? number
---@param y? number
---@param relative? boolean
---@return number x, number y
function Input.getCurrentCursorPosition(x, y, relative)
    if self.usingGamepad() then
        return self.getGamepadCursorPosition(x, y, relative)
    end
    return self.getMousePosition(x, y, relative)
end

return self