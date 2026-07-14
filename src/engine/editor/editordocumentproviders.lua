---@class EditorDocumentProviders : Class
---@overload fun(editor: Editor): EditorDocumentProviders
local EditorDocumentProviders = Class()

function EditorDocumentProviders:init(editor)
    self.editor = editor
    self.providers = {}
    self.order = {}
end

---@param id string
---@param provider EditorDocumentProvider
function EditorDocumentProviders:register(id, provider)
    assert(type(id) == "string" and id ~= "", "Document providers require an id")
    assert(isClass(provider) and provider:includes(EditorDocumentProvider),
        "Document providers must extend EditorDocumentProvider")
    assert(rawget(provider, "__index") ~= provider,
        "Document providers must be instances, not classes")
    assert(provider.open ~= EditorDocumentProvider.open,
        "Document providers must override open()")
    assert(provider.editor == self.editor,
        "Document providers must belong to this editor")
    local previous = self.providers[id]
    if previous and previous ~= provider then previous:shutdown() end
    provider.id = id
    provider.priority = tonumber(provider.priority) or 0
    if not self.providers[id] then table.insert(self.order, id) end
    self.providers[id] = provider
    table.sort(self.order, function(first, second)
        local a, b = self.providers[first], self.providers[second]
        if a.priority ~= b.priority then return a.priority > b.priority end
        return first < second
    end)
    return provider
end

function EditorDocumentProviders:unregister(id)
    local provider = self.providers[id]
    if not provider then return false end
    provider:shutdown()
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
        if provider:supportsPath(path, file_type, options or {}) then
            local document = provider:createDocument(workspace, path, contents, file_type, options or {})
            if document then
                assert(isClass(document) and document:includes(EditorDocument),
                    "Document providers must create EditorDocument instances")
                document.document_provider_id = provider.id
                return document
            end
        end
    end
end

function EditorDocumentProviders:getForDocument(document)
    if document.document_provider_id and self.providers[document.document_provider_id]
        and self.providers[document.document_provider_id]:supports(document) then
        return self.providers[document.document_provider_id]
    end
    for _, provider in ipairs(self:getAll()) do
        if provider:supports(document) then return provider end
    end
end

function EditorDocumentProviders:open(document, options)
    assert(isClass(document) and document:includes(EditorDocument),
        "Document providers can only open EditorDocument instances")
    local provider = self:getForDocument(document)
    if not provider then return false, "No document viewer supports " .. document:getName() end
    local opened, reason = provider:open(document, options or {})
    if opened ~= false then document.open_provider_id = provider.id end
    return opened, reason, provider
end

function EditorDocumentProviders:close(document)
    local provider = document and document.open_provider_id and self.providers[document.open_provider_id]
    if provider then return provider:close(document) end
    return false
end

function EditorDocumentProviders:getFocused()
    for _, provider in ipairs(self:getAll()) do
        if provider:isFocused() then return provider end
    end
end

function EditorDocumentProviders:invokeFocused(method, ...)
    local provider = self:getFocused()
    if provider and provider[method] then return provider[method](provider, ...) end
end

function EditorDocumentProviders:broadcast(method, ...)
    for _, provider in ipairs(self:getAll()) do
        if provider[method] then provider[method](provider, ...) end
    end
end

function EditorDocumentProviders:any(method)
    for _, provider in ipairs(self:getAll()) do
        if provider[method] and provider[method](provider) then return true end
    end
    return false
end

function EditorDocumentProviders:captureSession()
    local result = {}
    for _, provider in ipairs(self:getAll()) do
        local state = provider:captureSession()
        if state ~= nil then result[provider.id] = state end
    end
    return result
end

function EditorDocumentProviders:restoreSession(session)
    for _, provider in ipairs(self:getAll()) do
        provider:restoreSession((session or {})[provider.id])
    end
end

function EditorDocumentProviders:shutdown()
    for _, provider in ipairs(self:getAll()) do
        provider:shutdown()
    end
    self.providers, self.order = {}, {}
end

return EditorDocumentProviders
