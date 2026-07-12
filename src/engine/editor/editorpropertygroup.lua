---@class EditorPropertyGroup : Class
---@overload fun(id: string, options?: table, owner?: EditorPropertySet): EditorPropertyGroup
local EditorPropertyGroup = Class()

function EditorPropertyGroup:init(id, options, owner)
    options = options or {}
    self.id = id
    self.name = options.name or StringUtils.titleCase(id:gsub("_", " "))
    self.indexed = options.indexed == true
    self.primary = options.primary
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
    if self.owner and self.owner.values then
        for key in pairs(self.owner.values) do
            local matched, index = self:matchStorageKey(key)
            if matched and matched.id == id then
                local definition = TableUtils.copy(options, true)
                definition.group_id = self.id
                definition.group_index = index
                self.owner:registerProperty(key, options.type, definition)
            end
        end
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

function EditorPropertyGroup:getStorageKey(property_id, index)
    return self.indexed and (property_id .. tostring(index)) or property_id
end

function EditorPropertyGroup:matchStorageKey(key)
    if not self.indexed then return self.properties[key], nil end
    for _, id in ipairs(self.order) do
        if StringUtils.startsWith(key, id) then
            local suffix = key:sub(#id + 1)
            if suffix:match("^%d+$") then return self.properties[id], tonumber(suffix) end
        end
    end
end

function EditorPropertyGroup:getNextIndex(properties)
    if not self.indexed then return nil end
    local primary = self.primary or self.order[1]
    local index = 1
    while properties[self:getStorageKey(primary, index)] ~= nil do index = index + 1 end
    return index
end

function EditorPropertyGroup:addInstance(properties, property_types)
    properties = properties or (self.owner and self.owner.values)
    property_types = property_types or (self.owner and self.owner.types)
    local index = self.indexed and self:getNextIndex(properties) or nil
    for _, definition in ipairs(self:getProperties()) do
        local key = self:getStorageKey(definition.id, index)
        if self.owner and self.owner.values == properties then
            local instance_definition = TableUtils.copy(definition, true)
            instance_definition.group_id = self.id
            instance_definition.group_index = index
            self.owner:addProperty(key, definition.type, instance_definition)
            self.owner.definitions[key].custom = nil
        else
            properties[key] = self.registry:getDefault(definition.type, definition)
            property_types[key] = definition.type
        end
    end
    return index
end

function EditorPropertyGroup:bind(registry)
    self.registry = registry
    return self
end

return EditorPropertyGroup
