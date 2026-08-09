--- Registers supported project file types and their icons.
---@class EditorFileTypeRegistry : Class
---@field extensions table
---@field names table
---@field type_order table
---@field types table
---@overload fun(): EditorFileTypeRegistry
local EditorFileTypeRegistry = Class()

local function normalizeName(path)
    local name = tostring(path or ""):gsub("\\", "/"):match("([^/]+)$") or ""
    return name:lower()
end

function EditorFileTypeRegistry:init()
    self.types = {}
    self.type_order = {}
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
    if self.types[id] then self:unregister(id, self.types[id]) end
    definition = TableUtils.copy(definition or {})
    definition.id = id
    if not self.types[id] then table.insert(self.type_order, id) end
    self.types[id] = definition
    for _, extension in ipairs(definition.extensions or {}) do
        self.extensions[tostring(extension):lower():gsub("^%.", "")] = definition
    end
    for _, name in ipairs(definition.names or {}) do
        self.names[tostring(name):lower()] = definition
    end
    return definition
end

function EditorFileTypeRegistry:unregister(id, definition)
    local registered = self.types[id]
    if not registered or definition and registered ~= definition then return false end
    self.types[id] = nil
    TableUtils.removeValue(self.type_order, id)
    self.extensions = {}
    self.names = {}
    for _, remaining_id in ipairs(self.type_order) do
        local remaining = self.types[remaining_id]
        for _, extension in ipairs(remaining.extensions or {}) do
            self.extensions[tostring(extension):lower():gsub("^%.", "")] = remaining
        end
        for _, name in ipairs(remaining.names or {}) do
            self.names[tostring(name):lower()] = remaining
        end
    end
    return true
end

function EditorFileTypeRegistry:get(path)
    local name = normalizeName(path)
    local extension = name:match("%.([^%.]+)$")
    for index = #self.type_order, 1, -1 do
        local definition = self.types[self.type_order[index]]
        if definition and definition.matches then
            local matched, result = pcall(definition.matches, path, name)
            if matched and result then return definition end
        end
    end
    return self.names[name] or (extension and self.extensions[extension]) or nil
end

function EditorFileTypeRegistry:getSupportedDescription()
    local extensions = {}
    for extension in pairs(self.extensions) do table.insert(extensions, "." .. extension) end
    table.sort(extensions)
    return table.concat(extensions, ", ")
end

return EditorFileTypeRegistry
