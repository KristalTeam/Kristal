---@class EditorSourceViewer : EditorControl
---@field active_document EditorFileDocument|EditorImageDocument|nil
---@field clip boolean
---@field documents table
---@field editor Editor
---@field image_preview EditorImagePreview
---@field input EditorSourceInput
---@field tab_rects table
---@field workspace EditorProjectWorkspace
---@overload fun(editor: Editor, workspace: EditorProjectWorkspace): EditorSourceViewer
local EditorSourceViewer, super = Class(EditorControl)

local TAB_HEIGHT = 30
local STATUS_HEIGHT = 22

function EditorSourceViewer:init(editor, workspace)
    super.init(self, 0, 0, 760, 520)
    self.editor = editor
    self.workspace = workspace
    self.documents = {}
    self.active_document = nil
    self.tab_rects = {}
    self.clip = true
    self.input = self:addChild(EditorSourceInput())
    self.image_preview = self:addChild(EditorImagePreview())
end

function EditorSourceViewer:openDocument(document, options)
    if not TableUtils.contains(self.documents, document) then table.insert(self.documents, document) end
    self:setActiveDocument(document)
    options = options or {}
    if document.file_type == "text" and options.line then
        self.input:setProtocolCursor(options.line, options.character or 0, options.encoding)
    end
    return true
end

function EditorSourceViewer:setActiveDocument(document)
    if not document then return false end
    self.active_document = document
    if document.file_type == "image" then
        self.input:setDocument(nil)
        self.image_preview:setDocument(document)
    else
        self.image_preview:setDocument(nil)
        self.input:setDocument(document)
    end
    if self.editor.source_viewer_panel then self.editor.source_viewer_panel.title = "Source Viewer" end
    return true
end

function EditorSourceViewer:closeDocument(document)
    document = document or self.active_document
    local index = document and TableUtils.getIndex(self.documents, document)
    if not index then return false end
    table.remove(self.documents, index)
    self.workspace:closeDocument(document)
    if self.active_document == document then
        self.active_document = nil
        local next_document = self.documents[math.min(index, #self.documents)]
        if next_document then self:setActiveDocument(next_document)
        else self.input:setDocument(nil) self.image_preview:setDocument(nil) end
    end
    return true
end

function EditorSourceViewer:isFocused()
    local focused = self.editor.dockspace and self.editor.dockspace.focused_control
    while focused do
        if focused == self or focused == self.input or focused == self.image_preview then return true end
        focused = focused.parent
    end
    return false
end

function EditorSourceViewer:captureSession()
    local open = {}
    for _, document in ipairs(self.documents) do
        if document.persistent ~= false then table.insert(open, document.relative_path) end
    end
    return {
        open = open,
        active = self.active_document and self.active_document.persistent ~= false
            and self.active_document.relative_path or nil
    }
end

function EditorSourceViewer:restoreSession(session)
    session = session or {}
    for _, path in ipairs(session.open or {}) do
        local document = self.workspace:openDocument(path)
        if document and document.read_only then self:openDocument(document) end
    end
    if session.active then
        local document = self.workspace.documents[self.workspace:getVirtualPath(session.active)]
        if document and TableUtils.contains(self.documents, document) then self:setActiveDocument(document) end
    end
end

function EditorSourceViewer:onMousePressed(x, y, button)
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

function EditorSourceViewer:getCursorType(_, y)
    return y < TAB_HEIGHT and "select" or (self.active_document and "type" or "select")
end

function EditorSourceViewer:update(dt)
    self.input.visible = self.active_document ~= nil and self.active_document.file_type == "text"
    self.image_preview.visible = self.active_document ~= nil and self.active_document.file_type == "image"
    self.input:setBounds(0, TAB_HEIGHT, self.width, math.max(0, self.height - TAB_HEIGHT - STATUS_HEIGHT))
    self.image_preview:setBounds(0, TAB_HEIGHT, self.width,
        math.max(0, self.height - TAB_HEIGHT - STATUS_HEIGHT))
    super.update(self, dt)
end

function EditorSourceViewer:drawSelf()
    Draw.setColor(0.07, 0.07, 0.08, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    self.tab_rects = {}
    local x = 0
    for _, document in ipairs(self.documents) do
        local width = math.min(220, math.max(110, font:getWidth(document.name) + 42))
        Draw.setColor(document == self.active_document and { 0.13, 0.16, 0.22, 1 }
            or { 0.10, 0.10, 0.12, 1 })
        love.graphics.rectangle("fill", x, 0, width, TAB_HEIGHT)
        Draw.setColor(document == self.active_document and { 0.64, 0.64, 0.68, 1 }
            or { 0.46, 0.46, 0.50, 1 })
        love.graphics.print(document.name, x + 8, math.floor((TAB_HEIGHT - font:getHeight()) / 2))
        Draw.setColor(0.58, 0.58, 0.62, 1)
        love.graphics.print("x", x + width - 16, math.floor((TAB_HEIGHT - font:getHeight()) / 2))
        table.insert(self.tab_rects, { x = x, width = width, document = document })
        x = x + width
        if x >= self.width then break end
    end
    if not self.active_document then
        local text = "Open a file from Project Files to preview it."
        Draw.setColor(0.52, 0.52, 0.57, 1)
        love.graphics.print(text, math.floor((self.width - font:getWidth(text)) / 2),
            math.floor((self.height - font:getHeight()) / 2))
    end
    Draw.setColor(0.09, 0.09, 0.105, 1)
    love.graphics.rectangle("fill", 0, self.height - STATUS_HEIGHT, self.width, STATUS_HEIGHT)
    Draw.setColor(0.60, 0.60, 0.65, 1)
    local status = self.active_document and self.active_document.relative_path or "No file open"
    if self.active_document and self.active_document.file_type == "image" then
        status = status .. "    " .. self.active_document.width .. "x" .. self.active_document.height
    end
    if self.active_document then status = status .. "    Read-only" end
    love.graphics.print(status, 7, self.height - STATUS_HEIGHT + 2)
end

return EditorSourceViewer
