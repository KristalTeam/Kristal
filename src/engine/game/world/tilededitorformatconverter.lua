---@class TiledEditorFormatConverter
local TiledEditorFormatConverter = {}

local function getTiledTilesetId(reference, map_data)
    if reference.name and Registry.getTileset(reference.name) then return reference.name end
    local filename = reference.exportfilename or reference.filename
    if filename then
        local base_dir = map_data.full_path and FileSystemUtils.getDirname(map_data.full_path) or ""
        local success, id = TiledUtils.relativePathToAssetId("scripts/world/tilesets", filename, base_dir)
        if success and Registry.getTileset(id) then return id end
    end
    return reference.name
end

local function getTiledTilesetReferences(map_data)
    local references = {}
    for _, source in ipairs(map_data.tilesets or {}) do
        local id = getTiledTilesetId(source, map_data)
        local tileset = id and Registry.getTileset(id)
        table.insert(references, {
            id = id,
            first_gid = source.firstgid or 1,
            columns = tileset and tileset.columns or source.columns,
            rows = tileset and math.ceil(tileset.tile_count / math.max(1, tileset.columns))
                or source.columns and math.ceil((source.tilecount or 0) / math.max(1, source.columns)),
            count = tileset and tileset.id_count or source.tilecount
        })
    end
    table.sort(references, function(a, b) return a.first_gid < b.first_gid end)
    return references
end

local function resolveTiledGid(gid, references)
    local tile_gid, flip_x, flip_y, rotated = TiledUtils.parseTileGid(gid)
    if tile_gid == 0 then return nil end
    local reference
    for _, candidate in ipairs(references) do
        if candidate.first_gid <= tile_gid then reference = candidate else break end
    end
    if not reference or not reference.id then return nil, "Could not resolve Tiled GID " .. tostring(tile_gid) end
    local tile_id = tile_gid - reference.first_gid
    if reference.count and tile_id >= reference.count then
        return nil, string.format("Tiled GID %d is outside tileset '%s'", tile_gid, reference.id)
    end
    return reference, EditorFormat.packTile(tile_id, flip_x, flip_y, rotated)
end

local function iterateTiledLayerTiles(layer, callback)
    if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
            local width = chunk.width or EditorFormat.CHUNK_SIZE
            for index, gid in ipairs(chunk.data or {}) do
                callback((chunk.x or 0) + ((index - 1) % width),
                    (chunk.y or 0) + math.floor((index - 1) / width), gid)
            end
        end
        return
    end
    local width = layer.width or 0
    for index, gid in ipairs(layer.data or {}) do
        callback((layer.x or 0) + ((index - 1) % width),
            (layer.y or 0) + math.floor((index - 1) / width), gid)
    end
end

local function convertTiledTileLayer(layer, references)
    local splits, split_order = {}, {}
    local function getSplit(reference)
        local split = splits[reference.id]
        if split then return split end
        split = TableUtils.copy(layer, true)
        TableUtils.clearFields(split, { "data", "encoding", "chunks", "width", "height" })
        split._editor_type_id = Registry.layer_types:getLegacyTiledType(layer).id
        split._editor_kind_id = "tile"
        split.kind = "tile"
        split.x = layer.offsetx or 0
        split.y = layer.offsety or 0
        split.tileset = reference.id
        split.tileset_columns = reference.columns
        split.tileset_rows = reference.rows
        split.chunks = {}
        split._chunks_by_position = {}
        splits[reference.id] = split
        table.insert(split_order, split)
        return split
    end
    local function setTile(split, x, y, packed)
        local size = EditorFormat.CHUNK_SIZE
        local chunk_x = math.floor(x / size) * size
        local chunk_y = math.floor(y / size) * size
        local key = chunk_x .. ":" .. chunk_y
        local chunk = split._chunks_by_position[key]
        if not chunk then
            chunk = { x = chunk_x, y = chunk_y, tile_data = {} }
            for index = 1, size * size do chunk.tile_data[index] = 0 end
            split._chunks_by_position[key] = chunk
            table.insert(split.chunks, chunk)
        end
        chunk.tile_data[(x - chunk_x) + (y - chunk_y) * size + 1] = packed
    end

    local conversion_error
    iterateTiledLayerTiles(layer, function(x, y, gid)
        if conversion_error or gid == 0 then return end
        local reference, packed = resolveTiledGid(gid, references)
        if not reference then conversion_error = packed return end
        setTile(getSplit(reference), x, y, packed)
    end)
    if conversion_error then return nil, conversion_error end
    if #split_order == 0 and references[1] then getSplit(references[1]) end
    if #split_order == 0 then return nil, "Tile layer has no resolvable tileset" end

    for index, split in ipairs(split_order) do
        split._chunks_by_position = nil
        table.sort(split.chunks, function(a, b) return a.y == b.y and a.x < b.x or a.y < b.y end)
        if #split_order > 1 then
            split.name = index == 1 and layer.name or string.format("%s [%s]", layer.name or "Tiles", split.tileset)
            split.id = index == 1 and layer.id or tostring(layer.id or "layer") .. ":" .. split.tileset
            split.properties = TableUtils.copy(layer.properties or {}, true)
            if index < #split_order then split.properties.thin = true end
        end
    end
    return split_order
