--- Stores and manages the currently loaded map. \
--- If a map in `scrips/world/maps` is defined as a folder, map data can be placed in `data.lua`, and a file named `map.lua` can be used to define a custom `Map` object for that map.
---@class Map : Class
---@overload fun(...) : Map
local Map = Class()

---@param world? World
---@param data? table
function Map:init(world, data)
    self.world = world or Game.world

    self.data = data

    self.full_map_path = Mod and Mod.info.path or ""
    self.tile_width = 40
    self.tile_height = 40
    self.width = 16
    self.height = 12
    self.name = nil
    self.music = nil
    self.keep_music = nil
    self.light = false
    self.border = nil
    self.bg_color = { 0, 0, 0, 0 }

    self.tilesets = {}
    self.tileset_gids = {}
    self.max_gid = 0

    self.collision = {}
    self.enemy_collision = {}
    self.block_collision = {}
    self.tile_layers = {}
    self.image_layers = {}
    self.shape_layers = {}
    self.markers = {}
    self.markers_by_id = {}
    self.battle_areas = {}
    self.battle_borders = {}
    self.paths = {}

    self.events = {}
    self.events_by_name = {}
    self.events_by_id = {}
    self.events_by_layer = {}

    self.shapes_by_id = {}
    self.shapes_by_name = {}

    self.hitboxes_by_id = {}
    self.hitboxes_by_name = {}

    local reader_class = self.reader_class or (data and data.__map_reader) or TiledMapReader
    assert(isClass(reader_class) and reader_class:includes(MapReader),
        "Map reader must be a MapReader class")
    self.reader = reader_class(self)

    if data then
        self.reader:initialize(data)
    end

    self.depth_per_layer = 0.1 -- its not perfect, but i doubt anyone will have 1000 layers
    self.next_layer = self.depth_per_layer

    self.next_object_id = 0

    self.object_layer = 1
    self.battle_fader_layer = 0.5
    self.tile_layer = 0
    self.layers = {}

    self.timer = Timer()
end

function Map:load()
    Game:setLight(self.light)

    self.world:addChild(self.timer)
    if self.data then
        self.reader:read(self.data)
    end
    for _, event in ipairs(self.events) do
        if event.onLoad then
            event:onLoad()
        end
    end
end

function Map:save(path, options)
    return self.reader:save(path, options)
end

function Map:onEnter() end
function Map:onExit() end

function Map:onFootstep(char, num) end

function Map:onGameOver() end

function Map:update() end
function Map:draw() end

function Map:getBorder(dark_transition)
    if self.border then
        return self.border
    elseif dark_transition then
        return self.light and "leaves" or "castle"
    end
end

function Map:getUniqueID()
    return "#" .. self.id
end

function Map:setFlag(flag, value)
    local uid = self:getUniqueID()
    Game:setFlag(uid .. ":" .. flag, value)
end

function Map:getFlag(flag, default)
    local uid = self:getUniqueID()
    return Game:getFlag(uid .. ":" .. flag, default)
end

function Map:addFlag(flag, amount)
    local uid = self:getUniqueID()
    return Game:addFlag(uid .. ":" .. flag, amount)
end

--- Gets a specific marker from the current map.
---@param id KristalObjectRef The name of the marker to search for, the unique numerical ID, or a Tiled object reference.
---@return number x The x-coordinate of the marker's center (or the center of the map if it doesn't exist).
---@return number y The y-coordinate of the marker's center (or the center of the map if it doesn't exist).
---@return Marker? marker The full marker data.
function Map:getMarker(id)
    local marker

    if type(id) == "table" then
        local map_id = id.map_id or id.map
        if map_id and map_id ~= self.id then
            return (self.width * self.tile_width / 2), (self.height * self.tile_height / 2), nil
        end
        local object_id = id.object_id or id.object or id.id
        if object_id ~= nil then
            marker = self.markers_by_id[object_id]
        end
    elseif type(id) == "number" then
        marker = self.markers_by_id[id]
    else
        marker = self.markers[id]
    end

    if marker == nil then
        return (self.width * self.tile_width / 2), (self.height * self.tile_height / 2), nil
    end

    return marker.center_x, marker.center_y, marker
