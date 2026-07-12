-- Native editor map, tileset, and world JSON format.

local EditorFormat = {}

EditorFormat.MAP_FORMAT_VERSION = 1
EditorFormat.TILESET_FORMAT_VERSION = 1
EditorFormat.WORLD_FORMAT_VERSION = 1
EditorFormat.TILED_MAP_CONVERSION_VERSION = 1
EditorFormat.TILED_TILESET_CONVERSION_VERSION = 1
EditorFormat.MAP_EXTENSION = ".json"
EditorFormat.TILESET_EXTENSION = ".json"
EditorFormat.WORLD_EXTENSION = ".json"
EditorFormat.WORLD_DIRECTORY = "world/worlds"

EditorFormat.TILE_FLIP_HORIZONTAL = 0x80000000
EditorFormat.TILE_FLIP_VERTICAL = 0x40000000
EditorFormat.TILE_ROTATE = 0x20000000
EditorFormat.TILE_ID_MASK = 0x1FFFFFFF
EditorFormat.CHUNK_SIZE = 16
EditorFormat.MILLISECONDS_PER_SECOND = 1000

function EditorFormat.slugId(value, fallback)
    local id = tostring(value or ""):lower()
    id = id:gsub("[^%w_ ]", "_"):gsub("%s+", "_"):gsub("_+", "_")
    id = id:gsub("^_+", ""):gsub("_+$", "")
    return id ~= "" and id or (fallback or "unnamed")
end

function EditorFormat.uniqueSlug(value, used, fallback)
    local base = EditorFormat.slugId(value, fallback)
    local id, index = base, 2
    while used[id] do
        id = base .. "_" .. index
        index = index + 1
    end
    used[id] = true
    return id
end

local function nextNumericId(preferred, used, state)
    preferred = tonumber(preferred)
    if preferred and preferred >= 1 and preferred % 1 == 0 and not used[preferred] then
        used[preferred] = true
        state.next_id = math.max(state.next_id, preferred + 1)
        return preferred
    end
    while used[state.next_id] do state.next_id = state.next_id + 1 end
    local id = state.next_id
    used[id] = true
    state.next_id = state.next_id + 1
    return id
end

function EditorFormat.packTile(tile_id, flip_x, flip_y, rotated)
    if tile_id == nil then return 0 end
    local payload = tile_id + 1
    assert(payload > 0 and payload <= EditorFormat.TILE_ID_MASK, "Tile id is outside the packed range")
    local packed = payload
    if flip_x then packed = bit.bor(packed, EditorFormat.TILE_FLIP_HORIZONTAL) end
    if flip_y then packed = bit.bor(packed, EditorFormat.TILE_FLIP_VERTICAL) end
    if rotated then packed = bit.bor(packed, EditorFormat.TILE_ROTATE) end
    if packed < 0 then packed = packed + 0x100000000 end
    return packed
end

function EditorFormat.unpackTile(packed)
    packed = tonumber(packed) or 0
    if packed == 0 then return nil, false, false, false end
    local signed = bit.tobit(packed)
    local payload = bit.band(signed, EditorFormat.TILE_ID_MASK)
    if payload == 0 then return nil, false, false, false end
    return payload - 1,
        bit.band(signed, EditorFormat.TILE_FLIP_HORIZONTAL) ~= 0,
        bit.band(signed, EditorFormat.TILE_FLIP_VERTICAL) ~= 0,
        bit.band(signed, EditorFormat.TILE_ROTATE) ~= 0
end

function EditorFormat.remapTileId(tile_id, old_columns, old_rows, new_columns, new_rows)
    old_columns, new_columns = tonumber(old_columns), tonumber(new_columns)
    if not old_columns or old_columns <= 0 or not new_columns or new_columns <= 0 then return tile_id end
    local x = tile_id % old_columns
    local y = math.floor(tile_id / old_columns)
    if old_rows and old_rows > 0 and y >= old_rows then return nil end
    if x >= new_columns then return nil end
    if new_rows and new_rows > 0 and y >= new_rows then return nil end
    return x + y * new_columns
end

