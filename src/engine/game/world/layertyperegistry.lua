---@class LayerTypeRegistry : Class
---@overload fun(): LayerTypeRegistry
local LayerTypeRegistry = Class()

local function objectLoader(callback)
    return function(map, layer, depth, reader, definition)
        if callback then callback(map, layer, depth, reader, definition) end
        map:loadShapes(layer)
    end
end

local function eventLoader(group)
    return objectLoader(function(map, layer, depth)
        map:loadObjects(layer, depth, group)
    end)
end

local function mapLoader(method)
    return objectLoader(function(map, layer)
        map[method](map, layer)
    end)
end

local function objectProperties(properties)
    properties:registerProperty("spawn", "boolean")
end

local function imageProperties(properties)
    properties:registerProperty("speedx", "number", { name = "Speed X" })
    properties:registerProperty("speedy", "number", { name = "Speed Y" })
    properties:registerProperty("wrapx", "boolean", { name = "Wrap X" })
    properties:registerProperty("wrapy", "boolean", { name = "Wrap Y" })
    properties:registerProperty("fitscreen", "boolean", { name = "Fit Screen" })
    properties:registerProperty("scalex", "number", { name = "Scale X", default = 1 })
    properties:registerProperty("scaley", "number", { name = "Scale Y", default = 1 })
end

local DEFAULT_KINDS = {
    {
        id = "group",
        format = {
            "id",
            "name",
            "color",
            "depth",
            "visible",
            "locked",
            "layers"
        }
    },
    {
        id = "tile",
        format = {
            "default",
            "tileset",
            "tileset_columns",
            "tileset_rows",
            "chunks",
        },
        extra_format = {
            ["chunks"] = {
                "x",
                "y",
                "tile_data"
            }
        }
    },
    {
        id = "object",
        format = {
            "default",
            "draw_order",
            "objects"
        }
    },
    {
        id = "image",
        format = {
            "default",
            "image",
            "image_width",
            "image_height",
            "repeat_x",
            "repeat_y",
            "transparent_color"
        }
    }
}

local DEFAULT_TYPES = {
    { id = "default",        name = "Unknown",         kind = "object", icon = "editor/ui/layer/default",        color = { 0.8, 0.8, 0.82, 1 }, load = objectLoader() },
    { id = "folder",         name = "Folder",          kind = "group",  icon = "editor/ui/layer/default",        color = { 1, 1, 1, 1 } },
    { id = "tile",           name = "Tiles",           kind = "tile",   icon = "editor/ui/layer/tile",           color = { 0.8, 0.8, 0.82, 1 } },
    { id = "image",          name = "Image",           kind = "image",  icon = "editor/ui/layer/image",          color = { 0.8, 0.8, 0.82, 1 }, properties = imageProperties },
    { id = "objects",        name = "Objects",         kind = "object", icon = "editor/ui/layer/objects",        color = { 1, 0, 1, 1 },       load = eventLoader("events"), properties = objectProperties },
    { id = "controllers",    name = "Controllers",     kind = "object", icon = "editor/ui/layer/controllers",    color = { 0, 1, 0.25, 1 }, load = eventLoader("controllers") },
    { id = "markers",        name = "Markers",         kind = "object", icon = "editor/ui/layer/markers",        color = { 0.49, 0, 1, 1 }, load = mapLoader("loadMarkers") },
    { id = "collision",      name = "Collision",       kind = "object", icon = "editor/ui/layer/collision",      color = { 0, 0, 1, 1 },       load = mapLoader("loadCollision") },
    { id = "enemycollision", name = "Enemy Collision", kind = "object", icon = "editor/ui/layer/enemycollision", color = { 0, 1, 1, 1 },       load = mapLoader("loadEnemyCollision") },
    { id = "blockcollision", name = "Block Collision", kind = "object", icon = "editor/ui/layer/blockcollision", color = { 1, 0.35, 0, 1 },    load = mapLoader("loadBlockCollision") },
    { id = "paths",          name = "Paths",           kind = "object", icon = "editor/ui/layer/paths",          color = { 1, 0.35, 0.85, 1 }, load = mapLoader("loadPaths") },
    { id = "battleareas",    name = "Battle Areas",    kind = "object", icon = "editor/ui/layer/battleareas",    color = { 1, 0.25, 0.25, 1 }, load = mapLoader("loadBattleAreas") },
    { id = "battleborder",   name = "Battle Border",   kind = "tile",   icon = "editor/ui/layer/default",        color = { 0.75, 0.85, 1, 1 } },
}

function LayerTypeRegistry:init()
    self.kinds = {}
    self.kind_order = {}
    self.types = {}
    self.order = {}
    for _, definition in ipairs(DEFAULT_KINDS) do
        self:registerKind(definition.id, definition)
    end
    for _, definition in ipairs(DEFAULT_TYPES) do
        self:register(definition.id, definition)
    end
end

