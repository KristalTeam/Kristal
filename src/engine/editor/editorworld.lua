--- Stores a group of positioned maps for world editing.
---@class EditorWorld : Class
---@field __editor_property_types table
---@field data table
---@field id string?
---@field map_lookup table<string, table>
---@field maps table
---@field name string?
---@field primary_map_id string?
---@field properties table
---@overload fun(id?: string): EditorWorld
local EditorWorld = Class()

function EditorWorld:init(id)
    self.id = id
    self.name = id
    self.properties = {}
    self.__editor_property_types = {}
    self.primary_map_id = nil
    self.maps = {}
    self.map_lookup = {}
end

function EditorWorld:initializeFormatExtensions(force)
    self.data = self.data or {}
    return EditorFormat.decodeWorldExtensions(self.data, {
        world = self.data, editor_world = self, world_id = self.id
    }, force)
end

function EditorWorld:getFormatExtensionData(id, default)
    self.data = self.data or {}
    self.data.extensions = self.data.extensions or {}
    local value = self.data.extensions[id]
    if value == nil and default ~= nil then
        value = type(default) == "table" and TableUtils.copy(default, true) or default
        self.data.extensions[id] = value
    end
    return value
end

function EditorWorld:setFormatExtensionData(id, value)
    assert(type(id) == "string" and id ~= "", "World format extension data requires an id")
    self.data = self.data or {}
    self.data.extensions = self.data.extensions or {}
    self.data.extensions[id] = value
    return value
end

function EditorWorld:hasMap(id)
    return self.map_lookup[id] ~= nil
end

function EditorWorld:addMap(id, x, y, options)
    options = options or {}
    if not Registry.hasMap(id) then return nil end
    local entry = self.map_lookup[id]
    if entry then
        if x ~= nil then entry.x = x end
        if y ~= nil then entry.y = y end
        if options.explicit_companion ~= false then entry.explicit_companion = true end
        return entry
    end
    local data = Registry.getMapData(id)
    local grid_width = data and (data.grid_width or data.tilewidth) or 40
    local grid_height = data and (data.grid_height or data.tileheight) or 40
    entry = {
        id = id,
        x = x or 0,
        y = y or 0,
        width = data and (data.width or 16) * grid_width,
        height = data and (data.height or 12) * grid_height,
        tile_width = grid_width,
        tile_height = grid_height,
        explicit_companion = options.explicit_companion ~= false,
        preview = nil,
        preview_attempted = false
    }
    self.map_lookup[id] = entry
    table.insert(self.maps, entry)
    return entry
end

function EditorWorld:setPrimaryMap(id)
    local entry = self:addMap(id, nil, nil, { explicit_companion = false })
    if not entry then return false end
    local previous = self.primary_map_id and self.map_lookup[self.primary_map_id]
    if previous and previous ~= entry then
        previous.primary = false
        if not previous.explicit_companion then self:removeMap(previous.id, true) end
    end
    self.primary_map_id = id
    entry.primary = true
    return true
end

function EditorWorld:getPrimaryMap()
    return self.primary_map_id and self.map_lookup[self.primary_map_id] or nil
end

function EditorWorld:setMapPosition(id, x, y)
    local entry = self.map_lookup[id]
    if not entry then return false end
    entry.x, entry.y = x or entry.x, y or entry.y
    return true
end

function EditorWorld:removeMap(id, allow_primary)
    if id == self.primary_map_id and not allow_primary then return false end
    local entry = self.map_lookup[id]
    if not entry then return false end
    for index, candidate in ipairs(self.maps) do
        if candidate == entry then table.remove(self.maps, index) break end
    end
    self.map_lookup[id] = nil
    if id == self.primary_map_id then self.primary_map_id = nil end
    return true
end

function EditorWorld:getBounds()
    local first = self.maps[1]
    if not first then return 0, 0, 0, 0 end
    local min_x, min_y = first.x, first.y
    local max_x, max_y = first.x + (first.width or 0), first.y + (first.height or 0)
    for _, entry in ipairs(self.maps) do
        min_x, min_y = math.min(min_x, entry.x), math.min(min_y, entry.y)
        max_x = math.max(max_x, entry.x + (entry.width or 0))
        max_y = math.max(max_y, entry.y + (entry.height or 0))
    end
    return min_x, min_y, max_x, max_y
end

function EditorWorld:createReference(map_id, object_id)
    return EditorObjectReference(map_id, object_id)
end

return EditorWorld
