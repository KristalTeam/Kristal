---@class EditorFileDocument : EditorDocument
---@field buffer EditorCodeBuffer?
---@field diagnostics table
---@field file_type string
---@field language_id string?
---@field name string?
---@field path string?
---@field persistent boolean
---@field read_only boolean
---@field real_path string
---@field relative_path string
---@field view_states table
---@field workspace EditorProjectWorkspace
---@overload fun(workspace: EditorProjectWorkspace, path: string, contents: string, options?: table): EditorFileDocument
local EditorFileDocument, super = Class(EditorDocument)

function EditorFileDocument:init(workspace, path, contents, options)
    options = options or {}
    super.init(self, workspace.editor)
    self.workspace = workspace
    self.path = path
    self.real_path = options.real_path or assert(ProjectFileSystem.getRealPath(path))
    self.relative_path = options.relative_path or path:sub(#workspace.virtual_root + 2)
    self.name = self.relative_path:match("([^/]+)$") or self.relative_path
    self.language_id = self.name:lower():match("%.lua$") and "lua" or "plaintext"
    self.file_type = "text"
    self.read_only = true
    self.persistent = options.persistent ~= false
    self.buffer = EditorCodeBuffer(contents or "")
    self.diagnostics = {}
    self.view_states = {}
end

function EditorFileDocument:getText()
    return self.buffer:getText()
end

function EditorFileDocument:isDirty()
    return false
end

function EditorFileDocument:save()
    return false, "The built-in source viewer is read-only"
end

function EditorFileDocument:setDiagnostics(diagnostics)
    self.diagnostics = diagnostics or {}
    self.workspace:refreshDocument(self)
end

return EditorFileDocument
