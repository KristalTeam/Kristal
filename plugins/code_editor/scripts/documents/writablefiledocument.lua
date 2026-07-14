---@class EditorWritableFileDocument : EditorFileDocument
local EditorWritableFileDocument, super = Class(EditorFileDocument)

local DEFAULT_HISTORY_LIMIT = 1000

local function contentHash(text)
    return love.data.hash("sha256", tostring(text or ""))
end

local function protocolChange(edit)
    return {
        range = {
            start = { line = edit.start.line - 1, character = edit.start.column - 1 },
            ["end"] = { line = edit.old_end.line - 1, character = edit.old_end.column - 1 }
        },
        text = edit.inserted,
        start_line_text = edit.old_start_line,
        end_line_text = edit.old_end_line
    }
end

function EditorWritableFileDocument:init(workspace, path, contents, options)
    options = options or {}
    super.init(self, workspace, path, contents, options)
    self.read_only = options.read_only == true
    self.writable_code_document = not self.read_only
    self.saved_hash = contentHash(self.buffer:getText())
    self.version = 1
    self.state_id = 1
    self.saved_state_id = 1
    self.next_state_id = 2
    self.undo_stack = {}
    self.redo_stack = {}
end

function EditorWritableFileDocument:getText()
    return self.buffer:getText()
end

function EditorWritableFileDocument:isDirty()
    return self.state_id ~= self.saved_state_id
end

function EditorWritableFileDocument:getHistoryLimit()
    local history = self.workspace.editor and self.workspace.editor.history
    return history and history.getLimit and history:getLimit() or DEFAULT_HISTORY_LIMIT
end

function EditorWritableFileDocument:notifyChanged(edit)
    self.version = self.version + 1
    self.workspace:onDocumentChanged(self, { change = protocolChange(edit) })
end

function EditorWritableFileDocument:replaceRange(first, last, text, options)
    options = options or {}
    if self.read_only then return false, "This document is read-only" end
    local edit = self.buffer:replace(first, last, text)
    if edit.inserted == edit.removed then return false end
    if options.history ~= false then
        edit.before_state = self.state_id
        edit.after_state = self.next_state_id
        self.next_state_id = self.next_state_id + 1
        self.state_id = edit.after_state
        table.insert(self.undo_stack, edit)
        while #self.undo_stack > self:getHistoryLimit() do table.remove(self.undo_stack, 1) end
        self.redo_stack = {}
    end
    self:notifyChanged(edit)
    return true, edit
end

function EditorWritableFileDocument:applyTextEdits(edits, primary_index)
    if self.read_only then return false, "This document is read-only" end
    if type(edits) ~= "table" or #edits == 0 then return false, "No edits to apply" end
    primary_index = primary_index or 1
    local normalized = {}
    for index, edit in ipairs(edits) do
        if type(edit) ~= "table" or type(edit.start) ~= "table" or type(edit.finish) ~= "table" then
            return false, "Invalid text edit"
        end
        local first, last = self.buffer:ordered(edit.start, edit.finish)
        table.insert(normalized, {
            index = index,
            start = self.buffer:positionToOffset(first),
            finish = self.buffer:positionToOffset(last),
            text = tostring(edit.text or "")
        })
    end
    table.sort(normalized, function(first, second)
        if first.start ~= second.start then return first.start < second.start end
        if first.finish ~= second.finish then return first.finish < second.finish end
        return first.index < second.index
    end)
    for index = 2, #normalized do
        if normalized[index].start < normalized[index - 1].finish then
            return false, "Overlapping text edits"
        end
    end
    local primary
    for _, edit in ipairs(normalized) do
        if edit.index == primary_index then primary = edit break end
    end
    if not primary then return false, "Primary text edit is missing" end
    local cursor_offset = primary.start + #primary.text
    for _, edit in ipairs(normalized) do
        if edit ~= primary and edit.finish <= primary.start then
            cursor_offset = cursor_offset + #edit.text - (edit.finish - edit.start)
        end
    end
    local text = self.buffer:getText()
    for index = #normalized, 1, -1 do
        local edit = normalized[index]
        text = text:sub(1, edit.start) .. edit.text .. text:sub(edit.finish + 1)
    end
    local final_buffer = EditorCodeBuffer(text)
    local changed = self:setText(text)
    if not changed then return false, "Text edits did not change the document" end
    return true, final_buffer:offsetToPosition(cursor_offset)
end

function EditorWritableFileDocument:setText(text, options)
    return self:replaceRange({ line = 1, column = 1 }, self.buffer:getEndPosition(), text, options)
end

function EditorWritableFileDocument:undo()
    local original = table.remove(self.undo_stack)
    if not original then return false end
    local edit = self.buffer:replace(original.start, original.new_end, original.removed)
    self.state_id = original.before_state
    table.insert(self.redo_stack, original)
    self:notifyChanged(edit)
    return true, edit
end

function EditorWritableFileDocument:redo()
    local original = table.remove(self.redo_stack)
    if not original then return false end
    local edit = self.buffer:replace(original.start, original.old_end, original.inserted)
    self.state_id = original.after_state
    table.insert(self.undo_stack, original)
    self:notifyChanged(edit)
    return true, edit
end

function EditorWritableFileDocument:save()
    if self.read_only then return false, "This document is read-only" end
    local disk_text, read_error = ProjectFileSystem.readFile(self.path)
    if disk_text == nil then return false, read_error or "The file can no longer be read from disk" end
    if contentHash(disk_text:gsub("\r\n", "\n"):gsub("\r", "\n")) ~= self.saved_hash then
        return false, "The file changed outside Kristal after it was opened"
    end
    local text = self.buffer:getText()
    local written, reason = ProjectFileSystem.writeFile(self.path, text)
    if not written then return false, reason end
    self.saved_hash = contentHash(text)
    self.saved_state_id = self.state_id
    self.workspace:onDocumentSaved(self)
    return true
end

function EditorWritableFileDocument:setDiagnostics(diagnostics)
    self.diagnostics = diagnostics or {}
    self.workspace:refreshDocument(self)
end

return EditorWritableFileDocument
