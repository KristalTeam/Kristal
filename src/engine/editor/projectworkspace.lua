---@class EditorProjectWorkspace : Class
---@overload fun(editor: Editor, file_types: EditorFileTypeRegistry): EditorProjectWorkspace
local EditorProjectWorkspace = Class()

local function join(path, name)
    return path == "" and name or (path .. "/" .. name)
end

local function normalizeRealPath(path)
    path = tostring(path or ""):gsub("\\", "/"):gsub("/+$", "")
    return love.system.getOS() == "Windows" and path:lower() or path
end

local function isWithin(path, root)
    path, root = normalizeRealPath(path), normalizeRealPath(root)
    return path == root or StringUtils.startsWith(path, root .. "/")
end

function EditorProjectWorkspace:init(editor, file_types)
    self.editor = editor
    self.file_types = file_types
    self.virtual_root = assert(Mod and Mod.info and Mod.info.path, "A project must be loaded before its workspace")
    self.virtual_root = self.virtual_root:gsub("\\", "/"):gsub("/+$", "")
    self.real_root = assert(ProjectFileSystem.getRealProjectRoot())
    self.documents = {}
    self.document_order = {}
end

function EditorProjectWorkspace:getRelativePath(path)
    if path == self.virtual_root then return "" end
    if not StringUtils.startsWith(path, self.virtual_root .. "/") then return nil end
    return path:sub(#self.virtual_root + 2)
end

function EditorProjectWorkspace:getVirtualPath(relative_path)
    relative_path = tostring(relative_path or ""):gsub("\\", "/"):gsub("^/+", "")
    return relative_path == "" and self.virtual_root or (self.virtual_root .. "/" .. relative_path)
end

function EditorProjectWorkspace:scan(path)
    path = path or self.virtual_root
    local info = love.filesystem.getInfo(path)
    if not info then return nil, "Project path does not exist: " .. path end
    local node = {
        name = path == self.virtual_root and (Mod.info.name or Mod.info.id) or (path:match("([^/]+)$") or path),
        path = path,
        relative_path = self:getRelativePath(path),
        type = info.type,
        children = info.type == "directory" and {} or nil
    }
    if node.children then
        local items, reason = ProjectFileSystem.getDirectoryItems(path)
        if not items then return nil, reason end
        for _, name in ipairs(items) do
            if name ~= ".git" and name ~= ".kristal-tmp" and name ~= ".kristal-backup" then
                local child = self:scan(join(path, name))
                if child then table.insert(node.children, child) end
            end
        end
        table.sort(node.children, function(a, b)
            if a.type ~= b.type then return a.type == "directory" end
            return a.name:lower() < b.name:lower()
        end)
    end
    return node
end

function EditorProjectWorkspace:openDocument(path)
    path = self:getVirtualPath(self:getRelativePath(path) or path)
    if self.documents[path] then return self.documents[path] end
    local info = love.filesystem.getInfo(path)
    if not info or info.type ~= "file" then return nil, "Not a project file: " .. path end
    local file_type = self.file_types and self.file_types:get(path)
    if not file_type then
        local name = path:match("([^/]+)$") or path
        return nil, "No editor is registered for '" .. name .. "'", "unsupported"
    end
    local contents, reason = ProjectFileSystem.readFile(path)
    if not contents then return nil, reason end
    local document
    if file_type.id == "text" then
        if contents:find("\0", 1, true) or not utf8.len(contents) then
            return nil, "The file is not valid UTF-8 text", "unsupported"
        end
        document = self.editor.document_providers:createDocument(self, path, contents, file_type, {
            read_only = false,
            persistent = true
        }) or EditorFileDocument(self, path, contents)
    elseif file_type.id == "image" then
        local loaded, image = pcall(function()
            local file_data = love.filesystem.newFileData(contents, path:match("([^/]+)$") or "image")
            return love.graphics.newImage(file_data)
        end)
        if not loaded then return nil, "Could not decode image: " .. tostring(image), "unsupported" end
        image:setFilter("nearest", "nearest")
        document = EditorImageDocument(self, path, image)
    else
        return nil, "File type '" .. file_type.id .. "' has no document handler", "unsupported"
    end
    self.documents[path] = document
    table.insert(self.document_order, document)
    self.editor.document_providers:broadcast("onDocumentOpened", document)
    return document
end

function EditorProjectWorkspace:findDocumentByRealPath(real_path)
    local normalized = normalizeRealPath(real_path)
    for _, document in ipairs(self.document_order) do
        if normalizeRealPath(document.real_path) == normalized then return document end
    end
end

function EditorProjectWorkspace:getEngineRoot()
    local root = love.filesystem.getRealDirectory("src/kristal.lua")
        or love.filesystem.getRealDirectory("main.lua")
    return root and root:gsub("\\", "/"):gsub("/+$", "") or nil
end

function EditorProjectWorkspace:isEngineMainPath(real_path)
    local engine_root = self:getEngineRoot()
    return engine_root ~= nil
        and normalizeRealPath(real_path) == normalizeRealPath(engine_root .. "/main.lua")
end

function EditorProjectWorkspace:resolveEngineMainDefinition(real_path, range)
    if type(range) ~= "table" or not range.start then return nil end
    real_path = tostring(real_path or ""):gsub("\\", "/")
    if not real_path:lower():match("/main%.lua$") then return nil end
    local source_root = real_path:match("^(.*)/[^/]+$")
    local file = source_root and io.open(real_path, "rb") or nil
    if not file then return nil end
    local lines = {}
    for line in file:lines() do table.insert(lines, line) end
    file:close()

    local line = lines[(range.start.line or 0) + 1] or ""
    local global_name, module = line:match(
        "^%s*([%a_][%w_]*)%s*=%s*require%s*%(%s*['\"]([^'\"]+)['\"]%s*%)")
    if not module then return nil end
    local target_path = source_root .. "/" .. module:gsub("%.", "/") .. ".lua"
    local target = io.open(target_path, "rb")
    if not target then return nil end
    local target_line = 0
    local returned_function_line
    local found_declaration = false
    local escaped_name = global_name:gsub("([^%w])", "%%%1")
    local index = 0
    for candidate in target:lines() do
        if candidate:match("^%s*local%s+" .. escaped_name .. "[%s,=]")
            or candidate:match("^%s*function%s+" .. escaped_name .. "[%s%.:%(]") then
            target_line = index
            found_declaration = true
            break
        end
        if returned_function_line == nil and candidate:match("^%s*return%s+function[%s%(]") then
            returned_function_line = index
        end
        index = index + 1
    end
    target:close()
    if not found_declaration and returned_function_line then target_line = returned_function_line end
    return target_path, {
        start = { line = target_line, character = 0 },
        ["end"] = { line = target_line, character = 0 }
    }
end

function EditorProjectWorkspace:getDisplayPath(real_path)
    real_path = tostring(real_path or ""):gsub("\\", "/")
    if isWithin(real_path, self.real_root) then
        return real_path:sub(#self.real_root + 2)
    end
    local engine_root = self:getEngineRoot()
    if engine_root and isWithin(real_path, engine_root) then
        return "Kristal/" .. real_path:sub(#engine_root + 2)
    end
    return real_path
end

function EditorProjectWorkspace:openDocumentByRealPath(real_path)
    real_path = tostring(real_path or ""):gsub("\\", "/")
    local existing = self:findDocumentByRealPath(real_path)
    if existing then return existing end
    if isWithin(real_path, self.real_root) then
        local relative_path = real_path:sub(#self.real_root + 2)
        return self:openDocument(relative_path)
    end

    local file_type = self.file_types and self.file_types:get(real_path)
    if not file_type or file_type.id ~= "text" then
        return nil, "The language server target is not a supported text file"
    end
    local file, reason = io.open(real_path, "rb")
    if not file then return nil, reason or "Could not read language server target" end
    local contents = file:read("*a")
    file:close()
    if contents:find("\0", 1, true) or not utf8.len(contents) then
        return nil, "The language server target is not valid UTF-8 text"
    end
    local relative_path = self:getDisplayPath(real_path)
    local path = "@external/" .. normalizeRealPath(real_path)
    local document = EditorFileDocument(self, path, contents, {
        real_path = real_path,
        relative_path = relative_path,
        read_only = true,
        persistent = false
    })
    self.documents[path] = document
    table.insert(self.document_order, document)
    self.editor.document_providers:broadcast("onDocumentOpened", document)
    return document
end

function EditorProjectWorkspace:closeDocument(document)
    if not document or self.documents[document.path] ~= document then return false end
    if document:isDirty() then return false, "The file has unsaved changes" end
    self.editor.document_providers:broadcast("onDocumentClosed", document)
    self.documents[document.path] = nil
    TableUtils.removeValue(self.document_order, document)
    if document.release then document:release() end
    return true
end

function EditorProjectWorkspace:onDocumentChanged(document, options)
    self:refreshDocument(document)
    self.editor.document_providers:broadcast("onDocumentChanged", document, options or {})
end

function EditorProjectWorkspace:onDocumentSaved(document)
    self:refreshDocument(document)
    self.editor.document_providers:broadcast("onDocumentSaved", document)
    if self.editor.message_bar then self.editor.message_bar:setStatus("Saved " .. document.relative_path) end
end

function EditorProjectWorkspace:refreshDocument(document)
    self.editor.document_providers:broadcast("onDocumentRefreshed", document)
end

function EditorProjectWorkspace:rename(path, destination)
    if normalizeRealPath(path) == normalizeRealPath(self.virtual_root) then
        return false, "The project root cannot be renamed or moved"
    end
    local open_document = self.documents[path]
    if open_document then
        local destination_type = self.file_types and self.file_types:get(destination)
        if not destination_type or destination_type.id ~= open_document.file_type then
            return false, "Close the file before changing its registered file type"
        end
    end
    local moved, reason = ProjectFileSystem.rename(path, destination)
    if not moved then return false, reason end
    local affected = {}
    for document_path, document in pairs(self.documents) do
        if document_path == path or StringUtils.startsWith(document_path, path .. "/") then
            table.insert(affected, { path = document_path, document = document })
        end
    end
    for _, entry in ipairs(affected) do
        local document = entry.document
        self.editor.document_providers:broadcast("onDocumentClosed", document)
        self.documents[entry.path] = nil
        document.path = destination .. entry.path:sub(#path + 1)
        document.real_path = assert(ProjectFileSystem.getRealPath(document.path))
        document.relative_path = assert(self:getRelativePath(document.path))
        document.name = document.relative_path:match("([^/]+)$") or document.relative_path
        document.language_id = document.name:lower():match("%.lua$") and "lua" or "plaintext"
        self.documents[document.path] = document
        self.editor.document_providers:broadcast("onDocumentOpened", document)
    end
    return true
end

function EditorProjectWorkspace:remove(path)
    local affected = {}
    for document_path, document in pairs(self.documents) do
        if document_path == path or StringUtils.startsWith(document_path, path .. "/") then
            if document:isDirty() then return false, "Save or close dirty files before deleting this path" end
            table.insert(affected, document)
        end
    end
    local removed, reason = ProjectFileSystem.remove(path)
    if not removed then return false, reason end
    for _, document in ipairs(affected) do self.editor.document_providers:close(document) end
    return true
end

function EditorProjectWorkspace:shutdown()
    for _, document in ipairs(self.document_order) do
        self.editor.document_providers:broadcast("onDocumentClosed", document)
    end
    for _, document in ipairs(self.document_order) do
        if document.release then document:release() end
    end
end

return EditorProjectWorkspace
