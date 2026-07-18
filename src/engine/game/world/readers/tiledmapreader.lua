--- Loads legacy Tiled maps into the game world.
---@class TiledMapReader : MapReader
---@overload fun(map: Map): TiledMapReader
local TiledMapReader, super = Class(MapReader)

TiledMapReader.FORMAT = "tiled"
TiledMapReader.LEGACY_FORMAT = true

local operations = MapReader.copyOperations()
TiledMapReader.operations = operations

function TiledMapReader:initialize(data)
    local map = self.map

    if data.full_path then
        local split_map_path = StringUtils.split(data.full_path, "/")
        map.full_map_path = table.concat(split_map_path, "/", 1, #split_map_path - 1)
    end

    map.tile_width = data.tilewidth or 40
    map.tile_height = data.tileheight or 40
    map.width = data.width or 16
    map.height = data.height or 12

    map.name = data.properties and data.properties["name"]
    map.music = data.properties and data.properties["music"]
    map.keep_music = data.properties and data.properties["keepmusic"]
    map.light = data.properties and data.properties["light"] or false
    map.border = data.properties and data.properties["border"]

    if data.backgroundcolor then
        local bgc = data.backgroundcolor
        map.bg_color = { bgc[1] / 255, bgc[2] / 255, bgc[3] / 255, (bgc[4] or 255) / 255 }
    end

    map:populateTilesets(data.tilesets or {})
end

function TiledMapReader:read(data)
    return self:call("loadMapData", data)
end

--- Always saves as the editor format, cause i don't really wanna write a legacy saver...
function TiledMapReader:save(path, options)
    local data, reason = EditorMapReader.convertLegacyData(self.map.data, options)
    if not data then return false, reason end
    return EditorMapReader.saveData(data, path, options)
end

function operations.loadMapData(self, data)
    local tile_depths = {}
    local indexed_layers = {}
    local has_battle_border = false
    local layers = TiledUtils.flattenLayers(data.layers)

    for i, layer in ipairs(layers) do
        self.layers[layer.name] = self.next_layer
        indexed_layers[i] = self.next_layer
        if not (layer.properties and layer.properties.thin) then
            self.next_layer = self.next_layer + self.depth_per_layer
        end
    end

    for i, layer in ipairs(layers) do
        local depth = indexed_layers[i]
        if not has_battle_border and self:isLayerType(layer, "battleborder") then
            self.battle_fader_layer = depth - (self.depth_per_layer / 2)
            has_battle_border = true
        end
        if layer.type == "tilelayer" and not self:isLayerType(layer, "battleborder") then
            table.insert(tile_depths, depth)
        end
        if not Kristal.callEvent(KRISTAL_EVENT.loadLayer, self, layer, depth) then
            self:loadLayer(layer, depth)
        end
    end

    local spawn_layer = TiledUtils.getSpawnLayer(layers,
        function(layer, type_id) return self:isLayerType(layer, type_id) end,
        function(layer) return self:getLayerClassOrName(layer) end)
    self.object_layer = spawn_layer and indexed_layers[spawn_layer] or 1

    -- Set the tile layer depth to the closest tile layer below the object layer
    self.tile_layer = 0
    for _, depth in ipairs(tile_depths) do
        if depth >= self.object_layer then break end

        self.tile_layer = depth
    end

    -- If no battleborder layer, set the battle fader layer depth to be below the object layer
    if not has_battle_border then
        self.battle_fader_layer = self.object_layer - (self.depth_per_layer / 2)
    end
end

function operations.getLayerClassOrName(self, layer)
    return TiledUtils.getLayerClassOrName(layer)
end

function operations.isLayerType(self, layer, type)
    return TiledUtils.isLayerType(layer, type)
end

function operations.getObjectType(self, data)
    if type(data.type) == "string" and data.type ~= "" then return data.type end
    if type(data.class) == "string" and data.class ~= "" then return data.class end
    if type(data.name) == "string" and data.name ~= "" then return data.name end
    return nil
end

function operations.loadLayer(self, layer, depth)
    if layer.type == "tilelayer" then
        self:loadTiles(layer, depth)
    elseif layer.type == "imagelayer" then
        self:loadImage(layer, depth)
    elseif layer.type == "objectgroup" then
        if self:isLayerType(layer, "objects") then
            self:loadObjects(layer, depth, "events")
        elseif self:isLayerType(layer, "controllers") then
            self:loadObjects(layer, depth, "controllers")
        elseif self:isLayerType(layer, "markers") then
            self:loadMarkers(layer)
        elseif self:isLayerType(layer, "collision") then
            self:loadCollision(layer)
        elseif self:isLayerType(layer, "enemycollision") then
            self:loadEnemyCollision(layer)
        elseif self:isLayerType(layer, "blockcollision") then
            self:loadBlockCollision(layer)
        elseif self:isLayerType(layer, "paths") then
            self:loadPaths(layer)
        elseif self:isLayerType(layer, "battleareas") then
            self:loadBattleAreas(layer)
        end
        self:loadShapes(layer)
    else
        Kristal.Console:warn(string.format("Unhandled or unknown Tiled layer type \"%s\", ignoring", layer.type))
    end
end

function operations.createTileLayer(self, data)
    assert(data.encoding == "lua", "Tile layer format \"" .. tostring(data.encoding)
        .. "\" is not supported. Please set the format to CSV in the map properties.")
    return TileLayer(self, data)
end

function operations.loadTextureFromImagePath(self, filename)
    return TiledUtils.resolveImageAsset(filename, self.full_map_path)
end

function operations.populateTilesets(self, data)
    self.tilesets = {}
    for _, tileset_data in ipairs(data) do
        local tileset
        local filename = tileset_data.exportfilename or tileset_data.filename
        if filename then
            local success, result = self:loadTilesetFromTilesetPath(filename)
            if not success then
                error("Map \"" .. self.data.id .. "\" failed to load tileset \"" .. tostring(tileset_data.name) .. "\"\n" .. result)
            end
            tileset = result
        else
            tileset = Tileset(tileset_data, self.full_map_path .. "/" .. self.data.id, self.full_map_path)
        end
        table.insert(self.tilesets, tileset)
        local gid = tileset_data.firstgid or (self.max_gid + 1)
        self.tileset_gids[tileset] = gid
        self.max_gid = math.max(self.max_gid, gid + tileset.id_count - 1)
    end
end

function operations.loadTilesetFromTilesetPath(self, filename)
    local tileset_dir = "scripts/world/tilesets"
    local success, result, final_path = TiledUtils.relativePathToAssetId(tileset_dir, filename, self.full_map_path)

    if not success then
        if result == "not under prefix" then
            return false, "Tileset not found in \"" .. tileset_dir .. "\" (Got path \"" .. final_path .. "\")"
        elseif result == "path outside root" then
            return false, "Tileset path located outside Kristal (Got path \"<kristal>/" .. final_path .. "\")"
        else
            return false, "Unknown reason"
        end
    end

    local tileset = Registry.getTileset(result)

    if not tileset then
        return false, "No tileset found with id \"" .. result .. "\""
    end

    return true, tileset
end

return TiledMapReader
