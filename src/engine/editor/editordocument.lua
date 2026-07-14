---@class EditorDocument : Class
---@overload fun(editor?: Editor): EditorDocument
local EditorDocument = Class()

function EditorDocument:init(editor)
    self.editor = editor
    self.document_provider_id = nil
    self.open_provider_id = nil
    self.history_revision = 0
    self.saved_history_revision = 0
end

function EditorDocument:getName()
    return self.name or self.id or "Untitled"
end

function EditorDocument:isDirty()
    return (self.history_revision or 0) ~= (self.saved_history_revision or 0)
end

function EditorDocument:save()
    return false, "This document cannot be saved"
end

function EditorDocument:release()
end

return EditorDocument
