---@class EditorTooltip : EditorControl
---@field prefix string
---@field text string
---@overload fun(): EditorTooltip
local EditorTooltip, super = Class(EditorControl)

function EditorTooltip:init()
    super.init(self, 0, 0, 0, 26)
    self.enabled = false
    self.visible = false
    self.prefix = ""
    self.text = ""
end

---@param value any
---@param x number
---@param y number
---@param maximum_width number
---@param maximum_height number
---@param prefix string?
function EditorTooltip:setText(value, x, y, maximum_width, maximum_height, prefix)
    self.text = tostring(value)
    self.prefix = prefix or ""
    local font = EditorFont.get(14)
    self.width = math.min(font:getWidth(self.prefix .. self.text) + 16,
        math.max(0, maximum_width - 8))
    self.x = MathUtils.clamp(x, 4, math.max(4, maximum_width - self.width - 4))
    self.y = MathUtils.clamp(y, 4, math.max(4, maximum_height - self.height - 4))
    self.visible = true
end

function EditorTooltip:drawSelf()
    love.graphics.setLineWidth(1)
    Draw.setColor(0.075, 0.075, 0.09, 0.98)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height, 3)
    Draw.setColor(0.42, 0.48, 0.62, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1, 3)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    Draw.setColor(0.68, 0.69, 0.74, 1)
    love.graphics.print(self.prefix, 8, 5)
    Draw.setColor(0.52, 0.72, 1, 1)
    love.graphics.print(self.text, 8 + font:getWidth(self.prefix), 5)
end

return EditorTooltip
