---@class EditorCodeEditor : EditorControl
---@overload fun(editor: Editor, workspace: EditorProjectWorkspace): EditorCodeEditor
local EditorCodeEditor, super = Class(EditorControl)
local EditorCodeInput = ...

local TAB_HEIGHT = 30
local STATUS_HEIGHT = 22

function EditorCodeEditor:init(editor, workspace, language_service)
    super.init(self, 0, 0, 760, 520)
    self.editor = editor
    self.workspace = workspace
    self.language_service = language_service
    self.documents = {}
    self.active_document = nil
    self.tab_rects = {}
    self.navigation_request = 0
    self.format_request = 0
    self.clip = true
    self.input = self:addChild(EditorCodeInput({
        editor = editor,
        code_editor = self,
        language_service = language_service
    }))
    self.image_preview = self:addChild(EditorImagePreview())
end

function EditorCodeEditor:openDocument(document, options)
    if not TableUtils.contains(self.documents, document) then table.insert(self.documents, document) end
    options = options or {}
    self:setActiveDocument(document, options.focus ~= false)
    if document.file_type == "text" and options.line ~= nil then
        self.input:setProtocolCursor(options.line, options.character or 0,
            options.encoding or document.diagnostic_encoding
                or (self.language_service and self.language_service.position_encoding))
    end
    return true
end

function EditorCodeEditor:setActiveDocument(document, focus)
    if not document then return false end
    if document ~= self.active_document then
        self.navigation_request = self.navigation_request + 1
        self.format_request = self.format_request + 1
    end
    self.active_document = document
    if document.file_type == "image" then
        self.input:setDocument(nil)
        self.image_preview:setDocument(document)
    else
        self.image_preview:setDocument(nil)
        self.input:setDocument(document)
    end
    if focus ~= false and self.editor.dockspace then
        self.editor.dockspace:setFocus(document.file_type == "text" and self.input or self)
    end
    return true
end

function EditorCodeEditor:refreshDocument(document)
    if document == self.active_document then
        self.input.diagnostics = document.diagnostics or {}
    end
end

