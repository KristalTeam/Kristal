---@class EditorTextInput : EditorControl
---@overload fun(options?: table): EditorTextInput
local EditorTextInput, super = Class(EditorControl)

local function clampCursor(value, cursor)
    return MathUtils.clamp(cursor or (#value + 1), 1, #value + 1)
end

local function previousCodepoint(value, cursor)
    cursor = clampCursor(value, cursor)
    if cursor <= 1 then return 1 end
    return utf8.offset(value, -1, cursor) or 1
end

local function nextCodepoint(value, cursor)
    cursor = clampCursor(value, cursor)
    if cursor > #value then return #value + 1 end
    return utf8.offset(value, 2, cursor) or (#value + 1)
end

local function getLines(value)
    local lines, start = {}, 1
    while true do
        local newline = value:find("\n", start, true)
        local finish = newline and newline - 1 or #value
        table.insert(lines, { start = start, finish = finish, text = value:sub(start, finish) })
        if not newline then break end
        start = newline + 1
    end
    return lines
end

function EditorTextInput:init(options)
    options = options or {}
    self.multiline = options.multiline == true
    super.init(self, options.x, options.y, options.width or 180,
        options.height or (self.multiline and 96 or 28))
    self.value = tostring(options.value or "")
    self.placeholder = options.placeholder or ""
    self.on_changed = options.on_changed
    self.on_submit = options.on_submit
    self.on_cancel = options.on_cancel
    self.editor = options.editor
    self.submit_feedback = options.submit_feedback ~= false and self.on_submit ~= nil
    self.font = options.font
    self.cursor = #self.value + 1
    self.selection_anchor = nil
    self.preferred_x = nil
    self.scroll_x, self.scroll_y = 0, 0
    self.focusable = true
    self.accepts_text_input = true
    self.cursor_type = "type"
    self.focused = false
    self.padding = options.padding or 6
    self.clip = true
    self.submitted_value = self.value
    self.pending_submit = false
end

function EditorTextInput:getFeedbackEditor()
    if self.editor then return self.editor end
    local state = Kristal.getState()
    if state and state.message_bar then return state end
end

function EditorTextInput:getSubmitHint()
    return self.multiline and "Editing text — press Ctrl+Enter to apply"
        or "Editing text — press Enter to apply"
end

function EditorTextInput:showSubmitStatus(message, duration)
    local editor = self:getFeedbackEditor()
    if editor and editor.message_bar then editor.message_bar:setStatus(message, duration or 4) end
end

function EditorTextInput:submitValue()
    if not self.on_submit then return false end
    local submitted_value = self.value
    local previous_value = self.submitted_value
    self.submitted_value = submitted_value
    self.pending_submit = false
    local applied = self.on_submit(submitted_value, self) ~= false
    if self.submit_feedback then
        if applied then
            self:showSubmitStatus("Text field applied")
        else
            self.submitted_value = previous_value
            self.pending_submit = submitted_value ~= previous_value
            self:showSubmitStatus("Text field could not be applied")
        end
    end
    return applied
end

function EditorTextInput:hasSelection()
    return self.selection_anchor ~= nil and self.selection_anchor ~= self.cursor
end

function EditorTextInput:getSelection()
    if not self:hasSelection() then return self.cursor, self.cursor end
    return math.min(self.cursor, self.selection_anchor), math.max(self.cursor, self.selection_anchor)
end

function EditorTextInput:clearSelection()
    self.selection_anchor = nil
end

function EditorTextInput:selectAll()
    self.selection_anchor = 1
    self.cursor = #self.value + 1
    self:ensureCursorVisible()
end

function EditorTextInput:getSelectedText()
    local first, last = self:getSelection()
    return self.value:sub(first, last - 1)
end

function EditorTextInput:setValue(value, silent)
    value = tostring(value or "")
    if self.value == value then
        if silent then
            self.submitted_value = value
            self.pending_submit = false
        end
        return
    end
    self.value = value
    self.cursor = #value + 1
    self:clearSelection()
    if silent then
        self.submitted_value = value
        self.pending_submit = false
    else
        if self.submit_feedback then
            self.pending_submit = value ~= self.submitted_value
            if self.pending_submit then self:showSubmitStatus(self:getSubmitHint()) end
        end
        if self.on_changed then self.on_changed(value, self) end
    end
end

function EditorTextInput:replaceSelection(text)
    text = tostring(text or "")
    local first, last = self:getSelection()
    local value = self.value:sub(1, first - 1) .. text .. self.value:sub(last)
    local cursor = first + #text
    self:setValue(value)
    self.cursor = clampCursor(self.value, cursor)
    self:clearSelection()
    self:ensureCursorVisible()
end

function EditorTextInput:deleteSelection()
    if not self:hasSelection() then return false end
    self:replaceSelection("")
    return true
end

function EditorTextInput:onFocus()
    self.focused = true
    love.keyboard.setTextInput(true)
    if self.submit_feedback then self:showSubmitStatus(self:getSubmitHint()) end
end

function EditorTextInput:onBlur()
    self.focused = false
    self.mouse_selecting = false
    love.keyboard.setTextInput(false)
    if self.submit_feedback and self.pending_submit then self:submitValue() end
end

function EditorTextInput:getCursorLine(cursor)
    cursor = clampCursor(self.value, cursor or self.cursor)
    local lines = getLines(self.value)
    for index, line in ipairs(lines) do
        if cursor <= line.finish + 1 or index == #lines then return index, line, lines end
    end
    return #lines, lines[#lines], lines
end

function EditorTextInput:getCursorPosition(cursor)
    local index, line, lines = self:getCursorLine(cursor)
    local font = self.font or EditorFont.get(16)
    local x = font:getWidth(self.value:sub(line.start, clampCursor(self.value, cursor or self.cursor) - 1))
    return x, (index - 1) * font:getHeight(), index, line, lines
end

function EditorTextInput:getCursorAt(x, y)
    local font = self.font or EditorFont.get(16)
    local lines = getLines(self.value)
    local line_index = self.multiline
        and MathUtils.clamp(math.floor((y - self.padding + self.scroll_y) / font:getHeight()) + 1, 1, #lines)
        or 1
    local line = lines[line_index]
    local target_x = x - self.padding + self.scroll_x
    local best_cursor, best_distance = line.start, math.huge
    local cursor = line.start
    while cursor <= line.finish + 1 do
        local width = font:getWidth(self.value:sub(line.start, cursor - 1))
        local distance = math.abs(target_x - width)
        if distance < best_distance then best_cursor, best_distance = cursor, distance end
        if cursor > line.finish then break end
        cursor = nextCodepoint(self.value, cursor)
    end
    return best_cursor
end

function EditorTextInput:ensureCursorVisible()
    local font = self.font or EditorFont.get(16)
    local x, y = self:getCursorPosition(self.cursor)
    local available_width = math.max(1, self.width - self.padding * 2)
    if x - self.scroll_x < 0 then self.scroll_x = x end
    if x - self.scroll_x > available_width then self.scroll_x = x - available_width end
    if self.multiline then
        local available_height = math.max(font:getHeight(), self.height - self.padding * 2)
        if y - self.scroll_y < 0 then self.scroll_y = y end
        if y + font:getHeight() - self.scroll_y > available_height then
            self.scroll_y = y + font:getHeight() - available_height
        end
    else
        self.scroll_y = 0
    end
end

function EditorTextInput:moveCursor(cursor, selecting)
    cursor = clampCursor(self.value, cursor)
    if selecting then
        self.selection_anchor = self.selection_anchor or self.cursor
    else
        self:clearSelection()
    end
    self.cursor = cursor
    self:ensureCursorVisible()
end

function EditorTextInput:selectWordAt(cursor)
    if #self.value == 0 then return end
    local first, last = clampCursor(self.value, cursor), clampCursor(self.value, cursor)
    while first > 1 do
        local previous = previousCodepoint(self.value, first)
        if not self.value:sub(previous, first - 1):match("[%w_]") then break end
        first = previous
    end
    while last <= #self.value do
        local next_cursor = nextCodepoint(self.value, last)
        if not self.value:sub(last, next_cursor - 1):match("[%w_]") then break end
        last = next_cursor
    end
    self.selection_anchor, self.cursor = first, last
end

function EditorTextInput:onMousePressed(x, y, button, presses)
    if button ~= 1 then return false end
    local cursor = self:getCursorAt(x, y)
    if Input.shift() then
        self.selection_anchor = self.selection_anchor or self.cursor
    else
        self.selection_anchor = cursor
    end
    self.cursor = cursor
    if presses and presses >= 2 then self:selectWordAt(cursor) end
    self.mouse_selecting = true
    self:ensureCursorVisible()
    return true
end

function EditorTextInput:onMouseMoved(x, y)
    if not self.mouse_selecting then return false end
    self.cursor = self:getCursorAt(x, y)
    self:ensureCursorVisible()
    return true
end

function EditorTextInput:onMouseReleased(_, _, button)
    if button ~= 1 or not self.mouse_selecting then return false end
    self.mouse_selecting = false
    if self.selection_anchor == self.cursor then self:clearSelection() end
    return true
end

function EditorTextInput:onKeyPressed(key)
    self.cursor = clampCursor(self.value, self.cursor)
    local ctrl, shift = Input.ctrl(), Input.shift()
    if ctrl and key == "a" then self:selectAll() return true end
    if ctrl and key == "c" then
        if self:hasSelection() then love.system.setClipboardText(self:getSelectedText()) end
        return true
    end
    if ctrl and key == "x" then
        if self:hasSelection() then
            love.system.setClipboardText(self:getSelectedText())
            self:deleteSelection()
        end
        return true
    end
    if ctrl and key == "v" then
        local text = love.system.getClipboardText() or ""
        if not self.multiline then text = text:gsub("[\r\n]", "") end
        self:replaceSelection(text)
        return true
    end

    if key == "backspace" then
        if not self:deleteSelection() then
            local previous = previousCodepoint(self.value, self.cursor)
            if previous < self.cursor then
                self.selection_anchor = previous
                self:replaceSelection("")
            end
        end
        return true
    elseif key == "delete" then
        if not self:deleteSelection() then
            local next_cursor = nextCodepoint(self.value, self.cursor)
            if next_cursor > self.cursor then
                self.selection_anchor = next_cursor
                self:replaceSelection("")
            end
        end
        return true
    elseif key == "left" then
        local target = self:hasSelection() and not shift and select(1, self:getSelection())
            or previousCodepoint(self.value, self.cursor)
        self:moveCursor(target, shift)
        self.preferred_x = nil
        return true
    elseif key == "right" then
        local _, selection_end = self:getSelection()
        local target = self:hasSelection() and not shift and selection_end
            or nextCodepoint(self.value, self.cursor)
        self:moveCursor(target, shift)
        self.preferred_x = nil
        return true
    elseif key == "home" or key == "end" then
        local _, line = self:getCursorLine()
        self:moveCursor(key == "home" and line.start or (line.finish + 1), shift)
        self.preferred_x = nil
        return true
    elseif self.multiline and (key == "up" or key == "down") then
        local x, _, line_index, _, lines = self:getCursorPosition()
        self.preferred_x = self.preferred_x or x
        self:moveCursor(self:getCursorAt(self.padding + self.preferred_x - self.scroll_x,
            self.padding + ((MathUtils.clamp(line_index + (key == "up" and -1 or 1), 1, #lines) - 1)
                * (self.font or EditorFont.get(16)):getHeight()) - self.scroll_y), shift)
        return true
    elseif key == "return" or key == "kpenter" then
        if self.multiline and not ctrl then
            self:replaceSelection("\n")
        elseif self.on_submit then
            self:submitValue()
        end
        return true
    elseif key == "tab" and self.multiline then
        self:replaceSelection("    ")
        return true
    elseif key == "escape" and self.on_cancel then
        self.on_cancel(self)
        return true
    end
    return false
end

function EditorTextInput:onTextInput(text)
    if not self.multiline then text = text:gsub("[\r\n]", "") end
    self:replaceSelection(text)
    return true
end

function EditorTextInput:drawSelf()
    self.cursor = clampCursor(self.value, self.cursor)
    local font = self.font or EditorFont.get(16)
    love.graphics.setFont(font)
    Draw.setColor(0.10, 0.10, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(self.pending_submit and { 0.95, 0.70, 0.20, 1 }
        or self.focused and { 0.55, 0.65, 0.85, 1 } or { 0.30, 0.30, 0.34, 1 })
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)

    local lines = getLines(self.value)
    local selection_start, selection_end = self:getSelection()
    for index, line in ipairs(lines) do
        local y = self.padding + (index - 1) * font:getHeight() - self.scroll_y
        if y + font:getHeight() >= 0 and y <= self.height then
            if self:hasSelection() then
                local first = math.max(selection_start, line.start)
                local last = math.min(selection_end, line.finish + 1)
                if first < last then
                    local x1 = self.padding + font:getWidth(self.value:sub(line.start, first - 1)) - self.scroll_x
                    local x2 = self.padding + font:getWidth(self.value:sub(line.start, last - 1)) - self.scroll_x
                    Draw.setColor(0.24, 0.42, 0.68, 0.85)
                    love.graphics.rectangle("fill", x1, y, math.max(2, x2 - x1), font:getHeight())
                end
            end
            Draw.setColor(0.90, 0.90, 0.92, 1)
            love.graphics.print(line.text, self.padding - self.scroll_x, y)
        end
    end
    if self.value == "" and not self.focused then
        Draw.setColor(0.55, 0.55, 0.58, 1)
        love.graphics.print(self.placeholder, self.padding, self.padding)
    end
    if self.focused and math.floor(Kristal.getTime() * 2) % 2 == 0 then
        local cursor_x, cursor_y = self:getCursorPosition()
        cursor_x = self.padding + cursor_x - self.scroll_x
        cursor_y = self.padding + cursor_y - self.scroll_y
        Draw.setColor(0.94, 0.94, 0.96, 1)
        love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + font:getHeight())
    end
end

return EditorTextInput