end

---@return table? data
---@return string? error
function TiledEditorFormatConverter.convertMap(data, options)
    local converted = TableUtils.copy(data, true)
    converted.version = EditorFormat.TILED_MAP_CONVERSION_VERSION
    converted.kristal_version = tostring(Kristal.Version)
    converted.grid_width = data.tilewidth or 40
    converted.grid_height = data.tileheight or 40
    converted.background_color = data.backgroundcolor
    converted.name = converted.name or converted.properties and converted.properties.name
    if converted.properties then
        converted.properties.name = nil
        converted.properties.keep_music = converted.properties.keep_music or converted.properties.keepmusic
        converted.properties.keepmusic = nil
    end
    converted.tilewidth, converted.tileheight, converted.backgroundcolor = nil, nil, nil
    local references = getTiledTilesetReferences(data)
    local spawn_layer = TiledUtils.getSpawnLayer(TiledUtils.flattenLayers(converted.layers, true))
    if spawn_layer and spawn_layer._tiled_source then
        spawn_layer._tiled_source.properties = spawn_layer._tiled_source.properties or {}
        spawn_layer._tiled_source.properties.spawn = true
    end
    local function convertTileObject(object)
        if not object.gid then return true end
        local reference, packed = resolveTiledGid(object.gid, references)
        if not reference then return false, packed end
        local tile_id, flip_x, flip_y, rotated = EditorFormat.unpackTile(packed)
        if rotated then
            if flip_x == flip_y then flip_x = not flip_x else flip_y = not flip_y end
            object.rotation = (object.rotation or 0) - 90
        end
        object.tileset = reference.id
        object.tile_id = tile_id
        object.flip_x = flip_x or nil
        object.flip_y = flip_y or nil
        object.gid = nil
        return true
    end
    local function convertLayers(layers)
        local result = {}
        for _, layer in ipairs(layers or {}) do
            if layer.type == "group" then
                layer._editor_type_id = "folder"
                layer._editor_kind_id = "group"
                layer.kind = "group"
                layer.x = layer.offsetx or 0
                layer.y = layer.offsety or 0
                local children, child_reason = convertLayers(layer.layers)
                if not children then return nil, child_reason end
                layer.layers = children
                table.insert(result, layer)
            elseif layer.type == "tilelayer" then
                local split_layers, reason = convertTiledTileLayer(layer, references)
                if not split_layers then return nil, reason end
                for _, split in ipairs(split_layers) do table.insert(result, split) end
            else
                local layer_type = Registry.layer_types:getLegacyTiledType(layer)
                layer._editor_type_id = layer_type.id
                layer._editor_kind_id = layer_type.kind
                layer.kind = layer_type.kind
                layer.x = layer.offsetx or 0
                layer.y = layer.offsety or 0
                for _, object in ipairs(layer.objects or {}) do
                    object.type = Registry.layer_types:getLegacyTiledObjectType(layer, object)
                        or object.type or ""
                    local success, object_reason = convertTileObject(object)
                    if not success then return nil, object_reason end
                end
                table.insert(result, layer)
            end
        end
        return result
    end
    local converted_layers, reason = convertLayers(converted.layers)
    if not converted_layers then return nil, reason end
    converted.layers = converted_layers
    if Registry.editor_events then
        MapUtils.walkObjects(converted.layers, function(object)
            Registry.createEditorEvent(object.type, object, { map_id = converted.id })
        end)
    end
    return EditorFormat.migrateMap(converted)
