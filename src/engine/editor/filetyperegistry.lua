---@class EditorFileTypeRegistry : Class
---@overload fun(): EditorFileTypeRegistry
local EditorFileTypeRegistry = Class()

local function normalizeName(path)
    local name = tostring(path or ""):gsub("\\", "/"):match("([^/]+)$") or ""
    return name:lower()
end

function EditorFileTypeRegistry:init()
    self.types = {}
    self.extensions = {}
    self.names = {}
    self:register("text", {
        label = "Text",
        extensions = {
            "lua", "json", "txt", "md", "markdown", "xml", "tmx", "tsx",
            "glsl", "frag", "vert", "shader", "csv", "tsv", "yaml", "yml",
            "toml", "ini", "cfg", "conf", "properties"
        },
        names = { ".gitignore", ".gitattributes", "license", "readme" }
    })
    self:register("image", {
        label = "Image",
        extensions = { "png", "jpg", "jpeg", "bmp", "tga", "webp", "dds", "ktx" }
    })
end

function EditorFileTypeRegistry:register(id, definition)
    assert(type(id) == "string" and id ~= "", "File type id must be a non-empty string")
    definition = TableUtils.copy(definition or {})
    definition.id = id
    self.types[id] = definition
    for _, extension in ipairs(definition.extensions or {}) do
        self.extensions[tostring(extension):lower():gsub("^%.", "")] = definition
    end
    for _, name in ipairs(definition.names or {}) do
        self.names[tostring(name):lower()] = definition
    end
    return definition
end

function EditorFileTypeRegistry:get(path)
    local name = normalizeName(path)
    local extension = name:match("%.([^%.]+)$")
    return self.names[name] or (extension and self.extensions[extension]) or nil
end

function EditorFileTypeRegistry:getSupportedDescription()
    local extensions = {}
    for extension in pairs(self.extensions) do table.insert(extensions, "." .. extension) end
    table.sort(extensions)
    return table.concat(extensions, ", ")
end

return EditorFileTypeRegistry
