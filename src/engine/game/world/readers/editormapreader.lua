---@class EditorMapReader : MapReader
---@overload fun(map: Map): EditorMapReader
local EditorMapReader, super = Class(MapReader)

EditorMapReader.FORMAT = "editor"
EditorMapReader.LEGACY_FORMAT = false
EditorMapReader.operations = MapReader.copyOperations()

function EditorMapReader:initialize(data)
    local map = self.map
    map.data = data
    map.full_map_path = data.full_path and FileSystemUtils.getDirname(data.full_path)
        or (Mod and Mod.info.path or "")
    map.tile_width = data.grid_width or 40
    map.tile_height = data.grid_height or 40
    map.width = data.width or 16
    map.height = data.height or 12
    map.name = data.name
    local properties = data.properties or {}
    map.music = properties.music
    map.keep_music = properties.keep_music
    map.light = properties.light or false
    map.border = properties.border
    map.bg_color = TableUtils.copy(data.background_color or { 0, 0, 0, 0 }, true)

    local added = {}
    MapUtils.walkLayers(data.layers, function(layer)
        if Registry.layer_types:getLayerKind(layer) == "tile" and layer.tileset and not added[layer.tileset] then
            map:addTileset(layer.tileset)
            added[layer.tileset] = true
        end
    end)
    MapUtils.walkObjects(data.layers, function(object)
        if object.tileset and not added[object.tileset] then
            map:addTileset(object.tileset)
            added[object.tileset] = true
        end
    end)
    return true
end

function EditorMapReader:read(data)
    local map = self.map
    local depth = map.depth_per_layer
    local object_depths, tile_depths = {}, {}
    local spawn_depth, battle_border_depth
    MapUtils.walkLayers(data.layers, function(layer)
        if Registry.layer_types:getLayerKind(layer) == "group" then
            return layer.visible ~= false
        elseif layer.visible ~= false then
            local layer_depth = layer._editor_depth_override or depth
            local type_id = layer._editor_type_id or layer.type
            local kind = Registry.layer_types:getLayerKind(layer)
            map.layers[layer.name] = layer_depth
            if kind == "object" then
                if layer.properties and layer.properties.spawn then spawn_depth = layer_depth end
                if type_id == "objects" then
                    table.insert(object_depths, layer_depth)
                end
            elseif kind == "tile" then
                if type_id == "battleborder" then
                    battle_border_depth = battle_border_depth or layer_depth
                else
                    table.insert(tile_depths, layer_depth)
                end
            end
            if not Kristal.callEvent(KRISTAL_EVENT.loadLayer, map, layer, layer_depth) then
                map:loadLayer(layer, layer_depth)
            end
            if not (layer.properties and layer.properties.thin) then depth = depth + map.depth_per_layer end
        end
    end)

    map.object_layer = spawn_depth
    map.object_layer = map.object_layer or object_depths[#object_depths] or 1

    map.tile_layer = 0
    for _, tile_depth in ipairs(tile_depths) do
        if tile_depth < map.object_layer and tile_depth > map.tile_layer then
            map.tile_layer = tile_depth
        end
    end
    map.battle_fader_layer = battle_border_depth
        and (battle_border_depth - map.depth_per_layer / 2)
        or (map.object_layer - map.depth_per_layer / 2)

    for _, object in ipairs(map.events) do
        local assignments = object.data and (object.data.__editor_fx or object.data.fx) or {}
        for _, assignment in ipairs(assignments) do
            local fx, id_or_reason = Registry.createRuntimeDrawFX(assignment, {
                map = map,
                object = object,
                resolveObjectReference = function(value)
                    local reference = EditorObjectReference.from(value, map.id)
                    if reference.map_id and reference.map_id ~= map.id then return nil end
                    return map:getEvent(reference.object_id)
                end
            })
            if not fx then
                error(string.format("Could not load DrawFX on map object %s: %s",
                    tostring(object.object_id or object.data.id), tostring(id_or_reason)), 2)
            end
            object:addFX(fx, id_or_reason)
        end
    end
    map.next_layer = depth
    return true
end

function EditorMapReader.operations.loadMapData(map, data)
    return map.reader:read(data)
end

function EditorMapReader.operations.getLayerClassOrName(map, layer)
    return layer._editor_type_id or layer.name
end

function EditorMapReader.operations.isLayerType(map, layer, type_id)
    return layer._editor_type_id == type_id
end

function EditorMapReader.operations.createTileLayer(map, layer)
    local runtime_layer = TableUtils.copy(layer, true)
    runtime_layer.width = map.width
    runtime_layer.height = map.height
    runtime_layer.encoding = "lua"
    runtime_layer.data = {}
    for index = 1, map.width * map.height do runtime_layer.data[index] = 0 end

    local tileset, first_gid = map:getTileset(layer.tileset)
    if not tileset then error("No tileset with id '" .. tostring(layer.tileset) .. "'", 2) end
    local current_rows = math.ceil(tileset.tile_count / math.max(1, tileset.columns))
    local size = EditorFormat.CHUNK_SIZE
    for _, chunk in ipairs(layer.chunks or {}) do
        for index, packed in ipairs(chunk.tile_data or {}) do
            local tile_id, flip_x, flip_y, rotated = EditorFormat.unpackTile(packed)
            if tile_id ~= nil then
                tile_id = EditorFormat.remapTileId(tile_id, layer.tileset_columns, layer.tileset_rows,
                    tileset.columns, current_rows)
                local x = (chunk.x or 0) + ((index - 1) % size)
                local y = (chunk.y or 0) + math.floor((index - 1) / size)
                if tile_id ~= nil and x >= 0 and y >= 0 and x < map.width and y < map.height then
                    local gid = first_gid + tile_id
                    if flip_x then gid = bit.bor(gid, EditorFormat.TILE_FLIP_HORIZONTAL) end
                    if flip_y then gid = bit.bor(gid, EditorFormat.TILE_FLIP_VERTICAL) end
                    if rotated then gid = bit.bor(gid, EditorFormat.TILE_ROTATE) end
                    runtime_layer.data[x + y * map.width + 1] = gid
                end
            end
        end
    end
    return TileLayer(map, runtime_layer)
end

function EditorMapReader.operations.loadLayer(map, layer, depth)
    local kind = Registry.layer_types:getLayerKind(layer)
    local layer_type = Registry.getLayerType(layer._editor_type_id or layer.type)
    if layer_type and layer_type.load then
        return layer_type.load(map, layer, depth, map.reader, layer_type)
    end
    if kind == "tile" then
        if not layer.tileset and #(layer.chunks or {}) == 0 then return end
        return map:loadTiles(layer, depth)
    elseif kind == "image" then
        return map:loadImage(layer, depth)
    elseif kind == "object" then
        return map:loadShapes(layer)
    end
end

function EditorMapReader.operations.loadTextureFromImagePath(map, filename)
    local texture, resolved_id = Assets.resolveTextureReference(filename)
    if texture then return true, resolved_id end
    return false, "Could not resolve map image asset '" .. tostring(filename) .. "'"
end

function EditorMapReader.convertLegacyData(data, options)
    return TiledEditorFormatConverter.convertMap(data, options)
end

function EditorMapReader.saveData(data, path, options)
    return EditorFormat.saveMapData(data, path, options)
end

function EditorMapReader:save(path, options)
    return EditorFormat.saveMapData(self.map.data, path, options)
end

return EditorMapReader
