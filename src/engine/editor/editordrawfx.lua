---@class EditorDrawFX : Class
---@overload fun(id: string, definition?: table, data?: table): EditorDrawFX
local EditorDrawFX = Class()

function EditorDrawFX:init(id, definition, data)
    self.id = id
    self.definition = definition or {}
    self.data = data or {}
    self.data.id = id
    self.data.properties = self.data.properties or {}
    self.data.__editor_property_types = self.data.__editor_property_types or {}
    self.properties = self.data.properties
    self.property_set = EditorPropertySet(self.data.properties, self.data.__editor_property_types)
    self:registerProperty("priority", "number", { default = self.definition.priority or 0 })
    if self.definition.init then self.definition.init(self) end
end

function EditorDrawFX:registerProperty(id, property_type, options)
    return self.property_set:registerProperty(id, property_type, options)
end

function EditorDrawFX:getName()
    return self.definition.name or StringUtils.titleCase(self.id:gsub("[/_]", " "))
end

return EditorDrawFX
