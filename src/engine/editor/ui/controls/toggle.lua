--- Provides a switch boolean control. Different from checkbox by being *snazzier*
---@class EditorToggle : EditorControl
---@field cursor_type string
---@field focusable boolean
---@field focused boolean
---@field label string?
---@field on_changed function?
---@field value boolean
---@overload fun(label?: string, value?: boolean, on_changed?: function): EditorToggle
local EditorToggle, super = Class(EditorControl)

function EditorToggle:init(label, value, on_changed)
    super.init(self, 0, 0, 180, 26)
    self.label = label or ""
    self.value = value == true
    self.on_changed = on_changed
    self.focusable = true
    self.cursor_type = "select"
    self.focused = false
end

function EditorToggle:setValue(value, silent)
    value = value == true
    if self.value == value then return end
    self.value = value
    if not silent and self.on_changed then self.on_changed(value, self) end
end

function EditorToggle:toggle() self:setValue(not self.value) end
function EditorToggle:onFocus() self.focused = true end
function EditorToggle:onBlur() self.focused = false end

function EditorToggle:onMousePressed(_, _, button)
    if button == 1 then self:toggle() return true end
end

function EditorToggle:onKeyPressed(key)
    if key == "space" or key == "return" or key == "kpenter" then
        self:toggle()
        return true
    end
end

function EditorToggle:drawSelf()
    local font = EditorFont.get(16)
    local switch_w, switch_h = 38, 20
    local switch_x = self.width - switch_w
    love.graphics.setColor(self.value and 0.35 or 0.18, self.value and 0.52 or 0.18, self.value and 0.78 or 0.20, 1)
    love.graphics.rectangle("fill", switch_x, (self.height - switch_h) / 2, switch_w, switch_h, switch_h / 2)
    love.graphics.setColor(self.focused and 0.80 or 0.55, self.focused and 0.84 or 0.55, self.focused and 0.95 or 0.58, 1)
    love.graphics.rectangle("line", switch_x + 0.5, (self.height - switch_h) / 2 + 0.5, switch_w - 1, switch_h - 1, switch_h / 2)
    local knob_x = self.value and (switch_x + switch_w - 17) or (switch_x + 3)
    love.graphics.setColor(0.92, 0.92, 0.94, 1)
    love.graphics.circle("fill", knob_x + 7, self.height / 2, 7)
    love.graphics.setFont(font)
    love.graphics.print(self.label, 0, math.floor((self.height - font:getHeight()) / 2))
end

return EditorToggle
