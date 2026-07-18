---@class EditorSourceInput : EditorControl
---@field accepts_clipboard_input boolean
---@field buffer EditorCodeBuffer?
---@field clip boolean
---@field cursor table
---@field cursor_type string
---@field document EditorFileDocument?
---@field focusable boolean
---@field focused boolean
---@field highlighted_document EditorFileDocument?
---@field lua_highlighter EditorLuaHighlighter
---@field mouse_selecting boolean
---@field padding_x number
---@field padding_y number
---@field scroll_x number
---@field scroll_y number
---@field selection_anchor {line: number, column: number}?
---@overload fun(options?: table): EditorSourceInput
local EditorSourceInput, super = Class(EditorControl)

local COLORS = EditorLuaHighlighter.COLORS

local function copyPosition(position)
    return { line = position.line, column = position.column }
end

local function samePosition(first, second)
    return first and second and first.line == second.line and first.column == second.column
end

local function previousColumn(line, column)
    if column <= 1 then return 1 end
    return utf8.offset(line, -1, column) or 1
end

local function nextColumn(line, column)
    if column > #line then return #line + 1 end
    return utf8.offset(line, 2, column) or (#line + 1)
end

function EditorSourceInput:init(options)
    options = options or {}
    super.init(self, options.x, options.y, options.width or 640, options.height or 400)
    self.padding_x = options.padding_x or 48
    self.padding_y = options.padding_y or 6
    self.document = nil
    self.buffer = nil
    self.cursor = { line = 1, column = 1 }
    self.selection_anchor = nil
    self.scroll_x, self.scroll_y = 0, 0
    self.focusable = true
    self.accepts_clipboard_input = true
    self.cursor_type = "type"
    self.focused = false
    self.mouse_selecting = false
    self.clip = true
    self.lua_highlighter = EditorLuaHighlighter()
    self.highlighted_document = nil
end

function EditorSourceInput:getFont()
    return EditorFont.getMono(16)
end

function EditorSourceInput:saveViewState()
    if not self.document then return end
    self.document.source_view = {
        cursor = copyPosition(self.cursor),
        selection_anchor = self.selection_anchor and copyPosition(self.selection_anchor),
        scroll_x = self.scroll_x,
        scroll_y = self.scroll_y
    }
end

function EditorSourceInput:setDocument(document)
    if document == self.document then return true end
    self:saveViewState()
    self.document = document
    self.buffer = document and document.buffer or nil
    local view = document and document.source_view
    self.cursor = self.buffer and self.buffer:clampPosition(view and view.cursor or { line = 1, column = 1 })
        or { line = 1, column = 1 }
    self.selection_anchor = self.buffer and view and view.selection_anchor
        and self.buffer:clampPosition(view.selection_anchor) or nil
    self.scroll_x, self.scroll_y = view and view.scroll_x or 0, view and view.scroll_y or 0
    self.highlighted_document = nil
    self:ensureCursorVisible()
    return true
end

function EditorSourceInput:updateHighlighting()
    if not self.document or self.document.language_id ~= "lua" then return false end
    if self.highlighted_document ~= self.document then
        self.lua_highlighter:setText(self.buffer:getText())
        self.highlighted_document = self.document
    end
    return true
end

function EditorSourceInput:hasSelection()
    return self.selection_anchor and not samePosition(self.selection_anchor, self.cursor)
end

function EditorSourceInput:getSelection()
    if not self.buffer or not self:hasSelection() then return self.cursor, self.cursor end
    return self.buffer:ordered(self.selection_anchor, self.cursor)
end

function EditorSourceInput:getSelectedText()
    if not self.buffer then return "" end
    return self.buffer:getTextRange(self:getSelection())
end

function EditorSourceInput:selectAll()
    if not self.buffer then return false end
    self.selection_anchor = { line = 1, column = 1 }
    self.cursor = self.buffer:getEndPosition()
    self:ensureCursorVisible()
    return true
end

function EditorSourceInput:setCursor(position, selecting)
    if not self.buffer then return false end
    if selecting then self.selection_anchor = self.selection_anchor or copyPosition(self.cursor)
    else self.selection_anchor = nil end
    self.cursor = self.buffer:clampPosition(position)
    self:ensureCursorVisible()
    return true
end

function EditorSourceInput:setProtocolCursor(line, character, encoding)
    if not self.buffer then return false end
    local index = MathUtils.clamp((line or 0) + 1, 1, self.buffer:getLineCount())
    local line_text = self.buffer:getLine(index)
    local byte_character = character or 0
    if encoding == "utf-16" and byte_character > 0 then
        local units, byte = 0, 1
        while byte <= #line_text and units < byte_character do
            local codepoint = utf8.codepoint(line_text, byte)
            units = units + (codepoint > 0xFFFF and 2 or 1)
            byte = utf8.offset(line_text, 2, byte) or (#line_text + 1)
        end
        byte_character = byte - 1
    end
    return self:setCursor({
        line = index,
        column = MathUtils.clamp(byte_character + 1, 1, #line_text + 1)
    }, false)
end

function EditorSourceInput:getCursorPosition(position)
    if not self.buffer then return 0, 0 end
    position = self.buffer:clampPosition(position or self.cursor)
    local font = self:getFont()
    return font:getWidth(self.buffer:getLine(position.line):sub(1, position.column - 1)),
        (position.line - 1) * font:getHeight()
end

function EditorSourceInput:getCursorAt(x, y)
    if not self.buffer then return { line = 1, column = 1 } end
    local font = self:getFont()
    local line_index = MathUtils.clamp(
        math.floor((y - self.padding_y + self.scroll_y) / font:getHeight()) + 1,
        1, self.buffer:getLineCount())
    local line = self.buffer:getLine(line_index)
    local target_x = x - self.padding_x + self.scroll_x
    local best_column, best_distance, column = 1, math.huge, 1
    while column <= #line + 1 do
        local distance = math.abs(target_x - font:getWidth(line:sub(1, column - 1)))
        if distance < best_distance then best_column, best_distance = column, distance end
        if column > #line then break end
        column = nextColumn(line, column)
    end
    return { line = line_index, column = best_column }
end

function EditorSourceInput:getMaxScrollY()
    if not self.buffer then return 0 end
    return math.max(0, self.buffer:getLineCount() * self:getFont():getHeight()
        + self.padding_y * 2 - self.height)
end

function EditorSourceInput:ensureCursorVisible()
    if not self.buffer then return end
    local font = self:getFont()
    local x, y = self:getCursorPosition()
    local available_width = math.max(1, self.width - self.padding_x - 6)
    local available_height = math.max(font:getHeight(), self.height - self.padding_y * 2)
    if x < self.scroll_x then self.scroll_x = x end
    if x > self.scroll_x + available_width then self.scroll_x = x - available_width end
    if y < self.scroll_y then self.scroll_y = y end
    if y + font:getHeight() > self.scroll_y + available_height then
        self.scroll_y = y + font:getHeight() - available_height
    end
    self.scroll_x = math.max(0, self.scroll_x)
    self.scroll_y = MathUtils.clamp(self.scroll_y, 0, self:getMaxScrollY())
end

function EditorSourceInput:onFocus()
    self.focused = true
end

function EditorSourceInput:onBlur()
    self.focused = false
    self.mouse_selecting = false
    self:saveViewState()
end

function EditorSourceInput:onMousePressed(x, y, button, presses)
    if button ~= 1 or not self.buffer then return false end
    local position = self:getCursorAt(x, y)
    if Input.shift() then self.selection_anchor = self.selection_anchor or copyPosition(self.cursor)
    else self.selection_anchor = copyPosition(position) end
    self.cursor = position
    if presses and presses >= 2 then
        local line = self.buffer:getLine(position.line)
        local first, last = position.column, position.column
        while first > 1 do
            local previous = previousColumn(line, first)
            if not line:sub(previous, first - 1):match("[%w_]") then break end
            first = previous
        end
        while last <= #line do
            local following = nextColumn(line, last)
            if not line:sub(last, following - 1):match("[%w_]") then break end
            last = following
        end
        self.selection_anchor = { line = position.line, column = first }
        self.cursor = { line = position.line, column = last }
    end
    self.mouse_selecting = true
    self:ensureCursorVisible()
    return true
end

function EditorSourceInput:onMouseMoved(x, y)
    if not self.mouse_selecting or not self.buffer then return false end
    self.cursor = self:getCursorAt(x, y)
    self:ensureCursorVisible()
    return true
end

function EditorSourceInput:onMouseReleased(_, _, button)
    if button ~= 1 or not self.mouse_selecting then return false end
    self.mouse_selecting = false
    if samePosition(self.selection_anchor, self.cursor) then self.selection_anchor = nil end
    return true
end

function EditorSourceInput:onWheelMoved(_, y)
    self.scroll_y = MathUtils.clamp(self.scroll_y - y * self:getFont():getHeight() * 3,
        0, self:getMaxScrollY())
    return true
end

function EditorSourceInput:onKeyPressed(key)
    if not self.buffer then return false end
    local ctrl, shift = Input.ctrl(), Input.shift()
    if ctrl and key == "a" then return self:selectAll() end
    if ctrl and key == "c" and self:hasSelection() then
        love.system.setClipboardText(self:getSelectedText())
        return true
    end
    local target
    if key == "left" then
        if self.cursor.column > 1 then
            target = { line = self.cursor.line,
                column = previousColumn(self.buffer:getLine(self.cursor.line), self.cursor.column) }
        elseif self.cursor.line > 1 then
            target = { line = self.cursor.line - 1,
                column = #self.buffer:getLine(self.cursor.line - 1) + 1 }
        end
    elseif key == "right" then
        local line = self.buffer:getLine(self.cursor.line)
        if self.cursor.column <= #line then
            target = { line = self.cursor.line, column = nextColumn(line, self.cursor.column) }
        elseif self.cursor.line < self.buffer:getLineCount() then
            target = { line = self.cursor.line + 1, column = 1 }
        end
    elseif key == "up" or key == "down" then
        target = { line = self.cursor.line + (key == "up" and -1 or 1), column = self.cursor.column }
    elseif key == "home" then
        target = { line = self.cursor.line, column = 1 }
    elseif key == "end" then
        target = { line = self.cursor.line, column = #self.buffer:getLine(self.cursor.line) + 1 }
    elseif key == "pageup" or key == "pagedown" then
        local rows = math.max(1, math.floor(self.height / self:getFont():getHeight()) - 1)
        target = { line = self.cursor.line + (key == "pageup" and -rows or rows), column = self.cursor.column }
    end
    if target then return self:setCursor(target, shift) end
    return false
end

function EditorSourceInput:drawSelection(line_index, line, y, font)
    if not self:hasSelection() then return end
    local first, last = self:getSelection()
    if line_index < first.line or line_index > last.line then return end
    local first_column = line_index == first.line and first.column or 1
    local last_column = line_index == last.line and last.column or (#line + 1)
    local x1 = self.padding_x + font:getWidth(line:sub(1, first_column - 1)) - self.scroll_x
    local x2 = self.padding_x + font:getWidth(line:sub(1, last_column - 1)) - self.scroll_x
    Draw.setColor(0.24, 0.42, 0.68, 0.85)
    love.graphics.rectangle("fill", x1, y, math.max(line_index < last.line and 3 or 1, x2 - x1), font:getHeight())
end

function EditorSourceInput:drawSelf()
    local font = self:getFont()
    love.graphics.setFont(font)
    Draw.setColor(0.055, 0.055, 0.065, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local gutter = self.padding_x - 8
    Draw.setColor(0.075, 0.075, 0.09, 1)
    love.graphics.rectangle("fill", 1, 1, gutter, self.height - 2)
    Draw.setColor(0.20, 0.20, 0.24, 1)
    love.graphics.line(gutter + 0.5, 0, gutter + 0.5, self.height)
    if not self.buffer then return end
    local line_height = font:getHeight()
    local first_line = MathUtils.clamp(math.floor(self.scroll_y / line_height) + 1,
        1, self.buffer:getLineCount())
    local last_line = math.min(self.buffer:getLineCount(), first_line + math.ceil(self.height / line_height) + 1)
    local highlighted = self:updateHighlighting()
    for line_index = first_line, last_line do
        local line = self.buffer:getLine(line_index)
        local y = self.padding_y + (line_index - 1) * line_height - self.scroll_y
        self:drawSelection(line_index, line, y, font)
        Draw.setColor(0.40, 0.40, 0.46, 1)
        local number = tostring(line_index)
        love.graphics.print(number, gutter - font:getWidth(number) - 5, y)
        local x = self.padding_x - self.scroll_x
        local tokens = highlighted and self.lua_highlighter:getLine(line_index)
            or { { text = line, kind = "text" } }
        for _, token in ipairs(tokens) do
            Draw.setColor(COLORS[token.kind] or COLORS.text)
            love.graphics.print(token.text, x, y)
            x = x + font:getWidth(token.text)
        end
    end
    if self.focused and math.floor(Kristal.getTime() * 2) % 2 == 0 then
        local x, y = self:getCursorPosition()
        Draw.setColor(0.95, 0.95, 0.98, 1)
        love.graphics.line(self.padding_x + x - self.scroll_x,
            self.padding_y + y - self.scroll_y,
            self.padding_x + x - self.scroll_x,
            self.padding_y + y - self.scroll_y + line_height)
    end
end

return EditorSourceInput
