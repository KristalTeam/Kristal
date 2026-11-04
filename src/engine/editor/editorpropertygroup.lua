--- Describes a reusable group of related properties.
---@class EditorPropertyGroup : Class
---@field id string?
---@field indexed boolean
---@field name string?
---@field order table
---@field owner any
---@field properties table
---@field registry any
---@overload fun(id: string, options?: table, owner?: EditorPropertySet): EditorPropertyGroup
local EditorPropertyGroup = Class()

function EditorPropertyGroup:init(id, options, owner)
    options = options or {}
    self.id = id
    self.name = options.name or StringUtils.titleCase(id:gsub("_", " "))
    self.indexed = options.indexed == true
    self.owner = owner
    self.order = {}
    self.properties = {}
end

function EditorPropertyGroup:registerProperty(id, property_type, options)
    options = TableUtils.copy(options or {}, true)
    options.id = id
    options.type = property_type or options.type or "string"
    options.name = options.name or StringUtils.titleCase(id:gsub("_", " "))
    if not self.properties[id] then table.insert(self.order, id) end
    self.properties[id] = options
    if self.owner then
        local definition = { fields = self.properties, field_order = self.order }
        if self.indexed then
            definition = { array = true, entry_type = "table", entry_options = definition }
        end
        definition.name = self.name
        self.owner:registerProperty(self.id, "table", definition)
    end
    return options
end

function EditorPropertyGroup:getProperty(id)
    return self.properties[id]
end

function EditorPropertyGroup:getProperties()
    local result = {}
    for _, id in ipairs(self.order) do table.insert(result, self.properties[id]) end
    return result
end

function EditorPropertyGroup:addInstance(properties, property_types)
    properties = properties or (self.owner and self.owner.values)
    property_types = property_types or (self.owner and self.owner.types)
    local instance = {}
    for _, definition in ipairs(self:getProperties()) do
        instance[definition.id] = self.registry:getDefault(definition.type, definition)
    end
    if self.indexed then
        properties[self.id] = properties[self.id] or {}
        table.insert(properties[self.id], instance)
    else
        properties[self.id] = instance
    end
    property_types[self.id] = "table"
    return self.indexed and #properties[self.id] or nil
end

function EditorPropertyGroup:bind(registry)
    self.registry = registry
    return self
end

return EditorPropertyGroup
