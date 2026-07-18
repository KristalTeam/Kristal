---@class EditorButton : EditorControl
---@field cursor_type string
---@field focusable boolean
---@field focused boolean
---@field label string?
---@field on_pressed function?
---@field pressed boolean
---@overload fun(label?: string, on_pressed?: function): EditorButton
local EditorButton, super = Class(EditorControl)

function EditorButton:init(label, on_pressed)
    super.init(self, 0, 0, 96, 28)
    self.label = label or "Button"
    self.on_pressed = on_pressed
    self.focusable = true
    self.focused = false
    self.pressed = false
    self.cursor_type = "select"
end

function EditorButton:activate()
    if not self.enabled then return false end
    if self.on_pressed then self.on_pressed(self) end
    return true
end

function EditorButton:onFocus() self.focused = true end
function EditorButton:onBlur() self.focused = false self.pressed = false end

function EditorButton:onMousePressed(_, _, button)
    if button ~= 1 then return false end
    self.pressed = true
    return true
end

function EditorButton:onMouseReleased(x, y, button)
    if button ~= 1 or not self.pressed then return false end
    self.pressed = false
    if x >= 0 and y >= 0 and x < self.width and y < self.height then return self:activate() end
    return true
end

function EditorButton:onKeyPressed(key)
    if key == "space" or key == "return" or key == "kpenter" then return self:activate() end
    return false
end

function EditorButton:drawSelf()
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    if not self.enabled then
        Draw.setColor(0.11, 0.11, 0.13, 1)
    elseif self.pressed then
        Draw.setColor(0.18, 0.28, 0.42, 1)
    elseif self.focused then
        Draw.setColor(0.20, 0.30, 0.46, 1)
    else
        Draw.setColor(0.15, 0.15, 0.18, 1)
    end
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(self.focused and 0.55 or 0.32, self.focused and 0.68 or 0.32,
        self.focused and 0.90 or 0.37, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
    Draw.setColor(self.enabled and { 0.90, 0.90, 0.92, 1 } or { 0.42, 0.42, 0.45, 1 })
    love.graphics.print(self.label, math.floor((self.width - font:getWidth(self.label)) / 2),
        math.floor((self.height - font:getHeight()) / 2))
end

return EditorButton
