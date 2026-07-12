---@class MapReader : Class
---@overload fun(map: Map): MapReader
local MapReader = Class()

MapReader.FORMAT = "unknown"
MapReader.LEGACY_FORMAT = false
MapReader.operations = {}
local operations = MapReader.operations

function MapReader.copyOperations()
    return TableUtils.copy(MapReader.operations)
end

function operations.loadTiles(self, layer, depth)
    local tilelayer = self:createTileLayer(layer)
    tilelayer:setPosition(layer.offsetx or 0, layer.offsety or 0)
    tilelayer.layer = depth
    self.world:addChild(tilelayer)
    table.insert(self.tile_layers, tilelayer)
    if self:isLayerType(layer, "battleborder") then
        table.insert(self.battle_borders, tilelayer)
    end
end

function operations.decodeTileData(self, tile)
    return MapUtils.unpackTileGid(tile)
end

function operations.encodeTileData(self, tileset, tile_id)
    local _, first_id = self:getTileset(tileset)
    return first_id + tile_id
end

function operations.getTileset(self, id)
    if type(id) == "number" then
        id = MapUtils.unpackTileGid(id)
        for index, tileset in ipairs(self.tilesets) do
            local first_id = self.tileset_gids[tileset]
            local next_id = first_id + tileset.id_count
            if index < #self.tilesets then next_id = self.tileset_gids[self.tilesets[index + 1]] end
            if id >= first_id and id < next_id then return tileset, id - first_id end
        end
    elseif type(id) == "string" then
        for _, tileset in ipairs(self.tilesets) do
            if tileset.id == id or tileset.name == id then return tileset, self.tileset_gids[tileset] end
        end
    end
    return nil, 0
end

local function getTileObjectInfo(self, data)
    if data.gid then
        local gid, flip_x, flip_y = MapUtils.unpackTileGid(data.gid)
        local tileset, tile_id = self:getTileset(gid)
        return tileset, tile_id, flip_x, flip_y
    end
    local tileset = data.tileset and self:getTileset(data.tileset) or nil
    return tileset, data.tile_id, data.flip_x == true, data.flip_y == true
end

function operations.getTileObjectRect(self, data)
    local tileset, tile_id = getTileObjectInfo(self, data)
    local tile_width, tile_height = data.width, data.height
    if tileset and (tile_width == nil or tile_height == nil) then
        local width, height = tileset:getTileSize(tile_id)
        tile_width, tile_height = tile_width or width, tile_height or height
    end
    tile_width, tile_height = tile_width or 0, tile_height or 0
    local origin = tileset and Tileset.ORIGINS[tileset.object_alignment]
        or Tileset.ORIGINS["unspecified"]
    return (data.x or 0) - origin[1] * tile_width,
        (data.y or 0) - origin[2] * tile_height, tile_width, tile_height
end

function operations.createTileObject(self, data, x, y, width, height)
    local tileset, tile_id, flip_x, flip_y = getTileObjectInfo(self, data)
    if not tileset or tile_id == nil then return nil end
    return TileObject(tileset, tile_id, x or data.x, y or data.y,
        width or data.width, height or data.height,
        math.rad(data.rotation or 0), flip_x, flip_y)
end

function operations.loadImage(self, layer, depth)
    local success, texture_result = self:loadTextureFromImagePath(layer.image)
    if not success then
        error("Map \"" .. self.data.id .. "\" failed to load image layer \"" .. layer.name .. "\"\n" .. texture_result)
    end
    local sprite = Sprite(texture_result, layer.offsetx, layer.offsety)
    sprite:setParallax(layer.parallaxx, layer.parallaxy)
    sprite.alpha = layer.opacity
    sprite.layer = depth
    if layer.tintcolor then
        sprite:setColor(layer.tintcolor[1] / 255, layer.tintcolor[2] / 255, layer.tintcolor[3] / 255)
    end
    sprite:setSpeed(layer.properties["speedx"] or 0, layer.properties["speedy"] or 0)
    if layer.repeatx or layer.properties["wrapx"] then
        sprite.wrap_texture_x = true
    end
    if layer.repeaty or layer.properties["wrapy"] then
        sprite.wrap_texture_y = true
    end
    if layer.properties["fitscreen"] then
        sprite.width = SCREEN_WIDTH
        sprite.height = SCREEN_HEIGHT
    end
    sprite:setScale(layer.properties["scalex"] or 1, layer.properties["scaley"] or 1)
    self.world:addChild(sprite)
    self.image_layers[layer.name] = sprite
    if self:isLayerType(layer, "battleborder") then
        sprite.alpha = 0
        table.insert(self.battle_borders, sprite)
    end
