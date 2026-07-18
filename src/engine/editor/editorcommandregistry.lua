--- Registers commands that can be run from the editor, similar to those you'd find in an IDE
---@class EditorCommandRegistry : Class
---@field commands table
---@field order table
---@field provider_order table
---@field providers table
---@overload fun(): EditorCommandRegistry
local EditorCommandRegistry = Class()

function EditorCommandRegistry:init()
    self.commands = {}
    self.order = {}
    self.providers = {}
    self.provider_order = {}
end

function EditorCommandRegistry:register(id, definition)
    assert(type(id) == "string" and id ~= "", "Editor commands require an id")
    assert(type(definition) == "table", "Editor commands require a definition")
    assert(type(definition.action) == "function", "Editor commands require an action")
    definition = TableUtils.copy(definition, false)
    definition.id = id
    definition.name = definition.name or definition.label
        or StringUtils.titleCase(id:gsub("_", " "))
    if not self.commands[id] then table.insert(self.order, id) end
    self.commands[id] = definition
    return definition
end

function EditorCommandRegistry:unregister(id)
    if not self.commands[id] then return false end
    self.commands[id] = nil
    TableUtils.removeValue(self.order, id)
    return true
end

function EditorCommandRegistry:registerProvider(id, provider)
    assert(type(id) == "string" and id ~= "", "Editor command providers require an id")
    assert(type(provider) == "function", "Editor command providers require a callback")
    if not self.providers[id] then table.insert(self.provider_order, id) end
    self.providers[id] = provider
    return provider
end

function EditorCommandRegistry:unregisterProvider(id)
    if not self.providers[id] then return false end
    self.providers[id] = nil
    TableUtils.removeValue(self.provider_order, id)
    return true
end

function EditorCommandRegistry:getAll()
    local result = {}
    for _, id in ipairs(self.order) do
        local command = self.commands[id]
        if command then table.insert(result, command) end
    end
    for _, id in ipairs(self.provider_order) do
        local provider = self.providers[id]
        if provider then
            for index, provided in ipairs(provider() or {}) do
                if provided and type(provided.action) == "function" then
                    local command = TableUtils.copy(provided, false)
                    command.id = command.id or (id .. ":" .. index)
                    command.name = command.name or command.label or command.id
                    table.insert(result, command)
                end
            end
        end
    end
    return result
end

return EditorCommandRegistry
