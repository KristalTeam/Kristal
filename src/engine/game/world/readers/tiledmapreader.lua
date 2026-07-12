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
    local object_depths = {}
    local tile_depths = {}
    local indexed_layers = {}
    local has_battle_border = false

    local layers = {}

    local function loadLayer(layer)
        if layer.type ~= "group" then
            table.insert(layers, layer)
        else
            for i, sublayer in ipairs(layer.layers) do
                local sublayer_copy = TableUtils.copy(sublayer)
                sublayer_copy.properties = TableUtils.mergeMany(layer.properties, sublayer_copy.properties)
                if i == #layer.layers then
                    sublayer_copy.properties.thin = sublayer.properties.thin
                end
                sublayer_copy.offsetx = (sublayer.offsetx or 0) + (layer.offsetx or 0)
                sublayer_copy.offsety = (sublayer.offsety or 0) + (layer.offsety or 0)
                sublayer_copy.parallaxx = (sublayer.parallaxx or 1) * (layer.parallaxx or 1)
                sublayer_copy.parallaxy = (sublayer.parallaxy or 1) * (layer.parallaxy or 1)
                loadLayer(sublayer_copy)
            end
        end
    end

    for _, layer in ipairs(data.layers or {}) do
        loadLayer(TableUtils.copy(layer))
    end

    for i, layer in ipairs(layers) do
        self.layers[layer.name] = self.next_layer
        indexed_layers[i] = self.next_layer
        if not (layer.properties and layer.properties.thin) then
            self.next_layer = self.next_layer + self.depth_per_layer
        end
    end

    self.object_layer = nil
    for i, layer in ipairs(layers) do
        local depth = indexed_layers[i]
        if not has_battle_border and self:isLayerType(layer, "battleborder") then
            self.battle_fader_layer = depth - (self.depth_per_layer / 2)
            has_battle_border = true
        end
        if layer.type == "objectgroup" and self:isLayerType(layer, "objects") then
            table.insert(object_depths, depth)
            if layer.properties["spawn"] then
                self.object_layer = depth
            end
        end
        if layer.type == "tilelayer" and not self:isLayerType(layer, "battleborder") then
            table.insert(tile_depths, depth)
        end
        if not Kristal.callEvent(KRISTAL_EVENT.loadLayer, self, layer, depth) then
            self:loadLayer(layer, depth)
        end
    end

    -- old behavior, ideally should not be used
    if not self.object_layer then
        self.object_layer = 1
        local priority_object_layer = nil
        local has_markers_layer = false
        for i, layer in ipairs(layers) do
            local depth = indexed_layers[i]
            if layer.type == "objectgroup" then
                if self:isLayerType(layer, "markers") then
                    has_markers_layer = true
                    priority_object_layer = nil
                    if #object_depths == 0 then
                        -- If there are no object layers, set the object depth to the marker layer's depth
                        self.object_layer = depth
                    else
                        -- Otherwise, set the object depth to the closest object layer's depth
                        local closest
                        for _, obj_depth in ipairs(object_depths) do
                            if not closest then
                                closest = obj_depth
                            elseif math.abs(depth - obj_depth) <= math.abs(depth - closest) then
                                closest = obj_depth
                            else
                                break
                            end
                        end
                        self.object_layer = closest or depth
                    end
                elseif self:getLayerClassOrName(layer):lower() == "objects_party" then
                    priority_object_layer = depth
                    break -- always use 'objects_party' if available
                elseif not has_markers_layer then
                    -- If there is no markers layer, set the object layer to the highest object layer
                    if self:isLayerType(layer, "objects") then
                        priority_object_layer = depth
                    end
                    self.object_layer = depth
                end
            end
        end
        -- If no marker layers, prioritize object layers without a custom name
        if priority_object_layer then
            self.object_layer = priority_object_layer
        end
    end

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
    if layer.class ~= nil and layer.class ~= "" then
        return layer.class
    end

    return layer.name
end

function operations.isLayerType(self, layer, type)
    if layer.class ~= nil and layer.class ~= "" then
        -- If there's a defined class, check that
        return layer.class == type
    end

    -- If there isn't a class, use the name
    return StringUtils.startsWith(layer.name:lower(), type)
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
    local image_dir = "assets/sprites"
    local success, result, final_path = TiledUtils.relativePathToAssetId(image_dir, filename, self.full_map_path)

    if not success then
        if result == "not under prefix" then
            return false, "Image not found in \"" .. image_dir .. "\" (Got path \"" .. final_path .. "\")"
        elseif result == "path outside root" then
            return false, "Image path located outside Kristal (Got path \"<kristal>/" .. final_path .. "\")"
        else
            return false, "Unknown reason"
        end
    end

    return true, result
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
