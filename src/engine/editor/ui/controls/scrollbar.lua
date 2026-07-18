--- Provides scrolling for editor controls and panels.
---@class EditorScrollbar : EditorControl
---@field cursor_type string
---@field drag_offset number
---@field dragging boolean
---@field horizontal boolean
---@field on_changed function?
---@field page number
---@field value number
---@overload fun(options?: table): EditorScrollbar
local EditorScrollbar, super = Class(EditorControl)

function EditorScrollbar:init(options)
    options = options or {}
    super.init(self, options.x, options.y, options.width or 12, options.height or 100)
    self.value = MathUtils.clamp(options.value or 0, 0, 1)
    self.page = MathUtils.clamp(options.page or 0.2, 0, 1)
    self.on_changed = options.on_changed
    self.horizontal = options.horizontal == true
    self.cursor_type = "select"
    self.dragging = false
    self.drag_offset = 0
end

function EditorScrollbar:setValue(value, silent)
    value = MathUtils.clamp(value or 0, 0, 1)
    if self.value == value then return end
    self.value = value
    if not silent and self.on_changed then self.on_changed(value, self) end
end

function EditorScrollbar:getThumbRect()
    local length = self.horizontal and self.width or self.height
    local thickness = self.horizontal and self.height or self.width
    local thumb_length = math.min(length, math.max(18, length * self.page))
    local position = math.max(0, length - thumb_length) * self.value
    if self.horizontal then return position, 0, thumb_length, thickness end
    return 0, position, thickness, thumb_length
end

function EditorScrollbar:onMousePressed(x, y, button)
    if button ~= 1 then return false end
    local thumb_x, thumb_y, thumb_w, thumb_h = self:getThumbRect()
    local position = self.horizontal and x or y
    local thumb_position = self.horizontal and thumb_x or thumb_y
    local thumb_length = self.horizontal and thumb_w or thumb_h
    local length = self.horizontal and self.width or self.height
    if position >= thumb_position and position < thumb_position + thumb_length then
        self.drag_offset = position - thumb_position
    else
        self.drag_offset = thumb_length / 2
        self:setValue((position - self.drag_offset) / math.max(1, length - thumb_length))
    end
    self.dragging = true
    return true
end

function EditorScrollbar:onMouseMoved(x, y)
    if not self.dragging then return end
    local _, _, thumb_w, thumb_h = self:getThumbRect()
    local position = self.horizontal and x or y
    local thumb_length = self.horizontal and thumb_w or thumb_h
    local length = self.horizontal and self.width or self.height
    self:setValue((position - self.drag_offset) / math.max(1, length - thumb_length))
end

function EditorScrollbar:onMouseReleased(_, _, button)
    if button == 1 and self.dragging then
        self.dragging = false
        return true
    end
end

function EditorScrollbar:onWheelMoved(x, y)
    local movement = self.horizontal and (x ~= 0 and x or y) or y
    self:setValue(self.value - movement * math.max(0.03, self.page * 0.25))
    return true
end

function EditorScrollbar:drawSelf()
    love.graphics.setColor(0.09, 0.09, 0.10, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local thumb_x, thumb_y, thumb_w, thumb_h = self:getThumbRect()
    love.graphics.setColor(self.dragging and 0.62 or 0.42, self.dragging and 0.65 or 0.44, self.dragging and 0.72 or 0.50, 1)
    love.graphics.rectangle("fill", thumb_x + 2, thumb_y + 2,
        math.max(1, thumb_w - 4), math.max(1, thumb_h - 4), 2)
end

return EditorScrollbar
