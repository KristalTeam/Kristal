--- Displays an icon button for an editor tool.
---@class EditorToolButton : EditorButton
---@field on_dropdown function?
---@field tool table
---@overload fun(tool: table, on_pressed?: function): EditorToolButton
local EditorToolButton, super = Class(EditorButton)

function EditorToolButton:init(tool, on_pressed)
    super.init(self, tool.short_name or tool.name, on_pressed)
    self.tool = tool
end

function EditorToolButton:onMousePressed(x, y, button)
    if button == 2 and self.on_dropdown then return self.on_dropdown(self) end
    return super.onMousePressed(self, x, y, button)
end

function EditorToolButton:drawSelf()
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
    Draw.setColor(self.focused and { 0.55, 0.68, 0.90, 1 }
        or self.enabled and { 0.32, 0.32, 0.37, 1 } or { 0.22, 0.22, 0.25, 1 })
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
    local texture = self.tool.icon and Assets.getTexture(self.tool.icon)
    if texture then
        Draw.setColor(self.enabled and { 0.92, 0.92, 0.95, 1 } or { 0.42, 0.42, 0.45, 1 })
        local scale_x, scale_y = 16 / texture:getWidth(), 16 / texture:getHeight()
        Draw.draw(texture, math.floor((self.width - 16) / 2), math.floor((self.height - 16) / 2),
            0, scale_x, scale_y)
    end
    if self.on_dropdown then
        local arrow = Assets.getTexture("ui/flat_arrow_down")
        if arrow then
            Draw.setColor(self.enabled and { 0.82, 0.82, 0.86, 1 } or { 0.38, 0.38, 0.41, 1 })
            Draw.draw(arrow, self.width - arrow:getWidth() - 2, self.height - arrow:getHeight() - 2)
        end
    end
end

return EditorToolButton
