---@class EditorObjectReferenceControl : EditorControl
---@field clip boolean
---@field cursor_type string
---@field dragging table|false
---@field editor Editor
---@field focusable boolean
---@field focused boolean
---@field on_changed function?
---@field open_picker_on_release boolean
---@field options table
---@field pending_drag boolean
---@field press_x number?
---@field press_y number?
---@field value EditorObjectReference|string|table|nil
---@overload fun(editor: table, value?: any, options?: table): EditorObjectReferenceControl
local EditorObjectReferenceControl, super = Class(EditorControl)

function EditorObjectReferenceControl:init(editor, value, options)
    options = options or {}
    super.init(self, 0, 0, 180, 28)
    self.editor = editor
    self.value = value
    self.on_changed = options.on_changed
    self.options = TableUtils.copy(options, true)
    self.focusable = true
    self.focused = false
    self.cursor_type = "link"
    self.clip = true
end

function EditorObjectReferenceControl:setValue(value)
    self.value = value
end

function EditorObjectReferenceControl:getLabel()
    if type(self.value) == "table" then
        if self.editor and self.editor.getObjectReferenceLabel then
            return self.editor:getObjectReferenceLabel(self.value)
        end
        return EditorObjectReference.from(self.value):getLabel()
    end
    if self.value == nil or self.value == "" then return "Drag or double-click..." end
    return tostring(self.value)
end

function EditorObjectReferenceControl:onFocus() self.focused = true end
function EditorObjectReferenceControl:onBlur() self.focused = false end

function EditorObjectReferenceControl:openPicker()
    if not self.editor then return false end
    local options = TableUtils.copy(self.options, true)
    options.title = options.title or (options.marker and "Choose Marker Reference" or "Choose Object Reference")
    options.on_apply = function(value)
        self.value = value
        if self.on_changed then return self.on_changed(value, self) end
    end
    return self.editor:openObjectReferencePicker(self.value, options) ~= nil
end

function EditorObjectReferenceControl:onMousePressed(x, y, button, presses)
    if button ~= 1 then return false end
    if presses and presses >= 2 then
        self.open_picker_on_release = true
        self.pending_drag = false
        return true
    end
    self.press_x, self.press_y = x, y
    self.pending_drag = true
    return true
end

function EditorObjectReferenceControl:onMouseMoved(x, y)
    if self.pending_drag and not self.dragging
        and math.abs(x - self.press_x) + math.abs(y - self.press_y) >= 4 then
        self.dragging = self.editor:startObjectReferenceDrag(self)
    end
    return self.pending_drag
end

function EditorObjectReferenceControl:onMouseReleased(_, _, button)
    if button ~= 1 then return false end
    if self.open_picker_on_release then
        self.open_picker_on_release = false
        return self:openPicker()
    end
    local was_dragging = self.dragging
    self.pending_drag, self.dragging = false, false
    if was_dragging then
        local x, y = self.editor:getMousePosition()
        local value = self.editor:finishObjectReferenceDrag(x, y)
        if value then
            self.value = value
            if self.on_changed then self.on_changed(value, self) end
        end
    end
    return true
end

function EditorObjectReferenceControl:onKeyPressed(key)
    if key == "return" or key == "kpenter" or key == "space" then return self:openPicker() end
    return false
end

function EditorObjectReferenceControl:drawSelf()
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    Draw.setColor(0.10, 0.10, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(self.focused and { 0.55, 0.65, 0.85, 1 } or { 0.30, 0.30, 0.34, 1 })
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
    Draw.setColor(0.72, 0.82, 1, 1)
    local label = self:getLabel()
    love.graphics.print(label, 7, math.floor((self.height - font:getHeight()) / 2))
    Draw.setColor(1, 1, 1, 1)
end

return EditorObjectReferenceControl
