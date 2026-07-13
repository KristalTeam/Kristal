---@class EditorDocumentProviders : Class
---@overload fun(editor: Editor): EditorDocumentProviders
local EditorDocumentProviders = Class()

function EditorDocumentProviders:init(editor)
    self.editor = editor
    self.providers = {}
    self.order = {}
end

function EditorDocumentProviders:register(id, definition)
    assert(type(id) == "string" and id ~= "", "Document providers require an id")
    assert(type(definition) == "table", "Document providers require a definition")
    assert(type(definition.supports) == "function", "Document providers require a supports callback")
    assert(type(definition.open) == "function", "Document providers require an open callback")
    definition.id = id
    definition.priority = tonumber(definition.priority) or 0
    if not self.providers[id] then table.insert(self.order, id) end
    self.providers[id] = definition
    table.sort(self.order, function(first, second)
        local a, b = self.providers[first], self.providers[second]
        if a.priority ~= b.priority then return a.priority > b.priority end
        return first < second
    end)
    return definition
end

function EditorDocumentProviders:unregister(id)
    local provider = self.providers[id]
    if not provider then return false end
    if provider.shutdown then provider.shutdown() end
    self.providers[id] = nil
    TableUtils.removeValue(self.order, id)
    return true
end

function EditorDocumentProviders:get(id)
    return self.providers[id]
end

function EditorDocumentProviders:getAll()
    local result = {}
    for _, id in ipairs(self.order) do
        local provider = self.providers[id]
        if provider then table.insert(result, provider) end
    end
    return result
end

function EditorDocumentProviders:createDocument(workspace, path, contents, file_type, options)
    for _, provider in ipairs(self:getAll()) do
        if provider.create_document and provider.supports_path
            and provider.supports_path(path, file_type, options or {}) then
            local document = provider.create_document(workspace, path, contents, file_type, options or {})
            if document then
                document.document_provider_id = provider.id
                return document
            end
        end
    end
end

function EditorDocumentProviders:getForDocument(document)
    if document.document_provider_id and self.providers[document.document_provider_id]
        and self.providers[document.document_provider_id].supports(document) then
        return self.providers[document.document_provider_id]
    end
    for _, provider in ipairs(self:getAll()) do
        if provider.supports(document) then return provider end
    end
end

function EditorDocumentProviders:open(document, options)
    local provider = self:getForDocument(document)
    if not provider then return false, "No document viewer supports " .. tostring(document.name) end
    local opened, reason = provider.open(document, options or {})
    if opened ~= false then document.open_provider_id = provider.id end
    return opened, reason, provider
end

function EditorDocumentProviders:close(document)
    local provider = document and document.open_provider_id and self.providers[document.open_provider_id]
    if provider and provider.close then return provider.close(document) end
    return false
end

function EditorDocumentProviders:getFocused()
    for _, provider in ipairs(self:getAll()) do
        if provider.is_focused and provider.is_focused() then return provider end
    end
end

function EditorDocumentProviders:invokeFocused(method, ...)
    local provider = self:getFocused()
    if provider and provider[method] then return provider[method](...) end
end

function EditorDocumentProviders:broadcast(method, ...)
    for _, provider in ipairs(self:getAll()) do
        if provider[method] then provider[method](...) end
    end
end

function EditorDocumentProviders:any(method)
    for _, provider in ipairs(self:getAll()) do
        if provider[method] and provider[method]() then return true end
    end
    return false
end

function EditorDocumentProviders:captureSession()
    local result = {}
    for _, provider in ipairs(self:getAll()) do
        if provider.capture_session then result[provider.id] = provider.capture_session() end
    end
    return result
end

function EditorDocumentProviders:restoreSession(session)
    for _, provider in ipairs(self:getAll()) do
        if provider.restore_session then provider.restore_session((session or {})[provider.id]) end
    end
end

function EditorDocumentProviders:shutdown()
    for _, provider in ipairs(self:getAll()) do
        if provider.shutdown then provider.shutdown() end
    end
    self.providers, self.order = {}, {}
end

return EditorDocumentProviders