---@param id string
---@param definition table
function LayerTypeRegistry:registerKind(id, definition)
    assert(type(id) == "string" and id ~= "", "Layer kind requires a non-empty id")
    assert(type(definition) == "table", "Layer kind definition must be a table")
    local entry = TableUtils.copy(definition, true)
    entry.id = id
    entry.name = entry.name or StringUtils.titleCase(id:gsub("_", " "))
    entry.format = entry.format or { "default" }
    entry.extra_format = entry.extra_format or {}
    if not self.kinds[id] then table.insert(self.kind_order, id) end
    self.kinds[id] = entry
    return entry
end

function LayerTypeRegistry:getKind(id)
    return self.kinds[id]
end

function LayerTypeRegistry:getKinds()
    local result = {}
    for _, id in ipairs(self.kind_order) do table.insert(result, self.kinds[id]) end
    return result
end

function LayerTypeRegistry:getKindFormat(id, default_format)
    local kind = self:getKind(id)
    if not kind then return TableUtils.copy(default_format or {}, true), {} end
    local result = {}
    for _, field in ipairs(kind.format or {}) do
        if field == "default" then
            for _, common in ipairs(default_format or {}) do table.insert(result, common) end
        else
            table.insert(result, field)
        end
    end
    return result, TableUtils.copy(kind.extra_format or {}, true)
end

function LayerTypeRegistry:encodeKind(id, layer, context)
    local kind = self:getKind(id)
    if not kind then return TableUtils.copy(layer, true), nil, false end
    if kind.encode then
        local encoded, err = kind.encode(layer, context or {}, kind)
        return encoded, err, true
    end
    return TableUtils.copy(layer, true), nil, true
end

function LayerTypeRegistry:decodeKind(id, data, context)
    local kind = self:getKind(id)
    if not kind then
        return TableUtils.copy(data, true), nil, false
    end
    if kind.decode then
        local decoded, err = kind.decode(data, context or {}, kind)
        return decoded, err, true
    end
    return TableUtils.copy(data, true), nil, true
end

---@param id string
---@param definition table
function LayerTypeRegistry:register(id, definition)
    assert(type(id) == "string" and id ~= "", "Layer type requires a non-empty id")
    assert(type(definition) == "table", "Layer type definition must be a table")
    local entry = TableUtils.copy(definition, true)
    entry.id = id
    entry.name = entry.name or id
    entry.icon = entry.icon or "editor/ui/layer/default"
    entry.color = entry.color or { 1, 1, 1, 1 }
    entry.kind = entry.kind or "object"
    assert(self:getKind(entry.kind), "Unknown layer kind: " .. tostring(entry.kind))
    if not self.types[id] then table.insert(self.order, id) end
    self.types[id] = entry
    return entry
end

function LayerTypeRegistry:get(id)
    return self.types[id]
end

function LayerTypeRegistry:getLayerKind(layer)
    local kind = layer and (layer._editor_kind_id or layer.kind)
    if kind then return kind end
    local layer_type = layer and self:get(layer._editor_type_id or layer.type)
    return layer_type and layer_type.kind or "object"
end

function LayerTypeRegistry:initializeLayerProperties(layer, properties)
    properties:registerProperty("thin", "boolean")
    local kind = self:getKind(self:getLayerKind(layer))
    if kind and kind.properties then kind.properties(properties, layer, kind) end
    local layer_type = self:get(layer._editor_type_id or layer.type)
    if layer_type and layer_type.properties then layer_type.properties(properties, layer, layer_type) end
end

function LayerTypeRegistry:getAll()
    local result = {}
    for _, id in ipairs(self.order) do table.insert(result, self.types[id]) end
    return result
end

local function isLegacyType(layer, id)
    if layer.class ~= nil and layer.class ~= "" then return layer.class == id end
    return StringUtils.startsWith((layer.name or ""):lower(), id)
end

--- Resolves old Tiled layer naming/class conventions into an explicit editor layer type.
function LayerTypeRegistry:getLegacyTiledType(layer)
    if layer.type == "tilelayer" or layer.type == "imagelayer" then
        if isLegacyType(layer, "battleborder") then return self.types.battleborder end
        return self.types[layer.type == "tilelayer" and "tile" or "image"]
    elseif layer.type == "objectgroup" then
        local ids = { "objects", "controllers", "markers", "collision", "enemycollision",
            "blockcollision", "paths", "battleareas" }
        for _, id in ipairs(ids) do
            if isLegacyType(layer, id) then return self.types[id] end
        end
    end
    return self.types.default
end

function LayerTypeRegistry:getLayerColor(layer, layer_type)
    local color = layer and layer.color
    if type(color) == "table" then
        local divisor = math.max(color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 0) > 1 and 255 or 1
        return { (color[1] or 255) / divisor, (color[2] or 255) / divisor,
            (color[3] or 255) / divisor, (color[4] or divisor) / divisor }
    end
    layer_type = type(layer_type) == "table" and layer_type or self:get(layer_type)
    return TableUtils.copy(layer_type and layer_type.color or { 1, 1, 1, 1 })
end

return LayerTypeRegistry
