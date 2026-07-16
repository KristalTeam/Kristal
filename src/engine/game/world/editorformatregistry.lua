---@class EditorFormatRegistry : Class
---@overload fun(): EditorFormatRegistry
local EditorFormatRegistry = Class()

function EditorFormatRegistry:init()
    self.extensions = { map = {}, tileset = {}, world = {} }
    self.extension_order = { map = {}, tileset = {}, world = {} }
end

function EditorFormatRegistry:registerExtension(scope, id, definition)
    assert(self.extensions[scope], "Unknown editor format extension scope: " .. tostring(scope))
    assert(type(id) == "string" and id ~= "", "Editor format extensions require an id")
    assert(type(definition) == "table", "Editor format extensions require a definition")
    assert(definition.encode == nil or type(definition.encode) == "function",
        "Tileset format extension encode must be a function")
    assert(definition.decode == nil or type(definition.decode) == "function",
        "Tileset format extension decode must be a function")
    assert((definition.encode == nil) == (definition.decode == nil),
        "Tileset format extensions must define both encode and decode, or neither")
    assert(definition.validate == nil or type(definition.validate) == "function",
        "Tileset format extension validate must be a function")
    assert(definition.format == nil or type(definition.format) == "table",
        "Tileset format extension format must be an ordered field list")

    local entry = TableUtils.copy(definition, true)
    entry.id = id
    entry.scope = scope
    local previous = self.extensions[scope][id]
    if previous then TableUtils.removeValue(self.extension_order[scope], previous) end
    self.extensions[scope][id] = entry
    table.insert(self.extension_order[scope], entry)
    return entry
end

function EditorFormatRegistry:unregisterExtension(scope, id, expected)
    if not self.extensions[scope] then return false end
    local definition = self.extensions[scope][id]
    if not definition or expected and definition ~= expected then return false end
    self.extensions[scope][id] = nil
    TableUtils.removeValue(self.extension_order[scope], definition)
    return true
end

function EditorFormatRegistry:getExtension(scope, id)
    return self.extensions[scope] and self.extensions[scope][id]
end

function EditorFormatRegistry:getExtensions(scope)
    return TableUtils.copy(self.extension_order[scope] or {})
end

function EditorFormatRegistry:registerMapExtension(id, definition)
    return self:registerExtension("map", id, definition)
end

function EditorFormatRegistry:getMapExtension(id)
    return self:getExtension("map", id)
end

function EditorFormatRegistry:getMapExtensions()
    return self:getExtensions("map")
end

function EditorFormatRegistry:registerTilesetExtension(id, definition)
    return self:registerExtension("tileset", id, definition)
end

function EditorFormatRegistry:getTilesetExtension(id)
    return self:getExtension("tileset", id)
end

function EditorFormatRegistry:getTilesetExtensions()
    return self:getExtensions("tileset")
end

function EditorFormatRegistry:registerWorldExtension(id, definition)
    return self:registerExtension("world", id, definition)
end

function EditorFormatRegistry:getWorldExtension(id)
    return self:getExtension("world", id)
end

function EditorFormatRegistry:getWorldExtensions()
    return self:getExtensions("world")
end

return EditorFormatRegistry
