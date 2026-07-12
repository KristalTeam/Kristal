---@class EditorToolRegistry : Class
---@overload fun(): EditorToolRegistry
local EditorToolRegistry = Class()

function EditorToolRegistry:init()
    self.tools = {}
    self.order = {}
end

function EditorToolRegistry:register(id, definition)
    assert(type(id) == "string" and id ~= "", "Editor tools require an id")
    definition = TableUtils.copy(definition or {}, true)
    definition.id = id
    definition.name = definition.name or StringUtils.titleCase(id:gsub("_", " "))
    if not self.tools[id] then table.insert(self.order, id) end
    self.tools[id] = definition
    return definition
end

function EditorToolRegistry:get(id)
    return self.tools[id]
end

function EditorToolRegistry:getAll()
    local result = {}
    for _, id in ipairs(self.order) do table.insert(result, self.tools[id]) end
    return result
end

return EditorToolRegistry
