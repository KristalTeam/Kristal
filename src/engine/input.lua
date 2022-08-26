local Input = {}
local self = Input

Input.active_gamepad = nil

Input.gamepad_left_x = 0
Input.gamepad_left_y = 0

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
        ["up"] = {"up", "gamepad:dpup", "gamepad:up"},
        ["down"] = {"down", "gamepad:dpdown", "gamepad:down"},
        ["left"] = {"left", "gamepad:dpleft", "gamepad:left"},
        ["right"] = {"right", "gamepad:dpright", "gamepad:right"},
        ["confirm"] = {"z", "return", "gamepad:a"},
        ["cancel"] = {"x", "shift", "gamepad:b"},
        ["menu"] = {"c", "ctrl", "gamepad:y"},
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

function love.gamepadaxis(joystick, axis, value)
    Input.active_gamepad = joystick
    local threshold = 0.5
	if axis == "leftx" then
        self.gamepad_left_x = value

        if (value < -threshold) then if not Input.keyDown("gamepad:left" ) then Input.onKeyPressed("gamepad:left" , false) end else if Input.keyDown("gamepad:left" ) then Input.onKeyReleased("gamepad:left" ) end end
        if (value >  threshold) then if not Input.keyDown("gamepad:right") then Input.onKeyPressed("gamepad:right", false) end else if Input.keyDown("gamepad:right") then Input.onKeyReleased("gamepad:right") end end

	elseif axis == "lefty" then
        self.gamepad_left_y = value

        if (value < -threshold) then if not Input.keyDown("gamepad:up"  ) then Input.onKeyPressed("gamepad:up"  , false) end else if Input.keyDown("gamepad:up"  ) then Input.onKeyReleased("gamepad:up"  ) end end
        if (value >  threshold) then if not Input.keyDown("gamepad:down") then Input.onKeyPressed("gamepad:down", false) end else if Input.keyDown("gamepad:down") then Input.onKeyReleased("gamepad:down") end end
	end
end

function Input.onKeyPressed(key, is_repeat)
    self.key_down[key] = true
    self.key_pressed[key] = true

    local state = Kristal.getState()
    if state.onKeyPressed then
        state:onKeyPressed(key, is_repeat)
    end
end

function Input.onKeyReleased(key)
    self.key_down[key] = false
    self.key_released[key] = true

    local state = Kristal.getState()
    if state.onKeyReleased then
        state:onKeyReleased(key)
    end
end

function Input.usingGamepad()
    return Input.active_gamepad ~= nil
end

function love.gamepadpressed(joystick, button)
    Input.active_gamepad = joystick
    Input.onKeyPressed("gamepad:" .. button, false)
end

function love.gamepadreleased(joystick, button)
    Input.onKeyReleased("gamepad:" .. button)
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
    else
        if Utils.startsWith(name, "gamepad:") then
            return "[image:" .. Input.getButtonSprite(name) .. "]"
        end
    end
    return "["..name:upper().."]"
end

function Input.getControllerType()
    if not Input.active_gamepad then return nil end

    local name = Input.active_gamepad:getName():lower()

    local con = function(str) return Utils.contains(name, str) end
    if con("nintendo") or con("switch") or con("joy-con") or con("wii") or con("gamecube") or con("nso") or con("nes") then
        return "switch"
    end
    if con("sony") or con("playstation") or con("%f[%a]ps") then
        return "ps4"
    end
    return "xbox"
end

function Input.getButtonTexture(button)
    return Assets.getTexture("kristal/buttons/" .. Input.getButtonSprite(button))
end