end

function operations.loadCollision(self, layer)
    TableUtils.merge(self.collision, self:loadHitboxes(layer))
end

function operations.loadEnemyCollision(self, layer)
    TableUtils.merge(self.enemy_collision, self:loadHitboxes(layer))
end

function operations.loadBlockCollision(self, layer)
    TableUtils.merge(self.block_collision, self:loadHitboxes(layer))
end

function operations.loadBattleAreas(self, layer)
    TableUtils.merge(self.battle_areas, self:loadHitboxes(layer))
end

function operations.loadHitboxes(self, layer)
    local hitboxes = {}
    local ox, oy = layer.offsetx or 0, layer.offsety or 0
    for _, v in ipairs(layer.objects) do
        local hitbox = MapUtils.colliderFromShape(self.world, v, v.x + ox, v.y + oy, v.properties)
        if hitbox then
            table.insert(hitboxes, hitbox)

            self.hitboxes_by_id[v.id] = hitbox

            self.hitboxes_by_name[v.name] = self.hitboxes_by_name[v.name] or {}
            table.insert(self.hitboxes_by_name[v.name], hitbox)
        end
    end
    return hitboxes
end

function operations.loadShapes(self, layer)
    self.shape_layers[layer.name] = layer

    for _, v in ipairs(layer.objects) do
        self.shapes_by_id[v.id] = v

        self.shapes_by_name[v.name] = self.shapes_by_name[v.name] or {}
        table.insert(self.shapes_by_name[v.name], v)
    end
end

function operations.loadMarkers(self, layer)
    for _, source in ipairs(layer.objects) do
        local v = TableUtils.copy(source, true)
        v.width = v.width or 0
        v.height = v.height or 0
        local rotation = math.rad(tonumber(v.rotation) or 0)
        local half_width, half_height = v.width / 2, v.height / 2
        v.center_x = v.x + half_width * math.cos(rotation) - half_height * math.sin(rotation)
        v.center_y = v.y + half_width * math.sin(rotation) + half_height * math.cos(rotation)

        v.x = v.x + (layer.offsetx or 0)
        v.y = v.y + (layer.offsety or 0)
        v.center_x = v.center_x + (layer.offsetx or 0)
        v.center_y = v.center_y + (layer.offsety or 0)

        v.player_state = v.properties["player_state"] or "WALK"

        if v.name ~= nil then
            self.markers[v.name] = v
        end

        self.markers_by_id[v.id] = v
    end
end

function operations.loadPaths(self, layer)
    local ox, oy = layer.offsetx or 0, layer.offsety or 0
    for _, v in ipairs(layer.objects) do
        local path = {}
        if v.shape == "ellipse" then
            path.shape = "ellipse"
            path.x = v.x + v.width / 2 + ox
            path.y = v.y + v.height / 2 + oy
            path.rx = v.width / 2
            path.ry = v.height / 2

            -- Roughly calculte ellipse perimeter bc the actual calculation is hard
            path.length = 2 * math.pi * ((path.rx + path.ry) / 2)
            path.closed = true
        else
            path.shape = "line"
            path.x = v.x
            path.y = v.y
            local points = TableUtils.copy(v.polygon or v.polyline or {})
            if v.shape == "rectangle" then
                points = { { x = 0, y = 0 }, { x = v.width, y = 0 }, { x = v.width, y = v.height }, { x = 0, y = v.height }, { x = 0, y = 0 } }
                path.closed = true
            else
                if v.shape ~= "polyline" then
                    table.insert(points, points[1])
                    path.closed = true
                end
            end
            for i, point in ipairs(points) do
                points[i] = { x = v.x + point.x + ox, y = v.y + point.y + oy }
            end
            path.points = points
            path.length = 0
            for i = 1, #points - 1 do
                path.length = path.length + MathUtils.dist(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y)
            end
        end
        self.paths[v.name] = path
    end
