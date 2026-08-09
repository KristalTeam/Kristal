--- Registers property types and handles their values.
---@class EditorPropertyRegistry : Class
---@field function_sources table
---@field last_function_error any
---@field type_order table
---@field types table
---@overload fun(): EditorPropertyRegistry
local EditorPropertyRegistry = Class()

function EditorPropertyRegistry:init()
    self.types = {}
    self.type_order = {}
    self.function_sources = setmetatable({}, { __mode = "k" })
    self:registerType("string", { name = "String", default = "", control = "text" })
    self:registerType("value", {
        name = "Value", default = "", control = "multiline_value",
        encode = function(value, _, context) return self:encodeDynamic(value, context) end,
        decode = function(value, _, context) return self:decodeDynamic(value, context) end,
        coerce = function(value)
            if type(value) ~= "string" then return value end
            local trimmed = value:match("^%s*(.-)%s*$")
            if trimmed:match("^function%s*%(") then
                return self:compileFunction(value)
            end
            if trimmed:sub(1, 1) == "{" then
                return self:compileTable(value)
            end
            if value:lower() == "true" then return true end
            if value:lower() == "false" then return false end
            return tonumber(value) or value
        end
    })
    self:registerType("table", {
        name = "Table", default = {}, control = "table",
        encode = function(value, _, context) return self:encodeTable(value, context) end,
        decode = function(value, _, context) return self:decodeTable(value, context) end,
        coerce = function(value)
            if type(value) == "table" then return value end
            return self:compileTable(value)
        end
    })
    self:registerType("function", {
        name = "Function", default = "", control = "multiline_value",
        encode = function(value)
            if type(value) == "string" then return value end
            local source = self.function_sources[value]
            if source then return source end
            return nil, "Cannot encode an editor function whose source is unavailable"
        end,
        decode = function(value)
            if type(value) == "function" then return value end
            local result = self:compileFunction(value)
            return result, result and nil or self.last_function_error
        end,
        coerce = function(value)
            if type(value) == "function" then return value end
            return self:compileFunction(tostring(value or ""))
        end
    })
    self:registerType("number", { name = "Number", default = 0, control = "text", coerce = function(value) return tonumber(value) end })
    self:registerType("integer", {
        name = "Integer", default = 0, control = "text",
        coerce = function(value)
            local number = tonumber(value)
            return number and MathUtils.round(number) or nil
        end
    })
    self:registerType("boolean", {
        name = "Boolean", default = false, control = "boolean",
        coerce = function(value)
            if type(value) == "boolean" then return value end
            if tostring(value):lower() == "true" then return true end
            if tostring(value):lower() == "false" then return false end
        end
    })
    self:registerType("choice", {
        name = "Choice", default = "", control = "choice",
        coerce = function(value, definition)
            for _, choice in ipairs(self:getChoices(definition)) do
                local choice_value = EditorChoiceUtils.getValue(choice)
                if choice_value == value or tostring(choice_value) == tostring(value) then return choice_value end
            end
        end
    })
    self:registerType("chooser", {
        name = "Chooser", default = "", control = "choice", coerce = self.types.choice.coerce
    })
    self:registerType("color", {
        name = "Color", default = "#FFFFFFFF", control = "color",
        coerce = function(value)
            value = tostring(value or "")
            local hex = value:gsub("^#", "")
            return (#hex == 6 or #hex == 8) and hex:match("^%x+$") and "#" .. hex or nil
        end
    })
    self:registerType("asset_path", {
        name = "Asset Path", default = "", control = "path", path_kind = "asset"
    })
    self:registerType("script_path", {
        name = "Script Path", default = "", control = "path", path_kind = "script"
    })
    self:registerType("object_reference", {
        name = "Object Reference",
        default = nil,
        control = "object_reference",
        encode = function(value)
            if value == nil then return nil end
            local reference = EditorObjectReference.from(value)
            return { map = reference.map_id, object = reference.object_id }
        end,
        decode = function(value, definition, context)
            if value == nil then return nil end
            local map_id = definition and definition.map_id
                or context and context.map and context.map.id
            return EditorObjectReference.from(value, map_id)
        end,
        coerce = function(value, definition)
            if value == nil or value == "" then return EditorObjectReference(definition and definition.map_id, nil) end
            return EditorObjectReference.from(value, definition and definition.map_id)
        end
    })
    self:registerType("marker_reference", {
        name = "Marker Reference (Legacy)",
        control = "object_reference",
        encode = self.types.object_reference.encode,
        decode = function(value)
            return type(value) == "table" and TableUtils.copy(value, true) or value
        end,
        coerce = self.types.object_reference.coerce
    })
end

local function isObjectReference(value)
    return type(value) == "table" and value.includes and value:includes(EditorObjectReference)
end

---Encodes arbitrary values used by the `value` and `table` property types.
function EditorPropertyRegistry:encodeDynamic(value, context, seen)
    local value_type = type(value)
    if value_type == "nil" or value_type == "boolean" or value_type == "number" or value_type == "string" then
        return value
    elseif value_type == "function" then
        local encoded, err = self:encode("function", value, nil, context)
        if err then return nil, err end
        return { type = "function", value = encoded }
    elseif isObjectReference(value) then
        return { type = "object_reference", value = self:encode("object_reference", value, nil, context) }
    elseif value_type == "table" then
        local encoded, err = self:encodeTable(value, context, seen)
        if err then return nil, err end
        return { type = "table", value = encoded }
    end
    return nil, "Unsupported editor property value type: " .. value_type
end

function EditorPropertyRegistry:decodeDynamic(value, context)
    if type(value) ~= "table" or type(value.type) ~= "string" or value.value == nil then return value end
    if value.type == "function" or value.type == "object_reference" or value.type == "table" then
        return self:decode(value.type, value.value, nil, context)
    end
    return TableUtils.copy(value, true)
end

function EditorPropertyRegistry:encodeTable(value, context, seen)
    if type(value) ~= "table" then return nil, "Table property value must be a table" end
    seen = seen or {}
    if seen[value] then return nil, "Cannot encode a cyclic editor property table" end
    seen[value] = true
    local result
    if TableUtils.isContiguousArray(value) then
        result = { kind = "array", values = {} }
        for index = 1, #value do
            local encoded, err = self:encodeDynamic(value[index], context, seen)
            if err then seen[value] = nil return nil, err end
            result.values[index] = encoded
        end
    else
        result = { kind = "object", entries = {} }
        for _, key in ipairs(TableUtils.getSortedKeys(value)) do
            local encoded_key, key_err = self:encodeDynamic(key, context, seen)
            if key_err then seen[value] = nil return nil, key_err end
            local encoded_value, value_err = self:encodeDynamic(value[key], context, seen)
            if value_err then seen[value] = nil return nil, value_err end
            table.insert(result.entries, { key = encoded_key, value = encoded_value })
        end
    end
    seen[value] = nil
    return result
end

function EditorPropertyRegistry:decodeTable(value, context)
    if type(value) ~= "table" then return nil, "Encoded table property must be a table" end
    local result = {}
    if value.kind == "array" then
        for index, encoded in ipairs(value.values or {}) do
            local decoded, err = self:decodeDynamic(encoded, context)
            if err then return nil, err end
            result[index] = decoded
        end
    elseif value.kind == "object" then
        for _, entry in ipairs(value.entries or {}) do
            local key, key_err = self:decodeDynamic(entry.key, context)
            if key_err then return nil, key_err end
            local decoded, value_err = self:decodeDynamic(entry.value, context)
            if value_err then return nil, value_err end
            result[key] = decoded
        end
    else
        return TableUtils.copy(value, true)
    end
    return result
end

function EditorPropertyRegistry:compileTable(source)
    local chunk, message = loadstring("return " .. tostring(source or ""), "editor_property_table")
    if not chunk then self.last_function_error = message return nil end
    local success, value = pcall(chunk)
    if not success or type(value) ~= "table" then
        self.last_function_error = success and "Value is not a table" or tostring(value)
        return nil
    end
    self.last_function_error = nil
    return value
end

function EditorPropertyRegistry:formatValue(value, indent, seen)
    local value_type = type(value)
    if value_type == "function" then
        return self.function_sources[value]
            or "function(...)\n    -- existing function source is unavailable\nend"
    elseif value_type == "string" then
        return string.format("%q", value)
    elseif value_type ~= "table" then
        if value == nil then return "nil" end
        return tostring(value)
    end

    indent = indent or 0
    seen = seen or {}
    if seen[value] then return "\"<cyclic table>\"" end
    seen[value] = true
    local padding = string.rep("    ", indent)
    local child_padding = string.rep("    ", indent + 1)
    local entries = {}
    local array = TableUtils.isContiguousArray(value)
    for _, key in ipairs(TableUtils.getSortedKeys(value)) do
        local formatted = self:formatValue(value[key], indent + 1, seen)
        if array then
            table.insert(entries, child_padding .. formatted)
        else
            local key_text
            if type(key) == "string" and key:match("^[%a_][%w_]*$") then
                key_text = key
            else
                key_text = "[" .. self:formatValue(key, indent + 1, seen) .. "]"
            end
            table.insert(entries, child_padding .. key_text .. " = " .. formatted)
        end
    end
    seen[value] = nil
    if #entries == 0 then return "{}" end
    return "{\n" .. table.concat(entries, ",\n") .. "\n" .. padding .. "}"
end

function EditorPropertyRegistry:compileFunction(source)
    local chunk, message = loadstring("return " .. tostring(source or ""), "editor_property_function")
    if not chunk then self.last_function_error = message return nil end
    local success, value = pcall(chunk)
    if not success or type(value) ~= "function" then
        self.last_function_error = success and "Value is not an anonymous function" or tostring(value)
        return nil
    end
    self.last_function_error = nil
    self.function_sources[value] = source
    return value
end

function EditorPropertyRegistry:getDisplayValue(type_id, value)
    if type(value) == "function" then
        return self.function_sources[value] or "-- Existing function source is unavailable\nfunction(...)\n    -- replace to edit\nend"
    end
    if type(value) == "table" then return self:formatValue(value) end
    if value == nil then return "" end
    return tostring(value)
end

function EditorPropertyRegistry:registerType(id, definition)
    assert(type(id) == "string" and id ~= "", "Editor property types require an id")
    assert(type(definition) == "table", "Editor property type definitions must be tables")
    local entry = TableUtils.copy(definition, true)
    entry.id = id
    entry.name = entry.name or StringUtils.titleCase(id:gsub("_", " "))
    if not self.types[id] then table.insert(self.type_order, id) end
    self.types[id] = entry
    return entry
end

function EditorPropertyRegistry:getType(id)
    return self.types[id] or self.types.string
end

function EditorPropertyRegistry:getTypeExact(id)
    return self.types[id]
end

function EditorPropertyRegistry:hasType(id)
    return self.types[id] ~= nil
end

function EditorPropertyRegistry:getTypes()
    local result = {}
    for _, id in ipairs(self.type_order) do table.insert(result, self.types[id]) end
    return result
end

function EditorPropertyRegistry:getChoices(definition)
    return EditorChoiceUtils.resolve(definition and definition.choices, definition)
end

function EditorPropertyRegistry:registryChoices(registry_key, options)
    options = options or {}
    return function()
        local choices, seen = {}, {}
        if options.optional then table.insert(choices, { value = "", label = "None" }) end
        local keys = type(registry_key) == "table" and registry_key or { registry_key }
        for _, key in ipairs(keys) do
            for id in pairs(Registry[key] or {}) do
                if not seen[id] then
                    seen[id] = true
                    table.insert(choices, id)
                end
            end
        end
        table.sort(choices, function(a, b)
            local a_value = type(a) == "table" and (a.value or a.id or "") or a
            local b_value = type(b) == "table" and (b.value or b.id or "") or b
            return tostring(a_value):lower() < tostring(b_value):lower()
        end)
        return choices
    end
end

function EditorPropertyRegistry:coerce(type_id, value, definition)
    local property_type = self:getType(type_id)
    if property_type.coerce then return property_type.coerce(value, definition or {}, property_type) end
    return tostring(value or "")
end

function EditorPropertyRegistry:encode(type_id, value, definition, context)
    local property_type = self:getTypeExact(type_id)
    if not property_type then return TableUtils.copy(value, true) end
    if property_type.encode then return property_type.encode(value, definition or {}, context or {}, property_type) end
    local value_type = type(value)
    if value == nil or value_type == "boolean" or value_type == "number" or value_type == "string" then return value end
    return nil, "Property type '" .. type_id .. "' needs an encode callback for " .. value_type .. " values"
end

function EditorPropertyRegistry:decode(type_id, value, definition, context)
    local property_type = self:getTypeExact(type_id)
    if not property_type then return TableUtils.copy(value, true) end
    if property_type.decode then return property_type.decode(value, definition or {}, context or {}, property_type) end
    return value
end

function EditorPropertyRegistry:encodePropertySet(property_set, context)
    local entries = {}
    for _, definition in ipairs(property_set:getProperties()) do
        local name, type_id = definition.id, definition.type or "string"
        if property_set.values[name] ~= nil then
            local encoded, err = self:encode(type_id, property_set.values[name], definition, context)
            if err then return nil, string.format("Property '%s': %s", name, err) end
            table.insert(entries, { name = name, type = type_id, value = encoded })
        end
    end
    return entries
end

function EditorPropertyRegistry:decodePropertyEntries(entries, context)
    local values, types, order, definitions = {}, {}, {}, {}
    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "" then
            local type_id = entry.type or "string"
            local value, err = self:decode(type_id, entry.value, entry, context)
            if err then return nil, err end
            values[entry.name], types[entry.name] = value, type_id
            table.insert(order, entry.name)
            definitions[entry.name] = { custom = true, unavailable = not self:hasType(type_id) }
        end
    end
    return values, types, order, definitions
end

function EditorPropertyRegistry:getDefault(type_id, definition)
    local value = definition and definition.default
    if value == nil then value = self:getType(type_id).default end
    return type(value) == "table" and TableUtils.copy(value, true) or value
end

return EditorPropertyRegistry