EditorFormat.ORDERING = {
    map = {
        "version",
        "kristal_version",
        "id",
        "name",
        "width",
        "height",
        "grid_width",
        "grid_height",
        "background_color",
        "parallax_origin_x",
        "parallax_origin_y",
        "layers",
        "properties"
    },
    tileset = {
        "version",
        "kristal_version",
        "id",
        "name",
        "image",
        "image_width",
        "image_height",
        "tile_width",
        "tile_height",
        "tile_count",
        "tile_rows",
        "tile_columns",
        "spacing",
        "margin",
        "alignment",
        "render_size",
        "fill_mode",
        "tile_offset_x",
        "tile_offset_y",
        "transparent_color",
        "transform_rules",
        "tiles",
        "terrains",
        "properties"
    },
    tile = {
        "id",
        "type",
        "x",
        "y",
        "width",
        "height",
        "probability",
        "collision",
        "frames",
        "properties",
    },
    layer = {
        "id",
        "name",
        "color",
        "x",
        "y",
        "type",
        "kind",
        "depth",
        "alpha",
        "visible",
        "parallax_x",
        "parallax_y",
        "tile_width_override",
        "tile_height_override",
        "properties"
        --- extra kind specific info here
    },
    transform_rules = {
        "can_vflip",
        "can_hflip",
        "can_rotate",
        "prefer_untransformed",
    },
    world = {
        "version",
        "kristal_version",
        "id",
        "name",
        "maps",
        "properties"
    },
    world_map = {
        "map",
        "x",
        "y"
    },
    terrain = {
        "id",
        "name",
        "tile_icon",
        "type",
        "terrain_variants",
        "terrain_tiles",
        "properties",
    },
    object = {
        "id",
        "name",
        "type",
        "x",
        "y",
        "width",
        "height",
        "rotation",
        "shape",
        "scale_x",
        "scale_y",
        "origin_x",
        "origin_y",
        "alpha",
        "visible",
        "fx",
        "tileset", --- For tile objects
        "tile_id", --- --^
        "properties"
    },
    shape = {
        "type",
        "shape_data"
    },
    terrain_variant = {
        "id",
        "name",
        "color",
        "tile_icon",
        "probability",
        "properties"
    },
    terrain_tile = {
        "tile_id",
        "edges" -- 8 size table
    },
    frame = {
        "tile_id",
        "duration"
    },
    fx = {
        "type",
        "properties"
    },
    property = {
        "name",
        "type",
        "value"
    }
}

EditorFormat.SHAPE_DATA_TYPES = {
    point = {},
    line = {
        "points",
        "thickness"
    },
    rectangle = {},
    ellipse = {},
    polygon = {
        "points"
    },
    polyline = {
        "points",
        "edges",
        "thickness"
    }
}

local ARRAY_CHILDREN = {
    layers = "layer",
    properties = "property",
    objects = "object",
    chunks = "chunk",
    tiles = "tile",
    terrains = "terrain",
    terrain_variants = "terrain_variant",
    terrain_tiles = "terrain_tile",
    frames = "frame",
    fx = "fx",
    maps = "world_map",
    collision = "object"
}

local SERIALIZATION_METADATA = {
    full_path = true,
    __map_reader = true,
    __tileset_reader = true,
    __editor_property_types = true,
    __editor_property_order = true,
    _editor_property_types = true,
    _editor_property_order = true,
    _editor_property_set = true
}

local function getOrdering(schema, value)
    if schema == "layer" then
        return Registry.layer_types:getKindFormat(value.kind or "object", EditorFormat.ORDERING.layer)
    elseif schema and StringUtils.startsWith(schema, "shape_data:") then
        return EditorFormat.SHAPE_DATA_TYPES[schema:sub(12)]
    elseif schema == "chunk" then
        local tile_kind = Registry.getLayerKind("tile")
        return tile_kind and tile_kind.extra_format and tile_kind.extra_format.chunks
    end
    return EditorFormat.ORDERING[schema]
end

local function getChildSchema(schema, key, value)
    local child = ARRAY_CHILDREN[key]
    if child then return "array:" .. child end
    if schema == "chunk" and key == "tile_data" then
        return "compact_array:" .. EditorFormat.CHUNK_SIZE
    end
    if key == "shape" then return "shape" end
    if key == "shape_data" then return "shape_data:" .. tostring(schema == "shape" and value.type or "") end
    if schema == "shape_data:polyline" and key == "edges" then
        return "array:compact_array:2"
    end
    if key == "transform_rules" then return "transform_rules" end
end

local function shouldSerialize(key, value)
    if type(key) ~= "string" or SERIALIZATION_METADATA[key] then return false end
    if StringUtils.startsWith(key, "_editor") then return false end
    return type(value) ~= "function" and type(value) ~= "userdata" and type(value) ~= "thread"
end

