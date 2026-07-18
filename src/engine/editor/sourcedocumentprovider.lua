--- Built in implementation for viewing file/image documents.\
--- Can be replaced by things like the Code Editor plugin's writable version.
---@class EditorSourceDocumentProvider : EditorDocumentProvider
---@field viewer EditorSourceViewer
---@overload fun(editor: Editor, viewer: EditorSourceViewer): EditorSourceDocumentProvider
local EditorSourceDocumentProvider, super = Class(EditorDocumentProvider)

function EditorSourceDocumentProvider:init(editor, viewer)
    super.init(self, editor, { priority = -100 })
    self.viewer = viewer
end

function EditorSourceDocumentProvider:supports(document)
    return document.file_type == "text" or document.file_type == "image"
end

function EditorSourceDocumentProvider:open(document, options)
    self.viewer:openDocument(document, options)
    return self.editor:showDocumentProviderPanel(
        self.editor.source_viewer_panel,
        self.viewer,
        document.file_type == "text" and self.viewer.input or self.viewer
    )
end

function EditorSourceDocumentProvider:close(document)
    return self.viewer:closeDocument(document)
end

function EditorSourceDocumentProvider:isFocused()
    return self.viewer:isFocused()
end

function EditorSourceDocumentProvider:canSave()
    return false
end

function EditorSourceDocumentProvider:saveActive()
    if self.editor.message_bar then
        self.editor.message_bar:setStatus("The built-in source viewer is read-only", 4)
    end
    return false
end

function EditorSourceDocumentProvider:undo()
    return false
end

function EditorSourceDocumentProvider:redo()
    return false
end

function EditorSourceDocumentProvider:canUndo()
    return false
end

function EditorSourceDocumentProvider:canRedo()
    return false
end

function EditorSourceDocumentProvider:getUndoLabel()
    return false
end

function EditorSourceDocumentProvider:getRedoLabel()
    return false
end

function EditorSourceDocumentProvider:captureSession()
    return self.viewer:captureSession()
end

function EditorSourceDocumentProvider:restoreSession(state)
    self.viewer:restoreSession(state)
end

return EditorSourceDocumentProvider
