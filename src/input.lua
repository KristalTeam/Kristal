local Input = {}
local self = Input

-- TODO: rebinding

Input.key_down = {}
Input.key_pressed = {}
Input.key_released = {}

Input.aliases = {
    ["up"] = {"up"},
    ["down"] = {"down"},
    ["left"] = {"left"},
    ["right"] = {"right"},
    ["confirm"] = {"z", "return"},
    ["cancel"] = {"x", "lshift", "rshift"},
    ["menu"] = {"c", "lctrl", "rctrl"}
}

Input.lock_stack = {}

function Input.clearPressed()
    self.key_pressed = {}
    self.key_released = {}
end

function Input.lock(target)
    table.insert(self.lock_stack, target)
end

function Input.release(target)
    if not target then
        table.remove(self.lock_stack, #self.lock_stack)
    else
        Utils.removeFromTable(self.lock_stack, target)
    end
end

function Input.check(target)
    return self.lock_stack[#self.lock_stack] == target
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
            if self.key_down[k] then
                return true
            end
        end
        return false
    else
        return self.key_down[key]
    end
end

function Input.keyDown(key)
    return self.key_down[key]
end

function Input.pressed(key)
    if self.aliases[key] then
        for _,k in ipairs(self.aliases[key]) do
            if self.key_pressed[k] then
                return true
            end
        end
        return false
    else
        return self.key_down[key]
    end
end

function Input.keyPressed(key)
    return self.key_pressed[key]
end

function Input.released(key)
    if self.aliases[key] then
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
    if self.aliases[key] then
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
    return self.aliases[alias] and Utils.containsValue(self.aliases[alias], key)
end

function Input.getText(alias)
    local name = self.aliases[alias] and self.aliases[alias][1] or alias
    return "["..name:upper().."]"
end

function Input.isConfirm(key)
    return Utils.containsValue(self.aliases["confirm"], key)
end

function Input.isCancel(key)
    return Utils.containsValue(self.aliases["cancel"], key)
end

function Input.isMenu(key)
    return Utils.containsValue(self.aliases["menu"], key)
end

return Input