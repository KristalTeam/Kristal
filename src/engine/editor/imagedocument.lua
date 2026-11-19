--- Represents an image opened from the project workspace.
---@class EditorImageDocument : EditorDocument
---@field diagnostics table
---@field file_type string
---@field height number
---@field image love.Image
---@field language_id string?
---@field name string?
---@field path string?
---@field persistent boolean
---@field read_only boolean
---@field real_path string
---@field relative_path string
---@field width number
---@field workspace EditorProjectWorkspace
---@overload fun(workspace: EditorProjectWorkspace, path: string, image: love.Image): EditorImageDocument
local EditorImageDocument, super = Class(EditorDocument)

function EditorImageDocument:init(workspace, path, image)
    super.init(self, workspace.editor)
    self.workspace = workspace
    self.path = path
    self.real_path = assert(ProjectFileSystem.getRealPath(path))
    self.relative_path = path:sub(#workspace.virtual_root + 2)
    self.name = self.relative_path:match("([^/]+)$") or self.relative_path
    self.file_type = "image"
    self.language_id = nil
    self.read_only = true
    self.persistent = true
    self.image = image
    self.width = image:getWidth()
    self.height = image:getHeight()
    self.diagnostics = {}
end

function EditorImageDocument:isDirty()
    return false
end

function EditorImageDocument:save()
    return false, "Image previews are read-only"
end

function EditorImageDocument:release()
    if self.image and self.image.release then self.image:release() end
    self.image = nil
end

return EditorImageDocument
