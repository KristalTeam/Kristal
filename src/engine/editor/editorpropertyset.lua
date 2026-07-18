--- Stores property values, types, definitions, and groups for one owner.
---@class EditorPropertySet : Class
---@field definitions table
---@field group_order table
---@field groups table
---@field order table
---@field types table
---@field values any
---@overload fun(values?: table, types?: table): EditorPropertySet
local EditorPropertySet = Class()

function EditorPropertySet:init(values, types, order, definitions)
    self.values = values or {}
    self.types = types or {}
    self.order = {}
    self.definitions = {}
    self.group_order = {}
    self.groups = {}
    local names, added = {}, {}
    for _, name in ipairs(order or {}) do
        if self.values[name] ~= nil and not added[name] then table.insert(names, name) added[name] = true end
    end
    local remaining = {}
    for name in pairs(self.values) do if not added[name] then table.insert(remaining, name) end end
    table.sort(remaining)
    for _, name in ipairs(remaining) do table.insert(names, name) end
    for _, name in ipairs(names) do
        self:registerProperty(name, self.types[name] or self:inferType(self.values[name]),
            TableUtils.merge({ custom = true }, definitions and definitions[name] or {}))
    end
end

function EditorPropertySet.fromEntries(entries, context)
    local values, types, order, definitions = Registry.editor_properties:decodePropertyEntries(entries, context)
    if not values then return nil, types end
    return EditorPropertySet(values, types, order, definitions)
end

function EditorPropertySet:encodeEntries(context)
    return Registry.editor_properties:encodePropertySet(self, context)
end

function EditorPropertySet:inferType(value)
    if type(value) == "boolean" then return "boolean" end
    if type(value) == "number" then return "number" end
    if type(value) == "function" then return "function" end
    if type(value) == "table" then return "table" end
    return "string"
end

function EditorPropertySet:registerProperty(id, property_type, options)
    options = TableUtils.copy(options or {}, true)
    options.id = id
    options.type = property_type or options.type or self.types[id] or "string"
    options.name = options.name or StringUtils.titleCase(id:gsub("_", " "))
    if not self.definitions[id] then table.insert(self.order, id) end
    self.definitions[id] = options
    if self.values[id] ~= nil then self.types[id] = options.type end
    return options
end

function EditorPropertySet:getProperty(id)
    return self.definitions[id]
end

function EditorPropertySet:getProperties()
    local result = {}
    for _, id in ipairs(self.order) do table.insert(result, self.definitions[id]) end
    return result
end

function EditorPropertySet:getValue(id)
    if self.values[id] ~= nil then return self.values[id] end
    local definition = self.definitions[id]
    return Registry.editor_properties:getDefault(definition and definition.type or "string", definition)
end

function EditorPropertySet:setValue(id, value)
    local definition = self.definitions[id] or self:registerProperty(id, self.types[id] or self:inferType(value), { custom = true })
    if definition.unavailable then return false end
    local coerced = Registry.editor_properties:coerce(definition.type, value, definition)
    if coerced == nil then return false end
    self.values[id] = coerced
    self.types[id] = definition.type
    return true
end

function EditorPropertySet:normalizeObjectReferences(default_map_id)
    for _, definition in ipairs(self:getProperties()) do
        if definition.type == "marker_reference" then definition.type = "object_reference" end
        if definition.type == "object_reference" and self.values[definition.id] ~= nil then
            local map_id = default_map_id
            if definition.target_map_property then
                local map_key = definition.target_map_property
                if definition.group_index then map_key = map_key .. tostring(definition.group_index) end
                map_id = self.values[map_key] or map_id
            end
            local reference = EditorObjectReference.from(self.values[definition.id], map_id)
            if definition.allowed_types
                and MapUtils.isObjectTypeAllowed("marker", definition.allowed_types) then
                reference = MapUtils.resolveMarkerReference(map_id, self.values[definition.id])
            end
            self.values[definition.id] = reference
            self.types[definition.id] = "object_reference"
        end
    end
end

function EditorPropertySet:addProperty(id, property_type, options)
    local definition = self:registerProperty(id, property_type, TableUtils.merge({ custom = true }, options or {}))
    self.values[id] = Registry.editor_properties:getDefault(definition.type, definition)
    self.types[id] = definition.type
    return definition
end

function EditorPropertySet:renameProperty(old_id, new_id)
    local definition = self.definitions[old_id]
    if not definition or self.definitions[new_id] then return false end
    self.values[new_id], self.values[old_id] = self.values[old_id], nil
    self.types[new_id], self.types[old_id] = self.types[old_id], nil
    self.definitions[old_id] = nil
    definition.id = new_id
    definition.name = StringUtils.titleCase(new_id:gsub("_", " "))
    self.definitions[new_id] = definition
    for index, id in ipairs(self.order) do if id == old_id then self.order[index] = new_id break end end
    return true
end

function EditorPropertySet:removeProperty(id)
    local definition = self.definitions[id]
    self.values[id] = nil
    self.types[id] = nil
    if definition and definition.custom then
        self.definitions[id] = nil
        for index, candidate in ipairs(self.order) do
            if candidate == id then table.remove(self.order, index) break end
        end
    end
    return definition ~= nil
end

function EditorPropertySet:registerGroup(id, options)
    local group = EditorPropertyGroup(id, options, self):bind(Registry.editor_properties)
    if not self.groups[id] then table.insert(self.group_order, id) end
    self.groups[id] = group
    return group
end

function EditorPropertySet:getGroups()
    local result = {}
    for _, id in ipairs(self.group_order) do table.insert(result, self.groups[id]) end
    return result
end

return EditorPropertySet