local function encodeJSONValue(value, schema, options, depth, seen)
    local value_type = type(value)
    if value_type ~= "table" then
        local success, encoded = pcall(JSON.encode, value)
        if not success then return nil, encoded end
        return encoded
    end
    if seen[value] then return nil, "Cannot encode a circular JSON table" end
    seen[value] = true

    local pretty = options.pretty ~= false
    local indent = options.indent
    if type(indent) == "number" then indent = string.rep(" ", math.max(0, indent)) end
    indent = indent or "  "
    local newline = pretty and "\n" or ""
    local separator = pretty and ": " or ":"
    local padding = pretty and string.rep(indent, depth) or ""
    local child_padding = pretty and string.rep(indent, depth + 1) or ""
    local array_schema = schema and schema:match("^array:(.+)$")
    local compact_width = schema and tonumber(schema:match("^compact_array:(%d+)$"))
    local array = array_schema ~= nil or compact_width ~= nil
        or schema == nil and TableUtils.isContiguousArray(value)
    local parts = {}

    if array then
        for index = 1, #value do
            local encoded, reason = encodeJSONValue(value[index], array_schema, options, depth + 1, seen)
            if not encoded then seen[value] = nil return nil, reason end
            parts[index] = encoded
        end
        seen[value] = nil
        if #parts == 0 then return "[]" end
        if compact_width and pretty then
            local rows = {}
            for first = 1, #parts, compact_width do
                local row = {}
                for index = first, math.min(first + compact_width - 1, #parts) do
                    table.insert(row, parts[index])
                end
                table.insert(rows, child_padding .. table.concat(row, ", "))
            end
            return "[" .. newline .. table.concat(rows, "," .. newline) .. newline .. padding .. "]"
        end
        for index, encoded in ipairs(parts) do parts[index] = child_padding .. encoded end
        return "[" .. newline .. table.concat(parts, "," .. newline) .. newline .. padding .. "]"
    end

    local keys, included = {}, {}
    for _, key in ipairs(getOrdering(schema, value) or {}) do
        if value[key] ~= nil and shouldSerialize(key, value[key]) and not included[key] then
            table.insert(keys, key)
            included[key] = true
        end
    end
    local remaining = {}
    for key, child_value in pairs(value) do
        if not included[key] and shouldSerialize(key, child_value) then table.insert(remaining, key) end
    end
    table.sort(remaining)
    for _, key in ipairs(remaining) do table.insert(keys, key) end

    for _, key in ipairs(keys) do
        local child_schema = getChildSchema(schema, key, value)
        local encoded, reason = encodeJSONValue(value[key], child_schema, options, depth + 1, seen)
        if not encoded then seen[value] = nil return nil, reason end
        table.insert(parts, child_padding .. JSON.encode(key) .. separator .. encoded)
    end
    seen[value] = nil
    if #parts == 0 then return "{}" end
    return "{" .. newline .. table.concat(parts, "," .. newline) .. newline .. padding .. "}"
end

function EditorFormat.encodeJSON(data, schema, options)
    return encodeJSONValue(data, schema, options or {}, 0, {})
end

function EditorFormat.decodeJSON(source, path)
    if type(source) ~= "string" then return nil, "JSON source must be a string" end
    local success, data = pcall(JSON.decode, source)
    if not success then return nil, string.format("Could not decode %s: %s", path or "JSON", data) end
    if type(data) ~= "table" then return nil, string.format("%s must contain a JSON object", path or "File") end
    return data
end

local function copySerializable(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        if (type(key) == "number" or shouldSerialize(key, child)) and type(child) ~= "function" then
            result[key] = copySerializable(child, seen)
        end
    end
    return result
end

local function decodeOwnerProperties(owner, context)
    local entries = owner.properties or {}
    if type(entries[1]) ~= "table" or entries[1].name == nil then
        owner.properties = entries
        owner.__editor_property_types = owner.__editor_property_types or {}
        return true
    end
    local set, reason = EditorPropertySet.fromEntries(entries, context)
    if not set then return false, reason end
    owner.properties = set.values
    owner.__editor_property_types = set.types
    owner.__editor_property_order = TableUtils.copy(set.order)
    return true
end

local function encodeOwnerProperties(owner, context)
    local properties = owner.properties or {}
    if type(properties[1]) == "table" and properties[1].name ~= nil then
        return copySerializable(properties)
    end
    local set = owner._editor_property_set or owner.property_set
        or EditorPropertySet(properties, owner.__editor_property_types or owner._editor_property_types,
            owner.__editor_property_order or owner._editor_property_order)
    return Registry.editor_properties:encodePropertySet(set, context)
end

local function decodeShape(shape)
    if type(shape) ~= "table" then return shape end
    return shape.type or "rectangle", copySerializable(shape.shape_data or {})
end

local function encodeShape(object)
    if type(object.shape) == "table" then return copySerializable(object.shape) end
    local shape_type = object.shape or (object.point and "point") or (object.ellipse and "ellipse")
        or (object.polygon and "polygon") or (object.polyline and "polyline") or "rectangle"
    local shape_data = copySerializable(object.shape_data or {})
    if shape_type == "polygon" and object.polygon then
        shape_data.points = copySerializable(object.polygon)
    end
    if (shape_type == "line" or shape_type == "polyline") and object.polyline then
        shape_data.points = copySerializable(object.polyline or {})
    end
    if shape_type == "polyline" and shape_data.edges == nil then
        shape_data.edges = {}
        for index = 1, #(shape_data.points or {}) - 1 do
            table.insert(shape_data.edges, { index, index + 1 })
        end
    end
    return { type = shape_type, shape_data = shape_data }
end

local decodeObject, encodeObject, decodeLayer, encodeLayer

decodeObject = function(object, context)
    object = copySerializable(object)
    local shape, shape_data = decodeShape(object.shape)
    object.shape, object.shape_data = shape, shape_data
    if shape == "polygon" then object.polygon = copySerializable(shape_data.points or {}) end
    if shape == "line" or shape == "polyline" then
        object.polyline = copySerializable(shape_data.points or {})
    end
    local success, reason = decodeOwnerProperties(object, context)
    if not success then return nil, reason end
    for _, fx in ipairs(object.fx or {}) do
        fx.id = fx.id or fx.type
        local fx_success, fx_reason = decodeOwnerProperties(fx, context)
        if not fx_success then return nil, fx_reason end
    end
    object.__editor_fx = object.fx
    return object
end

encodeObject = function(object, context)
    local result = copySerializable(object)
    TableUtils.clearFields(result, { "class", "point", "ellipse", "polygon", "polyline", "shape_data", "__editor_fx" })
    result.type = object.type or object.class
    context.object_ids = context.object_ids or {}
    context.object_id_state = context.object_id_state or { next_id = 1 }
    result.id = nextNumericId(object.id, context.object_ids, context.object_id_state)
    result.shape = encodeShape(object)
    result.properties = nil
    local properties, reason = encodeOwnerProperties(object, context)
    if not properties then return nil, reason end
    result.properties = properties
    result.fx = {}
    for _, source_fx in ipairs(object.__editor_fx or object.fx or {}) do
        local fx = copySerializable(source_fx)
        fx.type = fx.type or fx.id
        fx.id = nil
        fx.properties = nil
        fx.properties, reason = encodeOwnerProperties(source_fx, context)
        if not fx.properties then return nil, reason end
        table.insert(result.fx, fx)
    end
    if #result.fx == 0 then result.fx = nil end
    return result
end

decodeLayer = function(source, context)
    local semantic_type = source.type or "default"
    local registered_type = Registry.getLayerType(semantic_type)
    local kind = source.kind or (registered_type and registered_type.kind) or "object"
    local layer, reason = Registry.layer_types:decodeKind(kind, source, context)
    if not layer then return nil, reason end
    layer._editor_type_id = semantic_type
    layer._editor_kind_id = kind
    layer._editor_depth_override = layer.depth
    layer._editor_visible = layer.visible ~= false
    layer.offsetx = layer.x or 0
    layer.offsety = layer.y or 0
    layer.opacity = layer.alpha == nil and 1 or layer.alpha
    layer.parallaxx = layer.parallax_x or 1
    layer.parallaxy = layer.parallax_y or 1
    layer.repeatx = layer.repeat_x
    layer.repeaty = layer.repeat_y
    layer.type = kind == "tile" and "tilelayer" or kind == "image" and "imagelayer"
        or kind == "group" and "group" or "objectgroup"
    local success
    success, reason = decodeOwnerProperties(layer, context)
    if not success then return nil, reason end
    if kind == "group" then
        local children = {}
        for _, child in ipairs(layer.layers or {}) do
            local decoded
            decoded, reason = decodeLayer(child, context)
            if not decoded then return nil, reason end
            table.insert(children, decoded)
        end
        layer.layers = children
    elseif kind == "object" then
        local objects = {}
        for _, object in ipairs(layer.objects or {}) do
            local decoded
            decoded, reason = decodeObject(object, context)
            if not decoded then return nil, reason end
            table.insert(objects, decoded)
        end
        layer.objects = objects
    end
    return layer
end

encodeLayer = function(source, context)
    local kind = Registry.layer_types:getLayerKind(source)
    if kind == "tile" and not source.chunks and type(source.data) == "table" and #source.data > 0 then
        return nil, "Legacy tile data must be converted to per-tileset packed chunks before saving"
    end
    local candidate, reason = Registry.layer_types:encodeKind(kind, source, context)
    if not candidate then return nil, reason end
    local result = copySerializable(candidate)
    TableUtils.clearFields(result, {
        "class", "offsetx", "offsety", "opacity", "parallaxx", "parallaxy", "repeatx", "repeaty",
        "draworder", "imagewidth", "imageheight", "transparentcolor", "tintcolor", "width", "height",
        "data", "encoding",
        "_editor_uid", "_editor_visible", "_editor_depth_override", "_editor_type_id", "_editor_kind_id"
    })
    result.type = source._editor_type_id or source.type or "default"
    if result.type == "tilelayer" or result.type == "imagelayer" or result.type == "objectgroup" or result.type == "group" then
        result.type = source._editor_type_id or "default"
    end
    result.kind = kind
    context.layer_ids = context.layer_ids or {}
    result.id = EditorFormat.uniqueSlug(source.name or source.id, context.layer_ids, "layer")
    result.x = source.x or source.offsetx
    result.y = source.y or source.offsety
    result.depth = source._editor_depth_override or source.depth
    result.alpha = source.alpha or source.opacity
    result.visible = source._editor_visible == nil and source.visible or source._editor_visible
    result.parallax_x = source.parallax_x or source.parallaxx
    result.parallax_y = source.parallax_y or source.parallaxy
    result.draw_order = source.draw_order or source.draworder
    result.repeat_x = source.repeat_x == nil and source.repeatx or source.repeat_x
    result.repeat_y = source.repeat_y == nil and source.repeaty or source.repeat_y
    result.image_width = source.image_width or source.imagewidth
    result.image_height = source.image_height or source.imageheight
    result.transparent_color = source.transparent_color or source.transparentcolor
    result.properties = nil
    result.properties, reason = encodeOwnerProperties(source, context)
    if not result.properties then return nil, reason end
    if kind == "group" then
        result.layers = {}
        for _, child in ipairs(source.layers or {}) do
            local encoded
            encoded, reason = encodeLayer(child, context)
            if not encoded then return nil, reason end
            table.insert(result.layers, encoded)
        end
    elseif kind == "object" then
        result.objects = {}
        for _, object in ipairs(source.objects or {}) do
            local encoded
            encoded, reason = encodeObject(object, context)
            if not encoded then return nil, reason end
            table.insert(result.objects, encoded)
        end
    end
    return result
end

local function decodeTile(tile, context)
    tile = copySerializable(tile)
    local success, reason = decodeOwnerProperties(tile, context)
    if not success then return nil, reason end
    if tile.frames and not tile.animation then
        tile.animation = {}
        for _, frame in ipairs(tile.frames) do
            table.insert(tile.animation, { tileid = frame.tile_id, duration = frame.duration })
        end
    end
    if tile.collision and not tile.objectgroup then
        tile.objectgroup = { objects = {} }
        for _, shape in ipairs(tile.collision) do
            local decoded, decode_reason = decodeObject(shape, context)
            if not decoded then return nil, decode_reason end
            table.insert(tile.objectgroup.objects, decoded)
        end
    end
    return tile
end

local function encodeTile(tile, context)
    local result = copySerializable(tile)
    TableUtils.clearFields(result, {
        "class", "image", "imagewidth", "imageheight", "animation", "objectgroup", "terrain",
        "__editor_property_types", "__editor_property_order"
    })
    result.type = tile.type or tile.class
    result.properties = nil
    local reason
    result.properties, reason = encodeOwnerProperties(tile, context)
    if not result.properties then return nil, reason end
    result.frames = nil
    if tile.animation or tile.frames then
        result.frames = {}
        for _, frame in ipairs(tile.animation or tile.frames) do
            table.insert(result.frames, { tile_id = frame.tile_id or frame.tileid, duration = frame.duration })
        end
    end
    result.collision = nil
    local collision = tile.objectgroup and tile.objectgroup.objects or tile.collision
    if collision then
        result.collision = {}
        local collision_context = { tileset = context.tileset, object_ids = {}, object_id_state = { next_id = 1 } }
        for _, shape in ipairs(collision) do
            local encoded
            encoded, reason = encodeObject(shape, collision_context)
            if not encoded then return nil, reason end
            table.insert(result.collision, encoded)
        end
    end
    return result
end


-- SECTION : Encode/Decode

---@return table? data
---@return string? error
function EditorFormat.decodeMap(source, path, options)
    local data, reason = EditorFormat.decodeJSON(source, path)
    if not data then return nil, reason end
    data, reason = EditorFormat.migrateMap(data)
    if not data then return nil, reason end
    local valid, diagnostics = EditorFormat.validateMap(data, options)
    if not valid then return nil, table.concat(diagnostics, "; ") end
    local success
    success, reason = decodeOwnerProperties(data, { owner = data, path = path })
    if not success then return nil, reason end
    local layers = {}
    for _, layer in ipairs(data.layers or {}) do
        local decoded
        decoded, reason = decodeLayer(layer, { map = data, path = path })
        if not decoded then return nil, reason end
        table.insert(layers, decoded)
    end
    data.layers = layers
    data.tilewidth = data.grid_width
    data.tileheight = data.grid_height
    data.backgroundcolor = data.background_color
    data.__map_reader = EditorMapReader
    return data
end

---@return string? encoded
---@return string? error
function EditorFormat.encodeMap(data, options)
    options = options or {}
    local result = copySerializable(data)
    TableUtils.clearFields(result, {
        "tilewidth", "tileheight", "backgroundcolor", "parallaxoriginx", "parallaxoriginy", "tilesets",
        "orientation", "renderorder", "infinite", "nextlayerid", "nextobjectid", "tiledversion",
        "luaversion", "compressionlevel", "class", "__map_reader", "full_path"
    })
    result.version = EditorFormat.MAP_FORMAT_VERSION
    result.kristal_version = result.kristal_version or tostring(Kristal.Version)
    result.grid_width = data.grid_width or data.tilewidth
    result.grid_height = data.grid_height or data.tileheight
    result.background_color = data.background_color or data.backgroundcolor
    result.parallax_origin_x = data.parallax_origin_x or data.parallaxoriginx
    result.parallax_origin_y = data.parallax_origin_y or data.parallaxoriginy
    result.properties = nil
    local reason
    result.properties, reason = encodeOwnerProperties(data, { owner = data })
    if not result.properties then return nil, reason end
    result.layers = {}
    local context = { map = result, layer_ids = {}, object_ids = {}, object_id_state = { next_id = 1 } }
    for _, layer in ipairs(data.layers or {}) do
        local encoded
        encoded, reason = encodeLayer(layer, context)
        if not encoded then return nil, reason end
        table.insert(result.layers, encoded)
    end
    local valid, diagnostics = EditorFormat.validateMap(result, options)
    if not valid then return nil, table.concat(diagnostics, "; ") end
    return EditorFormat.encodeJSON(result, "map", options)
end

---@return table? data
---@return string? error
function EditorFormat.decodeTileset(source, path, options)
    local data, reason = EditorFormat.decodeJSON(source, path)
    if not data then return nil, reason end
    data, reason = EditorFormat.migrateTileset(data)
    if not data then return nil, reason end
    local valid, diagnostics = EditorFormat.validateTileset(data, options)
    if not valid then return nil, table.concat(diagnostics, "; ") end
    local success
    success, reason = decodeOwnerProperties(data, { owner = data, path = path })
    if not success then return nil, reason end
    local tiles = {}
    for _, tile in ipairs(data.tiles or {}) do
        local decoded
        decoded, reason = decodeTile(tile, { tileset = data, path = path })
        if not decoded then return nil, reason end
        table.insert(tiles, decoded)
    end
    data.tiles = tiles
    for _, terrain in ipairs(data.terrains or {}) do
        success, reason = decodeOwnerProperties(terrain, { tileset = data, path = path })
        if not success then return nil, reason end
        for _, variant in ipairs(terrain.terrain_variants or {}) do
            success, reason = decodeOwnerProperties(variant, { tileset = data, path = path })
            if not success then return nil, reason end
        end
    end
    data.margin = data.margin or 0
    data.spacing = data.spacing or 0
    data.__tileset_reader = EditorTilesetReader
    return data
end

---@return string? encoded
---@return string? error
function EditorFormat.encodeTileset(data, options)
    options = options or {}
    local result = copySerializable(data)
    TableUtils.clearFields(result, {
        "tilewidth", "tileheight", "tilecount", "columns", "objectalignment", "tilerendersize",
        "fillmode", "tileoffset", "imagewidth", "imageheight", "transparentcolor", "grid",
        "wangsets", "transformations", "tiledversion", "class", "__tileset_reader", "full_path"
    })
    result.version = EditorFormat.TILESET_FORMAT_VERSION
    result.kristal_version = result.kristal_version or tostring(Kristal.Version)
    result.tile_width = data.tile_width
    result.tile_height = data.tile_height
    result.tile_count = data.tile_count
    result.tile_columns = data.tile_columns
    result.tile_rows = data.tile_rows or (result.tile_columns and result.tile_columns > 0
        and math.ceil((result.tile_count or 0) / result.tile_columns) or 0)
    result.alignment = data.alignment
    result.render_size = data.render_size
    result.fill_mode = data.fill_mode
    result.tile_offset_x = data.tile_offset_x
    result.tile_offset_y = data.tile_offset_y
    result.image_width = data.image_width
    result.image_height = data.image_height
    result.transparent_color = data.transparent_color
    result.properties = nil
    local reason
    result.properties, reason = encodeOwnerProperties(data, { owner = data })
    if not result.properties then return nil, reason end
    result.tiles = {}
    for _, tile in ipairs(data.tiles or {}) do
        local encoded
        encoded, reason = encodeTile(tile, { tileset = result })
        if not encoded then return nil, reason end
        table.insert(result.tiles, encoded)
    end
    result.terrains = {}
    local terrain_ids = {}
    for _, terrain in ipairs(data.terrains or {}) do
        local encoded = copySerializable(terrain)
        encoded.id = EditorFormat.uniqueSlug(terrain.name or terrain.id, terrain_ids, "terrain")
        encoded.properties = nil
        encoded.properties, reason = encodeOwnerProperties(terrain, { tileset = result })
        if not encoded.properties then return nil, reason end
        encoded.terrain_variants = {}
        local variant_ids, variant_state = {}, { next_id = 1 }
        for _, variant in ipairs(terrain.terrain_variants or {}) do
            local encoded_variant = copySerializable(variant)
            encoded_variant.id = nextNumericId(variant.id, variant_ids, variant_state)
            encoded_variant.properties = nil
            encoded_variant.properties, reason = encodeOwnerProperties(variant, { tileset = result })
            if not encoded_variant.properties then return nil, reason end
            table.insert(encoded.terrain_variants, encoded_variant)
        end
        table.insert(result.terrains, encoded)
    end
    local valid, diagnostics = EditorFormat.validateTileset(result, options)
    if not valid then return nil, table.concat(diagnostics, "; ") end
    return EditorFormat.encodeJSON(result, "tileset", options)
end

function EditorFormat.decodeWorld(source, path, options)
    local data, reason = EditorFormat.decodeJSON(source, path)
    if not data then return nil, reason end
    data, reason = EditorFormat.migrateWorld(data)
    if not data then return nil, reason end
    local valid, diagnostics = EditorFormat.validateWorld(data, options)
    if not valid then return nil, table.concat(diagnostics, "; ") end
    local success
    success, reason = decodeOwnerProperties(data, { owner = data, path = path })
    if not success then return nil, reason end
    return data
end

function EditorFormat.encodeWorld(data, options)
    options = options or {}
    local result = copySerializable(data)
    result.version = EditorFormat.WORLD_FORMAT_VERSION
    result.kristal_version = result.kristal_version or tostring(Kristal.Version)
    result.properties = nil
    local reason
    result.properties, reason = encodeOwnerProperties(data, { owner = data })
    if not result.properties then return nil, reason end
    local valid, diagnostics = EditorFormat.validateWorld(result, options)
    if not valid then return nil, table.concat(diagnostics, "; ") end
    return EditorFormat.encodeJSON(result, "world", options)
end



local function checkVersion(data, label, current_version)
    local version = tonumber(data.version)
    if not version then return nil, label .. " is missing a numeric format version" end
    if version > current_version then
        return nil, string.format("%s format version %s is newer than supported version %s",
            label, version, current_version)
    end
    if version < current_version then
        return nil, string.format("No migration is registered for %s format version %s", label:lower(), version)
    end
    return data
end

function EditorFormat.migrateMap(data)
    return checkVersion(data, "Map", EditorFormat.MAP_FORMAT_VERSION)
end

function EditorFormat.migrateTileset(data)
    return checkVersion(data, "Tileset", EditorFormat.TILESET_FORMAT_VERSION)
end

function EditorFormat.migrateWorld(data)
    return checkVersion(data, "World", EditorFormat.WORLD_FORMAT_VERSION)
end

-- SECTION : Validation

---@return boolean? valid
---@return table|string? diagnostics
function EditorFormat.validateMap(data, options)
    local diagnostics = {}
    if type(data.width) ~= "number" or data.width < 0 then table.insert(diagnostics, "Map width must be non-negative") end
    if type(data.height) ~= "number" or data.height < 0 then table.insert(diagnostics, "Map height must be non-negative") end
    if type(data.grid_width) ~= "number" or data.grid_width <= 0 then table.insert(diagnostics, "Map grid_width must be positive") end
    if type(data.grid_height) ~= "number" or data.grid_height <= 0 then table.insert(diagnostics, "Map grid_height must be positive") end
    if type(data.layers) ~= "table" then table.insert(diagnostics, "Map layers must be an array") end
    if data.properties ~= nil and type(data.properties) ~= "table" then table.insert(diagnostics, "Map properties must be an array") end
    local layer_ids, object_ids = {}, {}
    local function validateObjects(objects, path)
        for index, object in ipairs(objects or {}) do
            local object_path = string.format("%s.objects[%d]", path, index)
            if type(object.id) ~= "number" or object.id < 1 or object.id % 1 ~= 0 then
                table.insert(diagnostics, object_path .. ".id must be a positive integer")
            elseif object_ids[object.id] then
                table.insert(diagnostics, object_path .. ".id duplicates object " .. tostring(object.id))
            else
                object_ids[object.id] = true
            end
        end
    end
    local function validateLayers(layers, path)
        for index, layer in ipairs(layers or {}) do
            local layer_path = string.format("%s[%d]", path, index)
            if type(layer.id) ~= "string" or layer.id == "" then
                table.insert(diagnostics, layer_path .. ".id must be a non-empty string")
            elseif layer_ids[layer.id] then
                table.insert(diagnostics, layer_path .. ".id duplicates layer '" .. layer.id .. "'")
            else
                layer_ids[layer.id] = true
            end
            if layer.kind == "group" then
                validateLayers(layer.layers, layer_path .. ".layers")
            elseif layer.kind == "object" then
                validateObjects(layer.objects, layer_path)
            end
        end
    end
    if type(data.layers) == "table" then validateLayers(data.layers, "layers") end
    return #diagnostics == 0, diagnostics
end

---@return boolean? valid
---@return table|string? diagnostics
function EditorFormat.validateTileset(data, options)
    local diagnostics = {}
    if type(data.tile_width) ~= "number" or data.tile_width <= 0 then table.insert(diagnostics, "Tileset tile_width must be positive") end
    if type(data.tile_height) ~= "number" or data.tile_height <= 0 then table.insert(diagnostics, "Tileset tile_height must be positive") end
    if type(data.tile_count) ~= "number" or data.tile_count < 0 then table.insert(diagnostics, "Tileset tile_count must be non-negative") end
    if data.image ~= nil and type(data.image) ~= "string" and type(data.image) ~= "table" then
        table.insert(diagnostics, "Tileset image must be a path or an array of paths")
    end
    if data.tiles ~= nil and type(data.tiles) ~= "table" then table.insert(diagnostics, "Tileset tiles must be an array") end
    for tile_index, tile in ipairs(data.tiles or {}) do
        local object_ids = {}
        for object_index, object in ipairs(tile.collision or {}) do
            local path = string.format("tiles[%d].collision[%d]", tile_index, object_index)
            if type(object.id) ~= "number" or object.id < 1 or object.id % 1 ~= 0 then
                table.insert(diagnostics, path .. ".id must be a positive integer")
            elseif object_ids[object.id] then
                table.insert(diagnostics, path .. ".id duplicates collision object " .. tostring(object.id))
            else
                object_ids[object.id] = true
            end
        end
        for frame_index, frame in ipairs(tile.frames or {}) do
            local path = string.format("tiles[%d].frames[%d]", tile_index, frame_index)
            if type(frame.tile_id) ~= "number" or frame.tile_id < 0 or frame.tile_id % 1 ~= 0 then
                table.insert(diagnostics, path .. ".tile_id must be a non-negative integer")
            end
            if type(frame.duration) ~= "number" or frame.duration <= 0 then
                table.insert(diagnostics, path .. ".duration must be positive milliseconds")
            end
        end
    end
    local terrain_ids = {}
    for terrain_index, terrain in ipairs(data.terrains or {}) do
        local path = string.format("terrains[%d]", terrain_index)
        if type(terrain.id) ~= "string" or terrain.id == "" then
            table.insert(diagnostics, path .. ".id must be a non-empty string")
        elseif terrain_ids[terrain.id] then
            table.insert(diagnostics, path .. ".id duplicates terrain '" .. terrain.id .. "'")
        else
            terrain_ids[terrain.id] = true
        end
        local variant_ids = {}
        for variant_index, variant in ipairs(terrain.terrain_variants or {}) do
            local variant_path = string.format("%s.terrain_variants[%d]", path, variant_index)
            if type(variant.id) ~= "number" or variant.id < 1 or variant.id % 1 ~= 0 then
                table.insert(diagnostics, variant_path .. ".id must be a positive integer")
            elseif variant_ids[variant.id] then
                table.insert(diagnostics, variant_path .. ".id duplicates variant " .. tostring(variant.id))
            else
                variant_ids[variant.id] = true
            end
        end
    end
    return #diagnostics == 0, diagnostics
end

function EditorFormat.validateWorld(data, options)
    local diagnostics = {}
    if type(data.maps) ~= "table" then
        table.insert(diagnostics, "World maps must be an array")
    else
        for index, entry in ipairs(data.maps) do
            if type(entry) ~= "table" or type(entry.map) ~= "string" then
                table.insert(diagnostics, string.format("World map entry %d requires a map id", index))
            elseif type(entry.x) ~= "number" or type(entry.y) ~= "number" then
                table.insert(diagnostics, string.format("World map entry %d requires numeric x/y", index))
            end
        end
    end
    return #diagnostics == 0, diagnostics
end

-- SECTION : Saving

---@return boolean success
---@return string? error
function EditorFormat.saveMapData(data, path, options)
    local encoded, reason = EditorFormat.encodeMap(data, options)
    if not encoded then return false, reason end
    return EditorFormat.writeFile(path, encoded, options)
end

---@return boolean success
---@return string? error
function EditorFormat.saveTilesetData(data, path, options)
    local encoded, reason = EditorFormat.encodeTileset(data, options)
    if not encoded then return false, reason end
    return EditorFormat.writeFile(path, encoded, options)
end

function EditorFormat.saveWorldData(data, path, options)
    local encoded, reason = EditorFormat.encodeWorld(data, options)
    if not encoded then return false, reason end
    return EditorFormat.writeFile(path, encoded, options)
end

function EditorFormat.writeFile(path, encoded, options)
    if type(path) ~= "string" or path == "" then return false, "A save path is required" end
    if options and options.writer then return options.writer(path, encoded, options) end
    local directory = FileSystemUtils.getDirname(path)
    if directory ~= "" then love.filesystem.createDirectory(directory) end
    local written, reason = love.filesystem.write(path, encoded)
    if not written then return false, reason or ("Could not write '" .. path .. "'") end
    return true
end



return EditorFormat
