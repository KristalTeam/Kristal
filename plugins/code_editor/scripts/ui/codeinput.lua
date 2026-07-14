---@class EditorCodeInput : EditorControl
---@overload fun(options?: table): EditorCodeInput
local EditorCodeInput, super = Class(EditorControl)
local EditorCodeCompletionPopup, EditorCodeHoverPopup = ...

local COLORS = EditorLuaHighlighter.COLORS
local TAB_WIDTH = 4

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

local function protocolCharacterToColumn(line, character, encoding)
    character = math.max(0, character or 0)
    if encoding ~= "utf-16" then return math.min(#line, character) + 1 end
    local units = 0
    for byte, codepoint in utf8.codes(line) do
        if units >= character then return byte end
        units = units + (codepoint > 0xFFFF and 2 or 1)
    end
    return #line + 1
end

local function protocolPositionToBuffer(buffer, position, encoding)
    local line_index = MathUtils.clamp((position and position.line or 0) + 1, 1, buffer:getLineCount())
    return {
        line = line_index,
        column = protocolCharacterToColumn(buffer:getLine(line_index),
            position and position.character or 0, encoding)
    }
end

local function completionText(text, insert_text_format)
    text = tostring(text or "")
    if insert_text_format == 2 then
        text = text:gsub("%${%d+:([^}]*)}", "%1")
            :gsub("%${%d+}", "")
            :gsub("%$%d+", "")
    end
    return text
end

function EditorCodeInput:init(options)
    options = options or {}
    super.init(self, options.x, options.y, options.width or 640, options.height or 400)
    self.editor = options.editor
    self.code_editor = options.code_editor
    self.language_service = options.language_service
    self.font = options.font
    self.padding_x = options.padding_x or 48
    self.padding_y = options.padding_y or 6
    self.document = nil
    self.buffer = nil
    self.cursor = { line = 1, column = 1 }
    self.selection_anchor = nil
    self.preferred_x = nil
    self.scroll_x, self.scroll_y = 0, 0
    self.diagnostics = {}
    self.focusable = true
    self.accepts_text_input = true
    self.cursor_type = "type"
    self.focused = false
    self.mouse_selecting = false
    self.clip = true
    self.completion_popup = self:addChild(EditorCodeCompletionPopup())
    self.hover_popup = self:addChild(EditorCodeHoverPopup())
    self.completion_generation = 0
    self.completion_due = nil
    self.completion_defaults = nil
    self.hover_generation = 0
    self.hover_candidate = nil
    self.hover_elapsed = 0
    self.hover_requested = nil
    self.hover_explicit = false
    self.hover_mouse_x = nil
    self.hover_mouse_y = nil
    self.lua_highlighter = EditorLuaHighlighter()
    self.syntax_cache_document = nil
    self.syntax_cache_version = nil
    self.block_guides = {}
end

function EditorCodeInput:getFont()
    return self.font or EditorFont.getMono(16)
end

function EditorCodeInput:closeHover()
    self.hover_generation = self.hover_generation + 1
    self.hover_candidate = nil
    self.hover_requested = nil
    self.hover_elapsed = 0
    self.hover_explicit = false
    self.hover_mouse_x = nil
    self.hover_mouse_y = nil
    self.hover_popup:close()
    return true
end

function EditorCodeInput:closeCodeAssists()
    self.completion_generation = self.completion_generation + 1
    self.completion_due = nil
    self.completion_defaults = nil
    self.completion_popup:close()
    self:closeHover()
end

function EditorCodeInput:saveViewState()
    if not self.document then return end
    self.document.code_view = {
        cursor = copyPosition(self.cursor),
        selection_anchor = self.selection_anchor and copyPosition(self.selection_anchor),
        scroll_x = self.scroll_x,
        scroll_y = self.scroll_y
    }
end

function EditorCodeInput:setDocument(document)
    if document == self.document then
        self.diagnostics = document and document.diagnostics or {}
        return
    end
    self:saveViewState()
    self:closeCodeAssists()
    self.document = document
    self.buffer = document and document.buffer or nil
    self.diagnostics = document and document.diagnostics or {}
    local view = document and document.code_view
    self.cursor = self.buffer and self.buffer:clampPosition(view and view.cursor or { line = 1, column = 1 })
        or { line = 1, column = 1 }
    self.selection_anchor = self.buffer and view and view.selection_anchor
        and self.buffer:clampPosition(view.selection_anchor) or nil
    self.scroll_x = view and view.scroll_x or 0
    self.scroll_y = view and view.scroll_y or 0
    self.preferred_x = nil
    self.syntax_cache_document = nil
    self.syntax_cache_version = nil
    self.block_guides = {}
    self:ensureCursorVisible()
end

function EditorCodeInput:getBufferPositionFromProtocol(position, encoding)
    if not self.buffer then return { line = 1, column = 1 } end
    return protocolPositionToBuffer(self.buffer, position, encoding)
end

function EditorCodeInput:updateSyntaxCache()
    if not self.document or not self.buffer or self.document.language_id ~= "lua" then return false end
    if self.syntax_cache_document == self.document
        and self.syntax_cache_version == self.document.version then return true end
    self.syntax_cache_document = self.document
    self.syntax_cache_version = self.document.version
    self.lua_highlighter:setText(self.buffer:getText())
    self.block_guides = {}
    for _, block in ipairs(self.lua_highlighter.blocks) do
        local opening = self.buffer:offsetToPosition(block.open_offset)
        local closing = self.buffer:offsetToPosition(block.close_offset)
        local opening_line = self.buffer:getLine(opening.line)
        local indentation = opening_line:match("^%s*") or ""
        table.insert(self.block_guides, {
            opening = opening,
            closing = closing,
            column = #indentation + 1,
            depth = block.depth,
            open_offset = block.open_offset,
            close_offset = block.close_offset
        })
    end
    return true
end

function EditorCodeInput:getSyntaxTokenAt(position)
    if not self:updateSyntaxCache() then return nil end
    position = self.buffer:clampPosition(position or self.cursor)
    local column = 1
    local last_token
    for _, token in ipairs(self.lua_highlighter:getLine(position.line)) do
        local finish = column + #token.text
        if position.column >= column and position.column < finish then return token end
        column = finish
        last_token = token
    end
    return position.column == column and last_token or nil
end

function EditorCodeInput:getBracketMatch()
    if not self.buffer then return nil end
    if not self:updateSyntaxCache() then return nil end
    local syntax = self.lua_highlighter
    local cursor_offset = self.buffer:positionToOffset(self.cursor)
    local candidate
    if syntax.bracket_offsets[cursor_offset] then
        candidate = cursor_offset
    elseif cursor_offset > 0 and syntax.bracket_offsets[cursor_offset - 1] then
        candidate = cursor_offset - 1
    end
    if not candidate then return nil end
    local match = syntax.bracket_pairs[candidate]
    return self.buffer:offsetToPosition(candidate),
        match and self.buffer:offsetToPosition(match) or nil, 1, 1
end

function EditorCodeInput:getBlockKeywordMatch()
    if not self.buffer then return nil end
    if not self:updateSyntaxCache() then return nil end
    local syntax = self.lua_highlighter
    local cursor_offset = self.buffer:positionToOffset(self.cursor)
    local candidate = syntax.keyword_lookup[cursor_offset]
        or (cursor_offset > 0 and syntax.keyword_lookup[cursor_offset - 1])
    local token = candidate and syntax.keyword_tokens[candidate]
    if not token then return nil end
    local match = syntax.keyword_pairs[candidate]
    local matching_token = match and syntax.keyword_tokens[match] or nil
    return self.buffer:offsetToPosition(candidate),
        match and self.buffer:offsetToPosition(match) or nil,
        token.length, matching_token and matching_token.length or nil
end

function EditorCodeInput:onFocus()
    self.focused = true
    love.keyboard.setTextInput(true)
end

function EditorCodeInput:onBlur()
    self.focused = false
    self.mouse_selecting = false
    love.keyboard.setTextInput(false)
    self:closeCodeAssists()
    self:saveViewState()
end

function EditorCodeInput:hasSelection()
    return self.selection_anchor ~= nil and not samePosition(self.selection_anchor, self.cursor)
end

function EditorCodeInput:getSelection()
    if not self.buffer or not self:hasSelection() then return self.cursor, self.cursor end
    return self.buffer:ordered(self.selection_anchor, self.cursor)
end

function EditorCodeInput:clearSelection()
    self.selection_anchor = nil
end

function EditorCodeInput:getSelectedText()
    if not self.buffer then return "" end
    local first, last = self:getSelection()
    return self.buffer:getTextRange(first, last)
end

function EditorCodeInput:selectAll()
    if not self.buffer then return end
    self:closeCodeAssists()
    self.selection_anchor = { line = 1, column = 1 }
    self.cursor = self.buffer:getEndPosition()
    self:ensureCursorVisible()
end

function EditorCodeInput:setCursor(position, selecting)
    if not self.buffer then return end
    self:closeCodeAssists()
    if selecting then self.selection_anchor = self.selection_anchor or copyPosition(self.cursor)
    else self:clearSelection() end
    self.cursor = self.buffer:clampPosition(position)
    self:ensureCursorVisible()
end

function EditorCodeInput:setProtocolCursor(line, character, encoding)
    if not self.buffer then return end
    local line_index = MathUtils.clamp((line or 0) + 1, 1, self.buffer:getLineCount())
    self:setCursor({
        line = line_index,
        column = protocolCharacterToColumn(self.buffer:getLine(line_index), character, encoding)
    }, false)
end

function EditorCodeInput:getCursorPosition(position)
    if not self.buffer then return 0, 0 end
    position = self.buffer:clampPosition(position or self.cursor)
    local font = self:getFont()
    local line = self.buffer:getLine(position.line)
    return font:getWidth(line:sub(1, position.column - 1)), (position.line - 1) * font:getHeight()
end

function EditorCodeInput:getCursorAt(x, y)
    if not self.buffer then return { line = 1, column = 1 } end
    local font = self:getFont()
    local line_index = MathUtils.clamp(
        math.floor((y - self.padding_y + self.scroll_y) / font:getHeight()) + 1,
        1, self.buffer:getLineCount())
    local line = self.buffer:getLine(line_index)
    local target_x = x - self.padding_x + self.scroll_x
    local best_column, best_distance = 1, math.huge
    local column = 1
    while column <= #line + 1 do
        local width = font:getWidth(line:sub(1, column - 1))
        local distance = math.abs(target_x - width)
        if distance < best_distance then best_column, best_distance = column, distance end
        if column > #line then break end
        column = nextColumn(line, column)
    end
    return { line = line_index, column = best_column }
end

function EditorCodeInput:getMaxScrollY()
    if not self.buffer then return 0 end
    local font = self:getFont()
    return math.max(0, self.buffer:getLineCount() * font:getHeight() + self.padding_y * 2 - self.height)
end

function EditorCodeInput:ensureCursorVisible()
    if not self.buffer then return end
    local font = self:getFont()
    local x, y = self:getCursorPosition()
    local available_width = math.max(1, self.width - self.padding_x - 6)
    local available_height = math.max(font:getHeight(), self.height - self.padding_y * 2)
    if x - self.scroll_x < 0 then self.scroll_x = x end
    if x - self.scroll_x > available_width then self.scroll_x = x - available_width end
    if y - self.scroll_y < 0 then self.scroll_y = y end
    if y + font:getHeight() - self.scroll_y > available_height then
        self.scroll_y = y + font:getHeight() - available_height
    end
    self.scroll_x = math.max(0, self.scroll_x)
    self.scroll_y = MathUtils.clamp(self.scroll_y, 0, self:getMaxScrollY())
end

function EditorCodeInput:previousPosition(position)
    position = self.buffer:clampPosition(position)
    if position.column > 1 then
        return { line = position.line, column = previousColumn(self.buffer:getLine(position.line), position.column) }
    elseif position.line > 1 then
        local line = self.buffer:getLine(position.line - 1)
        return { line = position.line - 1, column = #line + 1 }
    end
    return position
end

function EditorCodeInput:nextPosition(position)
    position = self.buffer:clampPosition(position)
    local line = self.buffer:getLine(position.line)
    if position.column <= #line then
        return { line = position.line, column = nextColumn(line, position.column) }
    elseif position.line < self.buffer:getLineCount() then
        return { line = position.line + 1, column = 1 }
    end
    return position
end

function EditorCodeInput:replaceSelection(text)
    if not self.document then return false end
    local first, last = self:getSelection()
    local changed, edit = self.document:replaceRange(first, last, text)
    if not changed then return false end
    self.cursor = copyPosition(edit.new_end)
    self:clearSelection()
    self.preferred_x = nil
    self:ensureCursorVisible()
    self:scheduleAutomaticCompletion()
    return true
end

function EditorCodeInput:indentSelection(outdent)
    if not self.document or not self.buffer then return false end
    if self.document.read_only then return true end

    if not self:hasSelection() then
        if not outdent then
            local spaces = TAB_WIDTH - ((self.cursor.column - 1) % TAB_WIDTH)
            return self:replaceSelection(string.rep(" ", spaces))
        end
        local line = self.buffer:getLine(self.cursor.line)
        local leading = line:match("^[ \t]*") or ""
        local remove = leading:sub(1, 1) == "\t" and 1
            or math.min(#(leading:match("^ +") or ""), TAB_WIDTH)
        if remove == 0 then return true end
        self:closeCodeAssists()
        local changed = self.document:replaceRange(
            { line = self.cursor.line, column = 1 },
            { line = self.cursor.line, column = remove + 1 }, "")
        if changed then
            self.cursor.column = math.max(1, self.cursor.column - remove)
            self.preferred_x = nil
            self:ensureCursorVisible()
        end
        return true
    end

    local first, last = self:getSelection()
    local last_line = last.line
    if last.column == 1 and last_line > first.line then last_line = last_line - 1 end
    local replacement, deltas = {}, {}
    for line_index = first.line, last_line do
        local line = self.buffer:getLine(line_index)
        if outdent then
            local leading = line:match("^[ \t]*") or ""
            local remove = leading:sub(1, 1) == "\t" and 1
                or math.min(#(leading:match("^ +") or ""), TAB_WIDTH)
            replacement[#replacement + 1] = line:sub(remove + 1)
            deltas[line_index] = -remove
        else
            replacement[#replacement + 1] = string.rep(" ", TAB_WIDTH) .. line
            deltas[line_index] = TAB_WIDTH
        end
    end
    self:closeCodeAssists()
    local changed = self.document:replaceRange(
        { line = first.line, column = 1 },
        { line = last_line, column = #self.buffer:getLine(last_line) + 1 },
        table.concat(replacement, "\n"))
    if not changed then return true end

    local function adjust(position)
        local result = copyPosition(position)
        local delta = deltas[result.line]
        if delta and result.column > 1 then result.column = math.max(1, result.column + delta) end
        return self.buffer:clampPosition(result)
    end
    self.selection_anchor = adjust(self.selection_anchor)
    self.cursor = adjust(self.cursor)
    self.preferred_x = nil
    self:ensureCursorVisible()
    return true
end

function EditorCodeInput:getWordRangeAtCursor()
    local line = self.buffer:getLine(self.cursor.line)
    local first, last = self.cursor.column, self.cursor.column
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
    return { line = self.cursor.line, column = first }, { line = self.cursor.line, column = last }
end

function EditorCodeInput:scheduleAutomaticCompletion()
    self.completion_generation = self.completion_generation + 1
    self.completion_popup:close()
    self.completion_defaults = nil
    self:closeHover()
    if not self.buffer or not self.document or self.document.read_only
        or self.document.language_id ~= "lua" then
        self.completion_due = nil
        return
    end
    local line = self.buffer:getLine(self.cursor.line)
    local before = line:sub(1, self.cursor.column - 1)
    local trigger = before:sub(-1)
    if trigger:match("[%w_%.:]") then
        self.completion_due = {
            time = love.timer.getTime() + 0.12,
            trigger = (trigger == "." or trigger == ":") and trigger or nil
        }
    else
        self.completion_due = nil
    end
end

function EditorCodeInput:requestCompletion(manual, trigger)
    local service = self.language_service
    if not service or not self.document or self.document.read_only
        or self.document.language_id ~= "lua" then return false end
    self.completion_generation = self.completion_generation + 1
    local generation = self.completion_generation
    local document, version = self.document, self.document.version
    local position = copyPosition(self.cursor)
    self.completion_due = nil
    self:closeHover()
    local context = trigger and { triggerKind = 2, triggerCharacter = trigger } or { triggerKind = 1 }
    service:requestCompletion(document, position, context, function(result, response_error)
        if generation ~= self.completion_generation or document ~= self.document
            or version ~= document.version or not samePosition(position, self.cursor) then return end
        if response_error then
            if manual and self.editor.message_bar then
                self.editor.message_bar:setStatus(response_error.message or "Completion failed", 4)
            end
            return
        end
        if result == nil or result == JSON.null then return self.completion_popup:close() end
        local items = result.items or result
        if type(items) ~= "table" then return self.completion_popup:close() end
        local filtered = {}
        for _, item in ipairs(items) do
            if type(item) == "table" and type(item.label) == "string" and item.label ~= "" then
                table.insert(filtered, item)
            end
        end
        self.completion_defaults = result.items and result.itemDefaults or nil
        local cursor_x, cursor_y = self:getCursorPosition()
        local font = self:getFont()
        self.completion_popup:open(filtered,
            self.padding_x + cursor_x - self.scroll_x,
            self.padding_y + cursor_y - self.scroll_y + font:getHeight(),
            self.width, self.height)
    end)
    return true
end

function EditorCodeInput:completionEdit(item)
    local defaults = self.completion_defaults or {}
    local text_edit = item.textEdit
    local range, text
    if type(text_edit) == "table" then
        range = text_edit.range or text_edit.insert or text_edit.replace
        text = text_edit.newText
    elseif type(defaults.editRange) == "table" then
        range = defaults.editRange.start and defaults.editRange
            or defaults.editRange.insert or defaults.editRange.replace
        text = item.textEditText
    end
    text = text or item.insertText or item.label
    local format = item.insertTextFormat or defaults.insertTextFormat
    text = completionText(text, format)
    local first, last
    if type(range) == "table" and type(range.start) == "table" and type(range["end"]) == "table" then
        first = protocolPositionToBuffer(self.buffer, range.start,
            self.language_service and self.language_service.position_encoding)
        last = protocolPositionToBuffer(self.buffer, range["end"],
            self.language_service and self.language_service.position_encoding)
    else
        first, last = self:getWordRangeAtCursor()
    end
    return { start = first, finish = last, text = text }
end

function EditorCodeInput:acceptCompletion(index)
    local item = index and self.completion_popup.items[index] or self.completion_popup:getSelectedItem()
    if not item or not self.document then return false end
    local edits = { self:completionEdit(item) }
    for _, additional in ipairs(item.additionalTextEdits or {}) do
        local range = additional.range
        if type(range) == "table" and type(range.start) == "table" and type(range["end"]) == "table" then
            table.insert(edits, {
                start = protocolPositionToBuffer(self.buffer, range.start,
                    self.language_service and self.language_service.position_encoding),
                finish = protocolPositionToBuffer(self.buffer, range["end"],
                    self.language_service and self.language_service.position_encoding),
                text = tostring(additional.newText or "")
            })
        end
    end
    self.completion_generation = self.completion_generation + 1
    self.completion_popup:close()
    self.completion_defaults = nil
    local changed, cursor_or_reason = self.document:applyTextEdits(edits, 1)
    if not changed then
        self.editor:addWarning("Could not apply completion", cursor_or_reason, "luals_completion")
        return false
    end
    self.cursor = cursor_or_reason
    self:clearSelection()
    self.preferred_x = nil
    self:ensureCursorVisible()
    return true
end

function EditorCodeInput:requestHover(position, x, y, explicit)
    local service = self.language_service
    if not service or not self.document or self.document.language_id ~= "lua" then return false end
    position = copyPosition(position or self.cursor)
    local token = self:getSyntaxTokenAt(position)
    if token and (token.kind == "string" or StringUtils.startsWith(token.kind, "text_command_")) then
        self.hover_generation = self.hover_generation + 1
        self.hover_explicit = false
        self.hover_popup:close()
        return true
    end
    self.hover_generation = self.hover_generation + 1
    local generation = self.hover_generation
    local document, version = self.document, self.document.version
    if explicit then
        self.hover_explicit = true
        self.hover_mouse_x, self.hover_mouse_y = self.editor:getMousePosition()
    end
    service:requestHover(document, position, function(result, response_error)
        if generation ~= self.hover_generation or document ~= self.document or version ~= document.version
            or self.completion_popup.visible then return end
        if response_error or result == nil or result == JSON.null then
            self.hover_explicit = false
            if explicit and response_error and self.editor.message_bar then
                self.editor.message_bar:setStatus(response_error.message or "Hover failed", 4)
            end
            return self.hover_popup:close()
        end
        self.hover_popup:show(result, x, y, self.width, self.height)
    end)
    return true
end

function EditorCodeInput:selectWordAt(position)
    if not self.buffer then return end
    position = self.buffer:clampPosition(position)
    local line = self.buffer:getLine(position.line)
    local first, last = position.column, position.column
    while first > 1 do
        local previous = previousColumn(line, first)
        if not line:sub(previous, first - 1):match("[%w_]") then break end
        first = previous
    end
    while last <= #line do
        local next_column = nextColumn(line, last)
        if not line:sub(last, next_column - 1):match("[%w_]") then break end
        last = next_column
    end
    self.selection_anchor = { line = position.line, column = first }
    self.cursor = { line = position.line, column = last }
end

function EditorCodeInput:onMousePressed(x, y, button, presses)
    if not self.buffer then return false end
    if button == 1 and self.completion_popup.visible then
        local index = self.completion_popup:getItemAt(x, y)
        if index then
            self.completion_popup.selected = index
            return self:acceptCompletion(index)
        end
    end
    local position = self:getCursorAt(x, y)
    if button == 2 then
        self:setCursor(position, false)
        local global_x, global_y = self:getGlobalPosition()
        local items = {
            { label = "Go to Definition (F12)", action = function()
                self.code_editor:requestDefinition(copyPosition(self.cursor))
            end },
            { label = "Find References (Shift+F12)", action = function()
                self.code_editor:requestReferences(copyPosition(self.cursor))
            end },
            { label = "Show Hover", action = function()
                local cursor_x, cursor_y = self:getCursorPosition()
                self:requestHover(self.cursor, self.padding_x + cursor_x - self.scroll_x,
                    self.padding_y + cursor_y - self.scroll_y, true)
            end }
        }
        if not self.document.read_only then
            if self.document.language_id == "lua" then
                table.insert(items, { label = "Format Document (Shift+Alt+F)", action = function()
                    self.code_editor:formatActiveDocument()
                end })
            end
            table.insert(items, { label = "Trigger Completion (Ctrl+Space)", action = function()
                self:requestCompletion(true)
            end })
        end
        self.editor.dockspace:openContextMenu(items, global_x + x, global_y + y, self)
        return true
    elseif button ~= 1 then
        return false
    end
    if Input.ctrl() then
        self:setCursor(position, false)
        return self.code_editor:requestDefinition(copyPosition(position))
    end
    self:closeCodeAssists()
    if Input.shift() then self.selection_anchor = self.selection_anchor or copyPosition(self.cursor)
    else self.selection_anchor = copyPosition(position) end
    self.cursor = position
    if presses and presses >= 2 then self:selectWordAt(position) end
    self.mouse_selecting = true
    self.preferred_x = nil
    self:ensureCursorVisible()
    return true
end

function EditorCodeInput:onMouseMoved(x, y)
    if not self.mouse_selecting or not self.buffer then return false end
    self.cursor = self:getCursorAt(x, y)
    self:ensureCursorVisible()
    return true
end

function EditorCodeInput:onMouseReleased(_, _, button)
    if button ~= 1 or not self.mouse_selecting then return false end
    self.mouse_selecting = false
    if samePosition(self.selection_anchor, self.cursor) then self:clearSelection() end
    return true
end

function EditorCodeInput:onWheelMoved(_, y)
    if self.completion_popup.visible then return self.completion_popup:scrollRows(-y) end
    if self.hover_popup.visible and self.hover_popup:scrollRows(-y * 3) then return true end
    self:closeHover()
    local font = self:getFont()
    self.scroll_y = MathUtils.clamp(self.scroll_y - y * font:getHeight() * 3, 0, self:getMaxScrollY())
    return true
end

function EditorCodeInput:onKeyPressed(key, is_repeat)
    if not self.buffer then return false end
    local ctrl, shift = Input.ctrl(), Input.shift()
    if self.completion_popup.visible then
        if key == "escape" then return self.completion_popup:close() end
        if key == "up" then return self.completion_popup:moveSelection(-1) end
        if key == "down" then return self.completion_popup:moveSelection(1) end
        if key == "pageup" then return self.completion_popup:pageSelection(-1) end
        if key == "pagedown" then return self.completion_popup:pageSelection(1) end
        if key == "return" or key == "kpenter" or key == "tab" then
            return self:acceptCompletion()
        end
    end
    if key == "f12" then
        if shift then return self.code_editor:requestReferences(copyPosition(self.cursor)) end
        return self.code_editor:requestDefinition(copyPosition(self.cursor))
    end
    if shift and Input.alt() and key == "f" then
        return self.code_editor:formatActiveDocument()
    end
    if ctrl and key == "space" then
        if self.document.read_only then return true end
        return self:requestCompletion(true)
    end
    if key == "escape" and self.hover_popup.visible then return self:closeHover() end
    if ctrl and not is_repeat then
        if key == "s" then return self.code_editor:saveActiveDocument() end
        if key == "z" then
            if shift then return self.code_editor:redo() end
            return self.code_editor:undo()
        end
        if key == "y" then return self.code_editor:redo() end
    end
    if ctrl and key == "a" then self:selectAll() return true end
    if ctrl and key == "c" then
        if self:hasSelection() then love.system.setClipboardText(self:getSelectedText()) end
        return true
    elseif ctrl and key == "x" then
        if self:hasSelection() then
            love.system.setClipboardText(self:getSelectedText())
            self:replaceSelection("")
        end
        return true
    elseif ctrl and key == "v" then
        return self:replaceSelection(love.system.getClipboardText() or "")
    elseif ctrl and key == "home" then
        self:setCursor({ line = 1, column = 1 }, shift)
        return true
    elseif ctrl and key == "end" then
        self:setCursor(self.buffer:getEndPosition(), shift)
        return true
    end

    if key == "backspace" then
        if self:hasSelection() then return self:replaceSelection("") end
        local previous = self:previousPosition(self.cursor)
        if not samePosition(previous, self.cursor) then
            self.selection_anchor = previous
            return self:replaceSelection("")
        end
        return true
    elseif key == "delete" then
        if self:hasSelection() then return self:replaceSelection("") end
        local following = self:nextPosition(self.cursor)
        if not samePosition(following, self.cursor) then
            self.selection_anchor = following
            return self:replaceSelection("")
        end
        return true
    elseif key == "left" or key == "right" then
        if self:hasSelection() and not shift then
            local first, last = self:getSelection()
            self:setCursor(key == "left" and first or last, false)
        else
            self:setCursor(key == "left" and self:previousPosition(self.cursor)
                or self:nextPosition(self.cursor), shift)
        end
        self.preferred_x = nil
        return true
    elseif key == "home" or key == "end" then
        local line = self.buffer:getLine(self.cursor.line)
        self:setCursor({ line = self.cursor.line, column = key == "home" and 1 or (#line + 1) }, shift)
        self.preferred_x = nil
        return true
    elseif key == "up" or key == "down" then
        local x = self:getCursorPosition()
        self.preferred_x = self.preferred_x or x
        local target_line = MathUtils.clamp(self.cursor.line + (key == "up" and -1 or 1),
            1, self.buffer:getLineCount())
        self:setCursor(self:getCursorAt(self.padding_x + self.preferred_x - self.scroll_x,
            self.padding_y + (target_line - 1) * self:getFont():getHeight()
                - self.scroll_y), shift)
        return true
    elseif key == "return" or key == "kpenter" then
        local line = self.buffer:getLine(self.cursor.line)
        local before = line:sub(1, self.cursor.column - 1)
        return self:replaceSelection("\n" .. (before:match("^%s*") or ""))
    elseif key == "tab" then
        return self:indentSelection(shift)
    end
    return false
end

function EditorCodeInput:onTextInput(text)
    return self:replaceSelection(text)
end

function EditorCodeInput:update(dt)
    self.scroll_y = MathUtils.clamp(self.scroll_y, 0, self:getMaxScrollY())
    if self.completion_due and love.timer.getTime() >= self.completion_due.time then
        local trigger = self.completion_due.trigger
        self.completion_due = nil
        self:requestCompletion(false, trigger)
    end
    local context_menu_open = self.editor and self.editor.dockspace
        and self.editor.dockspace.context_menu ~= nil
    local mouse_x, mouse_y = self.editor:getMousePosition()
    local over_hover = self.hover_popup.visible and self.hover_popup:containsPoint(mouse_x, mouse_y)
    if self.hover_explicit then
        if not self.hover_mouse_x or math.abs(mouse_x - self.hover_mouse_x) > 2
            or math.abs(mouse_y - self.hover_mouse_y) > 2 then
            if not over_hover then self:closeHover() end
        end
    elseif over_hover then
        self.hover_elapsed = 0
    elseif self.document and self.document.language_id == "lua" and not self.completion_popup.visible
        and not self.mouse_selecting and not context_menu_open then
        if self:containsPoint(mouse_x, mouse_y) then
            local x, y = self:toLocal(mouse_x, mouse_y)
            if x >= self.padding_x and y >= self.padding_y then
                local position = self:getCursorAt(x, y)
                local candidate = tostring(self.document.version) .. ":" .. position.line .. ":" .. position.column
                if candidate ~= self.hover_candidate then
                    self.hover_candidate = candidate
                    self.hover_elapsed = 0
                    self.hover_requested = nil
                    self.hover_generation = self.hover_generation + 1
                    self.hover_popup:close()
                else
                    self.hover_elapsed = self.hover_elapsed + dt
                    if self.hover_elapsed >= 0.45 and self.hover_requested ~= candidate then
                        self.hover_requested = candidate
                        self:requestHover(position, x, y, false)
                    end
                end
            else
                self.hover_popup:close()
                self.hover_candidate = nil
            end
        else
            self.hover_generation = self.hover_generation + 1
            self:closeHover()
            self.hover_candidate = nil
            self.hover_requested = nil
            self.hover_elapsed = 0
        end
    elseif self.completion_popup.visible or context_menu_open then
        self.hover_popup:close()
    end
    super.update(self, dt)
end

function EditorCodeInput:drawSelection(line_index, line, y, font)
    if not self:hasSelection() then return end
    local first, last = self:getSelection()
    if line_index < first.line or line_index > last.line then return end
    local first_column = line_index == first.line and first.column or 1
    local last_column = line_index == last.line and last.column or (#line + 1)
    if first_column >= last_column and not (line_index < last.line) then return end
    local x1 = self.padding_x + font:getWidth(line:sub(1, first_column - 1)) - self.scroll_x
    local x2 = self.padding_x + font:getWidth(line:sub(1, last_column - 1)) - self.scroll_x
    Draw.setColor(0.24, 0.42, 0.68, 0.85)
    love.graphics.rectangle("fill", x1, y, math.max(line_index < last.line and 3 or 1, x2 - x1), font:getHeight())
end

function EditorCodeInput:drawDiagnostics(line_index, line, y, font)
    for _, diagnostic in ipairs(self.diagnostics or {}) do
        local range = diagnostic.range
        if range and range.start and range["end"] and line_index == (range.start.line or 0) + 1 then
            local first = protocolCharacterToColumn(line, range.start.character,
                self.document and self.document.diagnostic_encoding)
            local last = range["end"].line == range.start.line
                and protocolCharacterToColumn(line, range["end"].character,
                    self.document and self.document.diagnostic_encoding)
                or (#line + 1)
            local x1 = self.padding_x + font:getWidth(line:sub(1, first - 1)) - self.scroll_x
            local x2 = self.padding_x + font:getWidth(line:sub(1, math.max(first, last) - 1)) - self.scroll_x
            Draw.setColor((diagnostic.severity or 2) == 1 and { 1, 0.32, 0.32, 1 }
                or { 1, 0.72, 0.25, 1 })
            love.graphics.line(x1, y + font:getHeight() - 2, math.max(x1 + 3, x2), y + font:getHeight() - 2)
        end
    end
end

function EditorCodeInput:drawBracketMatches(line_index, line, y, font, first, second, first_length, second_length)
    for index, position in ipairs({ first, second }) do
        if position and position.line == line_index then
            local length = index == 1 and (first_length or 1) or (second_length or 1)
            local character = line:sub(position.column, position.column + length - 1)
            local x = self.padding_x + font:getWidth(line:sub(1, position.column - 1)) - self.scroll_x
            local width = math.max(2, font:getWidth(character))
            Draw.setColor(second and { 0.24, 0.48, 0.42, 0.65 }
                or { 0.62, 0.24, 0.28, 0.75 })
            love.graphics.rectangle("fill", x, y, width, font:getHeight())
            if index == 1 then
                Draw.setColor(second and { 0.48, 0.86, 0.70, 1 }
                    or { 1, 0.42, 0.46, 1 })
                love.graphics.rectangle("line", x + 0.5, y + 0.5,
                    math.max(1, width - 1), math.max(1, font:getHeight() - 1))
            end
        end
    end
end

function EditorCodeInput:drawBlockGuides(first_line, last_line, line_height, font, gutter)
    if not self:updateSyntaxCache() or #self.block_guides == 0 then return end
    local cursor_offset = self.buffer:positionToOffset(self.cursor)
    local active
    for _, guide in ipairs(self.block_guides) do
        if cursor_offset >= guide.open_offset and cursor_offset <= guide.close_offset
            and (not active or guide.depth >= active.depth) then
            active = guide
        end
    end
    local colors = {
        { 0.38, 0.58, 0.84 },
        { 0.68, 0.48, 0.82 },
        { 0.78, 0.62, 0.35 }
    }
    local old_width = love.graphics.getLineWidth()
    love.graphics.setLineWidth(1)
    for _, guide in ipairs(self.block_guides) do
        if guide.opening.line < guide.closing.line
            and guide.closing.line >= first_line and guide.opening.line <= last_line then
            local opening_line = self.buffer:getLine(guide.opening.line)
            local x = self.padding_x + font:getWidth(opening_line:sub(1, guide.column - 1))
                - self.scroll_x - 3.5
            if x >= gutter + 2 and x <= self.width then
                local start_y = self.padding_y + (guide.opening.line - 0.42) * line_height - self.scroll_y
                local end_y = self.padding_y + (guide.closing.line - 0.58) * line_height - self.scroll_y
                local color = colors[((guide.depth - 1) % #colors) + 1]
                Draw.setColor(color[1], color[2], color[3], guide == active and 0.9 or 0.38)
                love.graphics.line(x, start_y, x, end_y)
                love.graphics.line(x, start_y, x + 4, start_y)
                love.graphics.line(x, end_y, x + 4, end_y)
            end
        end
    end
    love.graphics.setLineWidth(old_width)
end

function EditorCodeInput:drawSelf()
    local font = self:getFont()
    love.graphics.setFont(font)
    Draw.setColor(0.055, 0.055, 0.065, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(self.focused and { 0.34, 0.46, 0.68, 1 } or { 0.22, 0.22, 0.26, 1 })
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)

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
    self:drawBlockGuides(first_line, last_line, line_height, font, gutter)
    local bracket, matching_bracket, bracket_length, matching_length = self:getBracketMatch()
    if not bracket then
        bracket, matching_bracket, bracket_length, matching_length = self:getBlockKeywordMatch()
    end
    for line_index = first_line, last_line do
        local line = self.buffer:getLine(line_index)
        local y = self.padding_y + (line_index - 1) * line_height - self.scroll_y
        self:drawSelection(line_index, line, y, font)
        self:drawBracketMatches(line_index, line, y, font, bracket, matching_bracket,
            bracket_length, matching_length)
        Draw.setColor(0.40, 0.40, 0.46, 1)
        local number = tostring(line_index)
        love.graphics.print(number, gutter - font:getWidth(number) - 5, y)
        local x = self.padding_x - self.scroll_x
        local tokens = self:updateSyntaxCache() and self.lua_highlighter:getLine(line_index)
            or { { text = line, kind = "text" } }
        for _, token in ipairs(tokens) do
            Draw.setColor(COLORS[token.kind] or COLORS.text)
            love.graphics.print(token.text, x, y)
            x = x + font:getWidth(token.text)
        end
        self:drawDiagnostics(line_index, line, y, font)
    end

    if self.focused and math.floor(Kristal.getTime() * 2) % 2 == 0 then
        local cursor_x, cursor_y = self:getCursorPosition()
        cursor_x = self.padding_x + cursor_x - self.scroll_x
        cursor_y = self.padding_y + cursor_y - self.scroll_y
        Draw.setColor(0.95, 0.95, 0.98, 1)
        love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + line_height)
    end
end

return EditorCodeInput