end

function operations.shouldLoadObject(self, data, layer)
    local skip_loading = false
    local uid = self:getUniqueID() .. "#" .. tostring(data.properties["uid"] or data.id)
    if data.properties["cond"] then
        local env = setmetatable({}, {__index = function(t, k)
            return Game:getFlag(uid .. ":" .. k) or Game:getFlag(k) or _G[k]
        end})
        local chunk, _ = assert(loadstring("return " .. data.properties["cond"]))
        skip_loading = not setfenv(chunk, env)()
    elseif data.properties["flagcheck"] then
        local inverted, flag = StringUtils.startsWith(data.properties["flagcheck"], "!")

        local result = Game:getFlag(uid .. ":" .. flag) or Game:getFlag(flag)
        local value = data.properties["flagvalue"]
        local is_true
        if value ~= nil then
            is_true = result == value
        elseif type(result) == "number" then
            is_true = result > 0
        else
            is_true = result
        end

        if is_true then
            skip_loading = inverted
        else
            skip_loading = not inverted
        end
    end
    return not skip_loading
end

function operations.loadObjects(self, layer, depth, layer_type)
    local parent = layer_type == "controllers" and self.world.controller_parent or self.world

    self.events_by_layer[layer.name] = {}
    for _, source in ipairs(layer.objects) do
        local v = TableUtils.copy(source, true)
        v.width = v.width or 0
        v.height = v.height or 0
        local rotation = math.rad(tonumber(v.rotation) or 0)
        local half_width, half_height = v.width / 2, v.height / 2
        v.center_x = v.x + half_width * math.cos(rotation) - half_height * math.sin(rotation)
        v.center_y = v.y + half_width * math.sin(rotation) + half_height * math.cos(rotation)

        -- Get width/height of the full polygon (usable when a polygon is not supported on an object)
        if v.polygon then
            local min_x, max_x, min_y, max_y = 0, 0, 0, 0
            for _, point in ipairs(v.polygon) do
                min_x = math.min(point.x, min_x)
                max_x = math.max(point.x, max_x)
                min_y = math.min(point.y, min_y)
                max_y = math.max(point.y, max_y)
            end

            v.width = max_x - min_x
            v.height = max_y - min_y
            local center_x, center_y = (min_x + max_x) / 2, (min_y + max_y) / 2
            v.center_x = v.x + center_x * math.cos(rotation) - center_y * math.sin(rotation)
            v.center_y = v.y + center_x * math.sin(rotation) + center_y * math.cos(rotation)
        end

        if v.gid then
            local tx, ty, tw, th = self:getTileObjectRect(v)
            v.center_x = tx + tw / 2
            v.center_y = ty + th / 2
        end

        local obj_type = v.type or v.class
        if obj_type == "" then
            obj_type = v.name
        end

        local uid = self:getUniqueID() .. "#" .. tostring(v.properties["uid"] or v.id)
        if not Game:getFlag(uid .. ":dont_load") then
            if self:shouldLoadObject(v, layer) then
                local obj
                if layer_type == "controllers" then
                    obj = self:loadController(obj_type, v)
                else
                    obj = self:loadObject(obj_type, v)
                end
                if obj then
                    obj.rotation = rotation
                    obj:setScale((obj.scale_x or 1) * (v.scale_x or 1),
                        (obj.scale_y or 1) * (v.scale_y or 1))
                    obj.x = obj.x + (layer.offsetx or 0)
                    obj.y = obj.y + (layer.offsety or 0)
                    obj:setParallax((obj.parallax_x or 1) * layer.parallaxx, (obj.parallax_y or 1) * layer.parallaxy)
                    if not obj.object_id then
                        obj.object_id = v.id
                    end
                    if not obj.unique_id then
                        obj.unique_id = v.properties["uid"]
                    end
                    obj.layer = depth
                    obj.layer_name = layer.name
                    obj.data = v

                    if (v.gid or v.tileset and v.tile_id ~= nil) and obj.applyTileObject then
                        obj:applyTileObject(v, self)
                    end

                    parent:addChild(obj)

                    table.insert(self.events, obj)

                    self.events_by_name[v.name] = self.events_by_name[v.name] or {}
                    table.insert(self.events_by_name[v.name], obj)
                    table.insert(self.events_by_layer[layer.name], obj)

                    if v.id then
                        self.events_by_id[v.id] = obj
                        self.next_object_id = math.max(self.next_object_id, v.id)
                    end
                end
            end
        end
    end