end

--- Checks if a marker exists.
---@param id string|integer|TiledObjectRef The name of the marker to search for, or the unique numerical ID.
function Map:hasMarker(id)
    if type(id) == "table" then
        local map_id = id.map_id or id.map
        if map_id and map_id ~= self.id then return false end
        local object_id = id.object_id or id.object or id.id
        if object_id ~= nil then
            return self.markers_by_id[object_id] ~= nil
        end
    elseif type(id) == "number" then
        return self.markers_by_id[id] ~= nil
    end

    return self.markers[id] ~= nil
end

function Map:getPath(name)
    return self.paths[name]
end

function Map:addTileset(id)
    local tileset = Registry.getTileset(id)
    if tileset then
        table.insert(self.tilesets, tileset)
        self.tileset_gids[tileset] = self.max_gid + 1
        self.max_gid = self.max_gid + tileset.tile_count
        return tileset
    else
        error("No tileset with id '" .. id .. "'")
    end
end

function Map:getTile(x, y, layer)
    local tile_layer = self:getTileLayer(layer)

    if tile_layer then
        return tile_layer:getTile(x, y)
    else
        return nil, 0
    end
end

function Map:setTile(x, y, tileset, ...)
    local args = { ... }

    local tile_layer
    if type(args[#args]) == "string" then
        tile_layer = self:getTileLayer(args[#args])
        table.remove(args, #args)
    else
        tile_layer = self:getTileLayer()
    end

    tile_layer:setTile(x, y, tileset, unpack(args))
end

--- Gets a specific event present in the current map.
---
--- If multiple objects are found (if you pass in a name), only the first will be returned. Use `Map:getEvents` to get all of them.
---@see Map.getEvents
---@param id string|integer|TiledObjectRef The name of the event, the unique numerical ID, or a Tiled object reference.
---@return Event? event The event instance, if found.
function Map:getEvent(id)
    if type(id) == "table" then
        local object_id = id.object_id or id.object or id.id
        if object_id ~= nil then
            return self.events_by_id[object_id]
        end
    elseif type(id) == "number" then
        return self.events_by_id[id]
    else
        if self.events_by_name[id] then
            return self.events_by_name[id][1]
        end
    end
end

--- Gets a list of all instances of one type of event in the current maps
---@param name? string The text id of the event to search for, fetches every event if `nil`
---@return Event[] events A table containing every instance of the event in the current map
function Map:getEvents(name)
    if name then
        return self.events_by_name[name] or {}
    else
        return self.events
    end
end

function Map:getShape(id)
    if type(id) == "number" then
        return self.shapes_by_id[id]
    else
        if self.shapes_by_name[id] then
            return self.shapes_by_name[id][1]
        end
    end
end

function Map:getHitbox(id)
    if type(id) == "number" then
        return self.hitboxes_by_id[id]
    else
        if self.hitboxes_by_name[id] then
            return self.hitboxes_by_name[id][1]
        end
    end
end

function Map:getImageLayer(id)
    return self.image_layers[id]
end

function Map:getShapeLayer(name)
    return self.shape_layers[name]
end

function Map:getShapes(layer_prefix)
    local result = {}
    for k, v in pairs(self.shape_layers) do
        if not layer_prefix or StringUtils.startsWith(k:lower(), layer_prefix) then
            TableUtils.merge(result, v.objects)
        end
    end
    return result
end

function Map:getTileLayer(name)
    if name then
        for _, layer in ipairs(self.tile_layers) do
            if layer.name == name then
                return layer
            end
        end
    else
        return self.tile_layers[1]
    end
end

function Map:addTileLayer(depth, battle_border)
    local tilelayer = TileLayer(self)
    tilelayer.layer = depth or self.next_layer
    self.world:addChild(tilelayer)
    table.insert(self.tile_layers, tilelayer)
    if battle_border then
        table.insert(self.battle_borders, tilelayer)
    end
    if not depth then
        self.next_layer = self.next_layer + self.depth_per_layer
    end
    return tilelayer
end

function Map:loadMapData(data)
    return self.reader:call("loadMapData", data)
end

function Map:getLayerClassOrName(layer)
    return self.reader:call("getLayerClassOrName", layer)
end

function Map:isLayerType(layer, type)
    return self.reader:call("isLayerType", layer, type)
end

function Map:loadLayer(layer, depth)
    return self.reader:call("loadLayer", layer, depth)
end

function Map:loadTiles(layer, depth)
    return self.reader:call("loadTiles", layer, depth)
end

function Map:createTileLayer(data)
    return self.reader:call("createTileLayer", data)
end

function Map:decodeTileData(tile)
    return self.reader:call("decodeTileData", tile)
end

function Map:encodeTileData(tileset, tile_id, ...)
    return self.reader:call("encodeTileData", tileset, tile_id, ...)
end

function Map:loadImage(layer, depth)
    return self.reader:call("loadImage", layer, depth)
end

function Map:loadTextureFromImagePath(filename)
    return self.reader:call("loadTextureFromImagePath", filename)
end

function Map:loadCollision(layer)
    return self.reader:call("loadCollision", layer)
end

function Map:loadEnemyCollision(layer)
    return self.reader:call("loadEnemyCollision", layer)
end

function Map:loadBlockCollision(layer)
    return self.reader:call("loadBlockCollision", layer)
end

function Map:loadBattleAreas(layer)
    return self.reader:call("loadBattleAreas", layer)
end

function Map:loadHitboxes(layer)
    return self.reader:call("loadHitboxes", layer)
end

function Map:loadShapes(layer)
    return self.reader:call("loadShapes", layer)
end

function Map:loadMarkers(layer)
    return self.reader:call("loadMarkers", layer)
end

function Map:loadPaths(layer)
    return self.reader:call("loadPaths", layer)
end

function Map:shouldLoadObject(data, layer)
    return self.reader:call("shouldLoadObject", data, layer)
end

function Map:getObjectType(data)
    return self.reader:call("getObjectType", data)
end

function Map:loadObjects(layer, depth, layer_type)
    return self.reader:call("loadObjects", layer, depth, layer_type)
end

--- Loads an object using the old system, based on the Registry.
---
--- Solely for legacy support of projects and libraries that use the old event system.
---@internal
---@param name string # The name of the object to load.
---@param data table # The Tiled object data for the object.
---@return Event? # The loaded object, or `nil` if none was found.
function Map:legacyLoadObject(name, data)
    return self.reader:call("legacyLoadObject", name, data)
end

--- Load an object by its name.
---@param name string The name of the object to load.
---@param data table The serialized object data for the object.
---@param context? table Format-specific loading context.
---@return Event? The loaded object, or `nil` if none was found.
function Map:loadObject(name, data, context)
    return self.reader:call("loadObject", name, data, context)
end

function Map:loadController(name, data, context)
    return self.reader:call("loadController", name, data, context)
end

function Map:populateTilesets(data)
    return self.reader:call("populateTilesets", data)
end

function Map:loadTilesetFromTilesetPath(filename)
    return self.reader:call("loadTilesetFromTilesetPath", filename)
end

---@return Tileset?
---@return integer
function Map:getTileset(id)
    return self.reader:call("getTileset", id)
end

function Map:getTileObjectRect(data)
    return self.reader:call("getTileObjectRect", data)
end

function Map:createTileObject(data, x, y, width, height)
    return self.reader:call("createTileObject", data, x, y, width, height)
end

return Map