end

---@return table? data
---@return string? error
function TiledEditorFormatConverter.convertTileset(data, options)
    local converted = TableUtils.copy(data, true)
    local id_count = data.tilecount or 0
    for _, tile in ipairs(data.tiles or {}) do
        id_count = math.max(id_count, (tonumber(tile.id) or -1) + 1)
    end
    converted.version = EditorFormat.TILED_TILESET_CONVERSION_VERSION
    converted.kristal_version = tostring(Kristal.Version)
    converted.tile_width = data.tilewidth
    converted.tile_height = data.tileheight
    converted.tile_count = id_count
    converted.tile_columns = data.columns
    converted.tile_rows = data.columns and data.columns > 0 and math.ceil(id_count / data.columns) or 0
    converted.alignment = data.objectalignment
    converted.render_size = data.tilerendersize
    converted.fill_mode = data.fillmode
    converted.tile_offset_x = data.tileoffset and data.tileoffset.x
    converted.tile_offset_y = data.tileoffset and data.tileoffset.y
    if data.transformations then
        converted.transform_rules = {
            can_hflip = data.transformations.hflip,
            can_vflip = data.transformations.vflip,
            can_rotate = data.transformations.rotate,
            prefer_untransformed = data.transformations.preferuntransformed
        }
    end
    if not data.image and id_count > 0 then
        local images = {}
        for index = 1, id_count do images[index] = "" end
        local has_images = false
        for _, tile in ipairs(data.tiles or {}) do
            if tile.image then
                images[tile.id + 1] = tile.image
                has_images = true
            end
        end
        if has_images then converted.image = images end
    end
    converted.terrains = {}
    local terrain_ids = {}
    for terrain_index, wangset in ipairs(data.wangsets or {}) do
        local terrain = {
            id = EditorFormat.uniqueSlug(wangset.name or wangset.id, terrain_ids,
                "terrain_" .. terrain_index),
            name = wangset.name,
            tile_icon = wangset.tile and wangset.tile >= 0 and wangset.tile or nil,
            properties = TableUtils.copy(wangset.properties or {}, true),
            __editor_property_types = TableUtils.copy(wangset.__editor_property_types or {}, true),
            terrain_variants = {},
            terrain_tiles = {}
        }
        for variant_index, color in ipairs(wangset.wangcolors or wangset.colors or {}) do
            table.insert(terrain.terrain_variants, {
                id = variant_index,
                name = color.name,
                color = color.color,
                tile_icon = color.tile and color.tile >= 0 and color.tile or nil,
                probability = color.probability,
                properties = TableUtils.copy(color.properties or {}, true),
                __editor_property_types = TableUtils.copy(color.__editor_property_types or {}, true)
            })
        end
        for _, wangtile in ipairs(wangset.wangtiles or {}) do
            local wang_id = wangtile.wangid or {}
            local counts, center, center_count = {}, nil, 0
            for _, variant_id in ipairs(wang_id) do
                if variant_id and variant_id > 0 then
                    counts[variant_id] = (counts[variant_id] or 0) + 1
                    if counts[variant_id] > center_count then
                        center, center_count = variant_id, counts[variant_id]
                    end
                end
            end
            local offsets = {
                { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 },
                { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }
            }
            local conditions = {}
            for index, offset in ipairs(offsets) do
                table.insert(conditions, {
                    type = "terrain", x = offset[1], y = offset[2],
                    terrain = wang_id[index] or 0
                })
            end
            if center then
                table.insert(terrain.terrain_tiles, {
                    tile_id = wangtile.tileid,
                    terrain = center,
                    conditions = conditions
                })
            end
        end
        table.insert(converted.terrains, terrain)
    end
    TableUtils.clearFields(converted, {
        "tilewidth", "tileheight", "tilecount", "columns", "objectalignment", "tilerendersize",
        "fillmode", "tileoffset", "imagewidth", "imageheight", "transparentcolor", "grid",
        "wangsets", "transformations", "tiledversion", "class", "__tileset_reader"
    })
    return EditorFormat.migrateTileset(converted)
end

return TiledEditorFormatConverter