function EditorCodeEditor:closeDocument(document)
    document = document or self.active_document
    if not document then return false end
    if document:isDirty() then
        if not self.editor:confirmUnsavedChanges({
            dirty = true,
            save_label = "Save",
            message = "Save changes to '" .. document.relative_path .. "' before closing it?",
            save = function() return document:save() end
        }) then return false end
    end
    local index
    for candidate_index, candidate in ipairs(self.documents) do
        if candidate == document then index = candidate_index break end
    end
    if not index then return false end
    if not self.workspace:closeDocument(document, { discard = true }) then return false end
    table.remove(self.documents, index)
    if self.active_document == document then
        self.navigation_request = self.navigation_request + 1
        self.format_request = self.format_request + 1
        self.active_document = nil
        local next_document = self.documents[math.min(index, #self.documents)]
        if next_document then
            self:setActiveDocument(next_document)
        else
            self.input:setDocument(nil)
        end
    end
    return true
end

function EditorCodeEditor:saveActiveDocument()
    if not self.active_document then return false end
    if self.active_document.read_only then
        if self.editor.message_bar then self.editor.message_bar:setStatus("This preview is read-only", 4) end
        return false
    end
    local saved, reason = self.active_document:save()
    if not saved then self.editor:addError("Could not save " .. self.active_document.relative_path,
        reason, "filesystem") end
    return saved
end

function EditorCodeEditor:undo()
    if not self.active_document or self.active_document.file_type ~= "text" then return false end
    local changed, edit = self.active_document:undo()
    if not changed then return false end
    self.input.cursor = { line = edit.new_end.line, column = edit.new_end.column }
    self.input:clearSelection()
    self.input:ensureCursorVisible()
    return true
end

function EditorCodeEditor:redo()
    if not self.active_document or self.active_document.file_type ~= "text" then return false end
    local changed, edit = self.active_document:redo()
    if not changed then return false end
    self.input.cursor = { line = edit.new_end.line, column = edit.new_end.column }
    self.input:clearSelection()
    self.input:ensureCursorVisible()
    return true
end

function EditorCodeEditor:goTo(document, line, character, encoding)
    self:openDocument(document)
    self.input:setProtocolCursor(line, character, encoding or document.diagnostic_encoding
        or (self.language_service and self.language_service.position_encoding))
end

function EditorCodeEditor:navigateToLocation(location)
    local document, reason = self.workspace:openDocumentByRealPath(location.path)
    if not document then
        self.editor:addWarning("Could not open language server target", reason, "luals_navigation")
        return false
    end
    local start = location.range and location.range.start or {}
    return self.editor:openDocument(document, {
        line = start.line or 0,
        character = start.character or 0,
        encoding = self.language_service and self.language_service.position_encoding
    })
end

function EditorCodeEditor:showLocations(locations, kind)
    if kind == "Definitions" and locations and #locations > 1 then
        local source_locations = {}
        for _, location in ipairs(locations) do
            local path = tostring(location.path or ""):gsub("\\", "/"):lower()
            if not path:match("/main%.lua$") then table.insert(source_locations, location) end
        end
        if #source_locations > 0 then locations = source_locations end
    end
    if not locations or #locations == 0 then
        if self.editor.message_bar then self.editor.message_bar:setStatus("No " .. kind:lower() .. " found", 4) end
        return false
    end
    if #locations == 1 then return self:navigateToLocation(locations[1]) end
    local items = {}
    for _, location in ipairs(locations) do
        local target = location
        table.insert(items, { label = target.label, action = function() self:navigateToLocation(target) end })
    end
    local cursor_x, cursor_y = self.input:getCursorPosition()
    local global_x, global_y = self.input:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items,
        global_x + self.input.padding_x + cursor_x - self.input.scroll_x,
        global_y + self.input.padding_y + cursor_y - self.input.scroll_y + 20,
        self, { searchable = true, maximum_rows = 14 })
    if self.editor.message_bar then
        self.editor.message_bar:setStatus(tostring(#locations) .. " " .. kind:lower() .. " found", 4)
    end
    return true
end

function EditorCodeEditor:requestDefinition(position)
    local service, document = self.language_service, self.active_document
    if not service or not document then return false end
    self.navigation_request = self.navigation_request + 1
    local request = self.navigation_request
    service:requestDefinition(document, position or self.input.cursor, function(locations, response_error)
        if request ~= self.navigation_request then return end
        if response_error then
            self.editor:addWarning("Could not find definition", response_error.message, "luals_navigation")
            return
        end
        self:showLocations(locations, "Definitions")
    end)
    return true
end

function EditorCodeEditor:requestReferences(position)
    local service, document = self.language_service, self.active_document
    if not service or not document then return false end
    self.navigation_request = self.navigation_request + 1
    local request = self.navigation_request
    service:requestReferences(document, position or self.input.cursor, function(locations, response_error)
        if request ~= self.navigation_request then return end
        if response_error then
            self.editor:addWarning("Could not find references", response_error.message, "luals_navigation")
            return
        end
        self:showLocations(locations, "References")
    end)
    return true
end

function EditorCodeEditor:formatActiveDocument()
    local service, document = self.language_service, self.active_document
    if not service or not document or document.language_id ~= "lua" then return false end
    if document.read_only then
        if self.editor.message_bar then self.editor.message_bar:setStatus("Read-only files cannot be formatted", 4) end
        return true
    end
    self.format_request = self.format_request + 1
    local request, version = self.format_request, document.version
    local cursor = { line = self.input.cursor.line, column = self.input.cursor.column }
    service:requestFormatting(document, { tabSize = 4, insertSpaces = true,
        trimTrailingWhitespace = true, insertFinalNewline = true,
        trimFinalNewlines = true }, function(result, response_error)
        if request ~= self.format_request or document ~= self.active_document
            or version ~= document.version then return end
        if response_error then
            self.editor:addWarning("Could not format " .. document.relative_path,
                response_error.message, "luals_format")
            return
        end
        if type(result) ~= "table" or #result == 0 then
            if self.editor.message_bar then self.editor.message_bar:setStatus("Document is already formatted", 3) end
            return
        end
        local edits = {}
        local encoding = service.position_encoding
        for _, edit in ipairs(result) do
            local range = edit.range
            if type(range) == "table" and range.start and range["end"] then
                table.insert(edits, {
                    start = self.input:getBufferPositionFromProtocol(range.start, encoding),
                    finish = self.input:getBufferPositionFromProtocol(range["end"], encoding),
                    text = tostring(edit.newText or "")
                })
            end
        end
        if #edits == 0 then return end
        local changed, reason = document:applyTextEdits(edits, 1)
        if not changed then
            self.editor:addWarning("Could not apply formatting", reason, "luals_format")
            return
        end
        self.input.cursor = document.buffer:clampPosition(cursor)
        self.input:clearSelection()
        self.input:closeCodeAssists()
        self.input:ensureCursorVisible()
        if self.editor.message_bar then self.editor.message_bar:setStatus("Formatted " .. document.relative_path, 3) end
    end)
    return true
end

function EditorCodeEditor:onMousePressed(x, y, button)
    if y >= TAB_HEIGHT or button ~= 1 then return false end
    for _, tab in ipairs(self.tab_rects) do
        if x >= tab.x and x < tab.x + tab.width then
            if x >= tab.x + tab.width - 22 then return self:closeDocument(tab.document) end
            self:setActiveDocument(tab.document)
            return true
        end
    end
    return true
end

function EditorCodeEditor:getCursorType(x, y)
    local select_cursor = y < TAB_HEIGHT or not self.active_document
        or self.active_document.file_type ~= "text"
    return select_cursor and "select" or "type"
end

function EditorCodeEditor:update(dt)
    self.input.visible = self.active_document ~= nil and self.active_document.file_type == "text"
    self.image_preview.visible = self.active_document ~= nil and self.active_document.file_type == "image"
    self.input:setBounds(0, TAB_HEIGHT, self.width, math.max(0, self.height - TAB_HEIGHT - STATUS_HEIGHT))
    self.image_preview:setBounds(0, TAB_HEIGHT, self.width,
        math.max(0, self.height - TAB_HEIGHT - STATUS_HEIGHT))
    super.update(self, dt)
end

function EditorCodeEditor:drawSelf()
    Draw.setColor(0.07, 0.07, 0.08, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    self.tab_rects = {}
    local x = 0
    for _, document in ipairs(self.documents) do
        local label = document.name .. (document:isDirty() and " *" or "")
        local width = math.min(220, math.max(110, font:getWidth(label) + 42))
        Draw.setColor(document == self.active_document and { 0.13, 0.16, 0.22, 1 }
            or { 0.10, 0.10, 0.12, 1 })
        love.graphics.rectangle("fill", x, 0, width, TAB_HEIGHT)
        Draw.setColor(document == self.active_document and { 0.42, 0.58, 0.86, 1 }
            or { 0.24, 0.24, 0.28, 1 })
        love.graphics.line(x + 0.5, TAB_HEIGHT - 0.5, x + width - 0.5, TAB_HEIGHT - 0.5)
        if document.read_only then
            Draw.setColor(document == self.active_document and { 0.64, 0.64, 0.68, 1 }
                or { 0.46, 0.46, 0.50, 1 })
        else
            Draw.setColor(0.88, 0.88, 0.91, 1)
        end
        love.graphics.print(label, x + 8, math.floor((TAB_HEIGHT - font:getHeight()) / 2))
        Draw.setColor(0.58, 0.58, 0.62, 1)
        love.graphics.print("x", x + width - 16, math.floor((TAB_HEIGHT - font:getHeight()) / 2))
        table.insert(self.tab_rects, { x = x, width = width, document = document })
        x = x + width
        if x >= self.width then break end
    end
    if not self.active_document then
        Draw.setColor(0.52, 0.52, 0.57, 1)
        local text = "Open a file from Project Files to begin editing."
        love.graphics.print(text, math.floor((self.width - font:getWidth(text)) / 2),
            math.floor((self.height - font:getHeight()) / 2))
    end
    Draw.setColor(0.09, 0.09, 0.105, 1)
    love.graphics.rectangle("fill", 0, self.height - STATUS_HEIGHT, self.width, STATUS_HEIGHT)
    Draw.setColor(0.60, 0.60, 0.65, 1)
    local status = self.active_document and self.active_document.relative_path or "No file open"
    if self.active_document and self.active_document.file_type == "image" then
        status = status .. "    " .. tostring(self.active_document.width) .. "x"
            .. tostring(self.active_document.height)
    end
    if self.active_document and self.active_document.read_only then status = status .. "    Read-only" end
    if self.language_service then status = status .. "    " .. self.language_service:getStatusText() end
    love.graphics.print(status, 7, self.height - STATUS_HEIGHT + 2)
end

return EditorCodeEditor
