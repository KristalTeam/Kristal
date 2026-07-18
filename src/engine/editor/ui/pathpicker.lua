---@class EditorPathPicker : EditorControl
---@field apply_button EditorButton
---@field cancel_button EditorButton
---@field captured_control EditorControl?
---@field editor Editor
---@field focused_control EditorControl?
---@field list EditorItemList
---@field options table
---@field panel_height number
---@field panel_width number
---@field panel_x number
---@field panel_y number
---@field search EditorSearchBar
---@field value string
---@overload fun(editor: Editor, value?: string, items?: table, options?: table): EditorPathPicker
local EditorPathPicker, super = Class(EditorControl)

function EditorPathPicker:init(editor, value, items, options)
    local width, height = editor:getUIDimensions()
    super.init(self, 0, 0, width, height)
    self.editor = editor
    self.options = options or {}
    self.value = value
    self.focused_control = nil
    self.captured_control = nil
    self.search = self:addChild(EditorSearchBar({
        editor = editor,
        placeholder = "Search...",
        on_changed = function(filter) self.list:setFilter(filter) end,
        on_submit = function() return self:apply() end
    }))
    self.list = self:addChild(EditorItemList({
        on_select = function(item) self.value = item and item.data or self.value end,
        on_activate = function(item)
            if item then
                self.value = item.data
                self:apply()
            end
        end,
        on_request_focus = function(control) self:setFocus(control) end
    }))
    self.list:setItems(items or {})
    for index, item in ipairs(self.list.filtered_items) do
        if item.data == value then self.list:select(index) break end
    end
    self.apply_button = self:addChild(EditorButton("Apply", function() self:apply() end))
    self.cancel_button = self:addChild(EditorButton("Cancel", function() self:cancel() end))
    self:setFocus(self.search)
end

function EditorPathPicker:setFocus(control)
    if self.focused_control == control then return end
    if self.focused_control then self.focused_control:onBlur() end
    self.focused_control = control
    if control then control:onFocus() end
end

function EditorPathPicker:apply()
    local selected = self.list:getSelectedItem()
    if selected then self.value = selected.data end
    if self.options.on_apply and self.options.on_apply(self.value) == false then return false end
    return self.editor:closePathPicker(true)
end

function EditorPathPicker:cancel()
    return self.editor:closePathPicker(false)
end

function EditorPathPicker:update(dt)
    self:setBounds(0, 0, self.editor:getUIDimensions())
    self.panel_width, self.panel_height = math.min(600, self.width - 40), math.min(520, self.height - 40)
    self.panel_x = math.floor((self.width - self.panel_width) / 2)
    self.panel_y = math.floor((self.height - self.panel_height) / 2)
    self.search:setBounds(self.panel_x + 18, self.panel_y + 52, self.panel_width - 36, 28)
    self.list:setBounds(self.panel_x + 18, self.panel_y + 88,
        self.panel_width - 36, math.max(40, self.panel_height - 142))
    self.apply_button:setBounds(self.panel_x + self.panel_width - 222,
        self.panel_y + self.panel_height - 42, 98, 28)
    self.cancel_button:setBounds(self.panel_x + self.panel_width - 116,
        self.panel_y + self.panel_height - 42, 98, 28)
    super.update(self, dt)
end

function EditorPathPicker:onMousePressed(x, y, button, _, presses)
    if button ~= 1 then return true end
    local target = self:getControlAt(x, y)
    if target and target ~= self then
        if target.focusable then self:setFocus(target) else self:setFocus(nil) end
        local local_x, local_y = target:toLocal(x, y)
        if target:onMousePressed(local_x, local_y, button, presses) then self.captured_control = target end
        return true
    end
    self:setFocus(nil)
    if x < self.panel_x or y < self.panel_y
        or x >= self.panel_x + self.panel_width or y >= self.panel_y + self.panel_height then
        return self:cancel()
    end
    return true
end

function EditorPathPicker:onMouseMoved(x, y, dx, dy)
    if self.captured_control then
        local local_x, local_y = self.captured_control:toLocal(x, y)
        self.captured_control:onMouseMoved(local_x, local_y, dx, dy)
    end
    return true
end

function EditorPathPicker:onMouseReleased(x, y, button, _, presses)
    if self.captured_control then
        local target = self.captured_control
        local local_x, local_y = target:toLocal(x, y)
        target:onMouseReleased(local_x, local_y, button, presses)
        self.captured_control = nil
    end
    return true
end

function EditorPathPicker:onKeyPressed(key, is_repeat)
    if key == "escape" then return self:cancel() end
    if key == "tab" then
        local controls = { self.search, self.list, self.apply_button, self.cancel_button }
        local index = 0
        for candidate, control in ipairs(controls) do
            if control == self.focused_control then index = candidate break end
        end
        index = ((index - 1 + (Input.shift() and -1 or 1)) % #controls) + 1
        self:setFocus(controls[index])
        return true
    end
    if self.focused_control == self.search
        and (key == "up" or key == "down" or key == "pageup" or key == "pagedown"
            or key == "home" or key == "end") then
        return self.list:onKeyPressed(key)
    end
    if self.focused_control and self.focused_control:onKeyPressed(key, is_repeat) then return true end
    if (key == "return" or key == "kpenter") and not is_repeat then return self:apply() end
    return true
end

function EditorPathPicker:onKeyReleased(key)
    if self.focused_control then self.focused_control:onKeyReleased(key) end
    return true
end

function EditorPathPicker:onTextInput(text)
    if self.focused_control then self.focused_control:onTextInput(text) end
    return true
end

function EditorPathPicker:onWheelMoved(x, y)
    local mouse_x, mouse_y = self.editor:getMousePosition()
    if self.list:containsPoint(mouse_x, mouse_y) then self.list:onWheelMoved(x, y) end
    return true
end

function EditorPathPicker:getCursorType(x, y)
    local target = self:getControlAt(x, y)
    if not target or target == self then return "default" end
    local local_x, local_y = target:toLocal(x, y)
    return target.getCursorType and target:getCursorType(local_x, local_y)
        or target.cursor_type or "default"
end

function EditorPathPicker:drawSelf()
    Draw.setColor(0, 0, 0, 0.68)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.105, 0.105, 0.125, 1)
    love.graphics.rectangle("fill", self.panel_x, self.panel_y,
        self.panel_width, self.panel_height, 4)
    Draw.setColor(0.42, 0.48, 0.62, 1)
    love.graphics.rectangle("line", self.panel_x + 0.5, self.panel_y + 0.5,
        self.panel_width - 1, self.panel_height - 1, 4)
    love.graphics.setFont(EditorFont.get(24))
    Draw.setColor(0.94, 0.94, 0.97, 1)
    love.graphics.print(self.options.title or "Choose Path", self.panel_x + 18, self.panel_y + 14)
end

return EditorPathPicker