end

function operations.legacyLoadObject(self, name, data)
    local registered_event = Registry.getLegacyEvent(name)
    if registered_event then
        return Registry.createLegacyEvent(name, data)
    end

    return nil
end

function operations.loadObject(self, name, data)

    -- Check the events
    local loaded = Kristal.callEvent(KRISTAL_EVENT.loadObject, self.world, name, data)
    if loaded ~= nil then
        if type(loaded) == "boolean" then -- don't load the object if it returns true
            if loaded then
                return
            end
        else
            return loaded
        end
    end

    -- Check the registry
    if Game.event_registry:has(name) then
        return Game.event_registry:create(name, data)
    end

    -- Attempt to use the legacy system to load it
    loaded = self:legacyLoadObject(name, data)
    if loaded ~= nil then
        return loaded
    end

    -- Check for built-in events, must happen after everything else
    if Game.builtin_event_registry:has(name) then
        return Game.builtin_event_registry:create(name, data)
    end

    -- Fallback to a TileObject
    if data.gid or data.tileset and data.tile_id ~= nil then
        return self:createTileObject(data)
    end

    Kristal.Console:warn("No event with ID '" .. tostring(name) .. "' found")
end

function operations.loadController(self, name, data)
    -- Mod object loading
    local obj = Kristal.modCall("loadController", self.world, name, data)
    if obj then
        return obj
    else
        local controllers = Kristal.modGet("Controllers")
        if controllers and controllers[name] then
            return controllers[name](data)
        end
    end
    local registered_event = Registry.getController(name)
    if registered_event then
        return Registry.createController(name, data)
    end
    -- Library object loading
    for id, lib in Kristal.iterLibraries() do
        local obj = Kristal.libCall(id, "loadController", self.world, name, data)
        if obj then
            return obj
        else
            if lib.Controllers and lib.Controllers[name] then
                return lib.Controllers[name](data)
            end
        end
    end
    -- Kristal object loading
    if name:lower() == "toggle" then
        return ToggleController(data.properties)
    elseif name:lower() == "fountainshadow" then
        return FountainShadowController(data.properties)
    end
end

function MapReader:init(map)
    self.map = map
    self.operations = self.operations or {}
end

function MapReader:call(operation, ...)
    local callback = self.operations[operation]
    if not callback then
        error(string.format("%s does not implement map operation '%s'",
            ClassUtils.getClassName(self), tostring(operation)), 2)
    end
    return callback(self.map, ...)
end

function MapReader:initialize(data)
    error(ClassUtils.getClassName(self) .. " does not implement map initialization", 2)
end

function MapReader:read(data)
    error(ClassUtils.getClassName(self) .. " does not implement map reading", 2)
end

function MapReader:getFormat()
    return self.FORMAT
end

function MapReader:isLegacyFormat()
    return self.LEGACY_FORMAT == true
end

function MapReader:save(path, options)
    return false, string.format("Map format '%s' has no saving implementation!", tostring(self:getFormat()))
end

return MapReader
