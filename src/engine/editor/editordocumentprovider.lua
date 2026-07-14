---@class EditorDocumentProvider : Class
---@overload fun(editor: Editor, options?: table): EditorDocumentProvider
local EditorDocumentProvider = Class()

function EditorDocumentProvider:init(editor, options)
    options = options or {}
    self.editor = editor
    self.id = nil
    self.priority = tonumber(options.priority) or 0
end

function EditorDocumentProvider:supportsPath(path, file_type, options)
    return false
end

function EditorDocumentProvider:createDocument(workspace, path, contents, file_type, options)
    return nil
end

function EditorDocumentProvider:supports(document)
    return false
end

function EditorDocumentProvider:open(document, options)
    error((ClassUtils.getClassName(self) or "EditorDocumentProvider") .. ":open() must be overridden", 2)
end

function EditorDocumentProvider:close(document)
    return false
end

function EditorDocumentProvider:isFocused()
    return false
end

function EditorDocumentProvider:saveActive()
    return nil
end

function EditorDocumentProvider:canSave()
    return nil
end

function EditorDocumentProvider:saveAll()
    return nil
end

function EditorDocumentProvider:undo()
    return nil
end

function EditorDocumentProvider:redo()
    return nil
end

function EditorDocumentProvider:canUndo()
    return nil
end

function EditorDocumentProvider:canRedo()
    return nil
end

function EditorDocumentProvider:getUndoLabel()
    return nil
end

function EditorDocumentProvider:getRedoLabel()
    return nil
end

function EditorDocumentProvider:hasUnsavedChanges()
    return false
end

function EditorDocumentProvider:captureSession()
    return nil
end

function EditorDocumentProvider:restoreSession(state)
end

function EditorDocumentProvider:onDocumentOpened(document)
end

function EditorDocumentProvider:onDocumentChanged(document, options)
end

function EditorDocumentProvider:onDocumentSaved(document)
end

function EditorDocumentProvider:onDocumentClosed(document)
end

function EditorDocumentProvider:onDocumentRefreshed(document)
end

function EditorDocumentProvider:update()
end

function EditorDocumentProvider:shutdown()
end

return EditorDocumentProvider