function Input.getButtonSprite(button)
    local invert = false

    local type = Input.getControllerType() or "xbox"

    local cb = function(str)
        if invert then
            return str .. "_dark"
        end
        return str
    end

    if button == "gamepad:left" then
        return "common/left_stick_left"
    end
    if button == "gamepad:right" then
        return "common/left_stick_right"
    end
    if button == "gamepad:up" then
        return "common/left_stick_up"
    end
    if button == "gamepad:down" then
        return "common/left_stick_down"
    end
    if button == "gamepad:dpleft" then
        if type == "switch" then return "switch/left"        end
        if type == "ps4"    then return cb("ps4/dpad_left")  end
        if type == "xbox"   then return "xbox/left"          end
    end
    if button == "gamepad:dpright" then
        if type == "switch" then return "switch/right"       end
        if type == "ps4"    then return cb("ps4/dpad_right") end
        if type == "xbox"   then return "xbox/right"         end
    end
    if button == "gamepad:dpup" then
        if type == "switch" then return "switch/up"          end
        if type == "ps4"    then return cb("ps4/dpad_up")    end
        if type == "xbox"   then return "xbox/up"            end
    end
    if button == "gamepad:dpdown" then
        if type == "switch" then return "switch/down"        end
        if type == "ps4"    then return cb("ps4/dpad_down")  end
        if type == "xbox"   then return "xbox/down"          end
    end
    if button == "gamepad:a" then
        if type == "switch" then return "switch/a"           end
        if type == "ps4"    then return "ps4/cross"          end
        if type == "xbox"   then return "xbox/a"             end
    end
    if button == "gamepad:b" then
        if type == "switch" then return "switch/b"           end
        if type == "ps4"    then return "ps4/circle"         end
        if type == "xbox"   then return "xbox/b"             end
    end
    if button == "gamepad:x" then
        if type == "switch" then return "switch/x"           end
        if type == "ps4"    then return "ps4/square"         end
        if type == "xbox"   then return "xbox/x"             end
    end
    if button == "gamepad:y" then
        if type == "switch" then return "switch/y"           end
        if type == "ps4"    then return "ps4/triangle"       end
        if type == "xbox"   then return "xbox/y"             end
    end
    if button == "gamepad:back" then
        if type == "switch" then return "switch/minus"       end
        if type == "ps4"    then return "ps4/share"          end
        if type == "xbox"   then return "xbox/view"          end
    end
    if button == "gamepad:start" then
        if type == "switch" then return "switch/plus"        end
        if type == "ps4"    then return "ps4/options"        end
        if type == "xbox"   then return "xbox/menu"          end
    end
    if button == "gamepad:guide" then
        if type == "switch" then return "switch/home"        end
        if type == "ps4"    then return "ps4/ps"             end
        if type == "xbox"   then return "xbox/xbox"          end
    end
    if button == "gamepad:leftshoulder" then
        if type == "switch" then return "switch/l"           end
        if type == "ps4"    then return "ps4/l1"             end
        if type == "xbox"   then return "xbox/left_bumper"   end
    end
    if button == "gamepad:rightshoulder" then
        if type == "switch" then return "switch/r"           end
        if type == "ps4"    then return "ps4/r1"             end
        if type == "xbox"   then return "xbox/right_bumper"  end
    end
    if button == "gamepad:lefttrigger" then
        if type == "switch" then return "switch/zl"          end
        if type == "ps4"    then return "ps4/l2"             end
        if type == "xbox"   then return "xbox/left_trigger"  end
    end
    if button == "gamepad:righttrigger" then
        if type == "switch" then return "switch/zr"          end
        if type == "ps4"    then return "ps4/r2"             end
        if type == "xbox"   then return "xbox/right_trigger" end
    end
    if button == "gamepad:leftstick" then
        if type == "switch" then return "switch/lStickClick" end
        if type == "ps4"    then return "ps4/l3"             end
        if type == "xbox"   then return "xbox/left_stick"    end
    end
    if button == "gamepad:rightstick" then
        if type == "switch" then return "switch/rStickClick" end
        if type == "ps4"    then return "ps4/r3"             end
        if type == "xbox"   then return "xbox/right_stick"   end
    end

    return "unknown"
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