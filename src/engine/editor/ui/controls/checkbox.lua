---@class EditorCheckbox : EditorControl
---@field cursor_type string
---@field focusable boolean
---@field focused boolean
---@field label string?
---@field on_changed function?
---@field value boolean
---@overload fun(label?: string, value?: boolean, on_changed?: function): EditorCheckbox
local EditorCheckbox, super = Class(EditorControl)

function EditorCheckbox:init(label, value, on_changed)
    super.init(self, 0, 0, 180, 24)
    self.label = label or ""
    self.value = value == true
    self.on_changed = on_changed
    self.focusable = true
    self.cursor_type = "select"
    self.focused = false
end

function EditorCheckbox:setValue(value, silent)
    value = value == true
    if self.value == value then return end
    self.value = value
    if not silent and self.on_changed then self.on_changed(value, self) end
end

function EditorCheckbox:toggle()
    self:setValue(not self.value)
end

function EditorCheckbox:onFocus() self.focused = true end
function EditorCheckbox:onBlur() self.focused = false end

function EditorCheckbox:onMousePressed(_, _, button)
    if button == 1 then
        self:toggle()
        return true
    end
end

function EditorCheckbox:onKeyPressed(key)
    if key == "space" or key == "return" or key == "kpenter" then
        self:toggle()
        return true
    end
end

function EditorCheckbox:drawSelf()
    local font = EditorFont.get(16)
    local size = math.min(18, self.height - 4)
    love.graphics.setColor(0.10, 0.10, 0.12, 1)
    love.graphics.rectangle("fill", 2, (self.height - size) / 2, size, size)
    love.graphics.setColor(self.focused and 0.65 or 0.42, self.focused and 0.72 or 0.42, self.focused and 0.90 or 0.46, 1)
    love.graphics.rectangle("line", 2.5, (self.height - size) / 2 + 0.5, size - 1, size - 1)
    if self.value then
        love.graphics.setLineWidth(2)
        love.graphics.line(6, self.height / 2, 10, self.height / 2 + 4, 17, self.height / 2 - 5)
        love.graphics.setLineWidth(1)
    end
    love.graphics.setFont(font)
    love.graphics.setColor(0.90, 0.90, 0.92, 1)
    love.graphics.print(self.label, size + 8, math.floor((self.height - font:getHeight()) / 2))
end

return EditorCheckbox
