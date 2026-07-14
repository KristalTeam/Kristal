---@class CodeEditorDocumentProvider : EditorDocumentProvider
local CodeEditorDocumentProvider, super = Class(EditorDocumentProvider)

function CodeEditorDocumentProvider:init(plugin, editor, panel, document_class)
    super.init(self, editor, { priority = 100 })
    self.plugin = plugin
    self.panel = panel
    self.document_class = document_class
end

function CodeEditorDocumentProvider:supportsPath(path, file_type, options)
    return file_type and file_type.id == "text" and options.read_only ~= true
end

function CodeEditorDocumentProvider:createDocument(workspace, path, contents, file_type, options)
    return self.document_class(workspace, path, contents, options)
end

function CodeEditorDocumentProvider:supports(document)
    return document.writable_code_document == true
end

function CodeEditorDocumentProvider:open(document, options)
    self.plugin.code_editor:openDocument(document, options)
    return self.editor:showDocumentProviderPanel(
        self.panel.panel, self.plugin.code_editor, self.plugin.code_editor.input)
end

function CodeEditorDocumentProvider:close(document)
    return self.plugin.code_editor:closeDocument(document)
end

function CodeEditorDocumentProvider:isFocused()
    local focused = self.editor.dockspace and self.editor.dockspace.focused_control
    while focused do
        if focused == self.plugin.code_editor then return true end
        focused = focused.parent
    end
    return false
end

function CodeEditorDocumentProvider:saveActive()
    return self.plugin.code_editor:saveActiveDocument()
end

function CodeEditorDocumentProvider:canSave()
    return self.plugin.code_editor.active_document ~= nil
end

function CodeEditorDocumentProvider:saveAll()
    for _, document in ipairs(self.plugin.code_editor.documents) do
        if document:isDirty() then
            local saved, reason = document:save()
            if not saved then
                self.editor:addError("Could not save " .. document.relative_path, reason, "filesystem")
                return false
            end
        end
    end
    return true
end

function CodeEditorDocumentProvider:undo()
    return self.plugin.code_editor:undo()
end

function CodeEditorDocumentProvider:redo()
    return self.plugin.code_editor:redo()
end

function CodeEditorDocumentProvider:canUndo()
    local document = self.plugin.code_editor.active_document
    return document ~= nil and #document.undo_stack > 0
end

function CodeEditorDocumentProvider:canRedo()
    local document = self.plugin.code_editor.active_document
    return document ~= nil and #document.redo_stack > 0
end

function CodeEditorDocumentProvider:getUndoLabel()
    local document = self.plugin.code_editor.active_document
    return document and #document.undo_stack > 0 and ("Edit " .. document.name) or nil
end

function CodeEditorDocumentProvider:getRedoLabel()
    local document = self.plugin.code_editor.active_document
    return document and #document.redo_stack > 0 and ("Edit " .. document.name) or nil
end

function CodeEditorDocumentProvider:hasUnsavedChanges()
    for _, document in ipairs(self.plugin.code_editor.documents) do
        if document:isDirty() then return true end
    end
    return false
end

function CodeEditorDocumentProvider:captureSession()
    local paths = {}
    for _, document in ipairs(self.plugin.code_editor.documents) do
        if document.persistent then table.insert(paths, document.relative_path) end
    end
    local active = self.plugin.code_editor.active_document
    return {
        paths = paths,
        active = active and active.persistent and active.relative_path or nil
    }
end

function CodeEditorDocumentProvider:restoreSession(state)
    if type(state) ~= "table" then return end
    local restored = {}
    for _, path in ipairs(state.paths or {}) do
        local document = self.editor.project_workspace:openDocument(path)
        if document and document.document_provider_id == self.id then
            self.plugin.code_editor:openDocument(document, { focus = false })
            restored[path] = document
        end
    end
    if state.active and restored[state.active] then
        self.plugin.code_editor:setActiveDocument(restored[state.active], false)
    end
end

function CodeEditorDocumentProvider:onDocumentOpened(document)
    self.plugin.language_service:openDocument(document)
end

function CodeEditorDocumentProvider:onDocumentChanged(document, options)
    self.plugin.language_service:changeDocument(document, options and options.change)
end

function CodeEditorDocumentProvider:onDocumentSaved(document)
    self.plugin.language_service:saveDocument(document)
end

function CodeEditorDocumentProvider:onDocumentClosed(document)
    self.plugin.language_service:closeDocument(document)
end

function CodeEditorDocumentProvider:onDocumentRefreshed(document)
    self.plugin.code_editor:refreshDocument(document)
end

function CodeEditorDocumentProvider:update()
    self.plugin.language_service:update()
end

function CodeEditorDocumentProvider:shutdown()
    self.plugin.language_service:shutdown(true)
end

return CodeEditorDocumentProvider
