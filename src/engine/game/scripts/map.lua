local Map = Class()

function Map:init(world, data)
    self.world = world or Game.world

    self.data = data

    if data and data.full_path then
        local map_path = data.full_path
        map_path = Utils.split(map_path, "/")
        map_path = Utils.join(map_path, "/", 1, #map_path - 1)
        self.full_map_path = map_path
    else
        self.full_map_path = Mod and Mod.info.path or ""
    end

    self.tile_width = data and data.tilewidth or 40
    self.tile_height = data and data.tileheight or 40
    self.width = data and data.width or 16
    self.height = data and data.height or 12

    self.music = data and data.properties and data.properties["music"]
    self.light = data and data.properties and data.properties["light"] or false

    if data and data.backgroundcolor then
        local bgc = data.backgroundcolor
        self.bg_color = {bgc[1]/255, bgc[2]/255, bgc[3]/255, (bgc[4] or 255)/255}
    else
        self.bg_color = {0, 0, 0, 0}
    end

    self.tilesets = {}
    self.collision = {}
    self.tile_layers = {}
    self.markers = {}
    self.battle_areas = {}
    self.battle_borders = {}
    self.paths = {}

    if data then
        self:populateTilesets(data.tilesets)
    end

    self.depth_per_layer = 0.1 -- its not perfect, but i doubt anyone will have 2000 layers
    self.next_layer = self.depth_per_layer

    self.object_layer = 1
    self.battle_fader_layer = 0.5
end

function Map:load()
    if self.data then
        self:loadMapData(self.data)
    else
        self:addTileLayer(0)
    end
end

function Map:update(dt) end
function Map:draw() end

function Map:getMarker(name)
    local marker = self.markers[name]
    return marker and marker.center_x or (self.width * self.tile_width/2), marker and marker.center_y or (self.height * self.tile_height/2)
end

function Map:addTileset(id)
    local tileset = Assets.getTileset(id)
    if tileset then
        table.insert(self.tilesets, tileset)
        return tileset
    else
        error("No tileset with id '"..id.."'")
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
    local args = {...}

    local tile_layer
    if type(args[#args]) == "string" then
        tile_layer = self:getTileLayer(args[#args])
        table.remove(args, #args)
    else
        tile_layer = self:getTileLayer()
    end

    tile_layer:setTile(x, y, tileset, unpack(args))
end

function Map:getTileLayer(name)
    if name then
        for _,layer in ipairs(self.tile_layers) do
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
        tilelayer.tile_opacity = 0
        table.insert(self.battle_borders, tilelayer)
    end
    if not depth then
        self.next_layer = self.next_layer + self.depth_per_layer
    end
    return tilelayer
end

function Map:loadMapData(data)
    local object_depths = {}
    local has_battle_border = false
    for i,layer in ipairs(data.layers or {}) do
        local name = Utils.split(layer.name, "_")[1]
        if not has_battle_border and name == "battleborder" then
            self.battle_fader_layer = self.next_layer - (self.depth_per_layer/2)
            has_battle_border = true
        end
        if layer.type == "tilelayer" then
            self:loadTiles(layer, name, self.next_layer)
        elseif layer.type == "imagelayer" then
            self:loadImage(layer, name, self.next_layer)
        elseif layer.type == "objectgroup" then
            if name == "objects" then
                table.insert(object_depths, self.next_layer)
                self:loadObjects(layer, self.next_layer)
            elseif name == "markers" then
                self:loadMarkers(layer)
            elseif name == "collision" then
                self:loadCollision(layer)
            elseif name == "paths" then
                self:loadPaths(layer)
            elseif name == "battleareas" then
                self:loadBattleAreas(layer)
            end
        end
        self.next_layer = self.next_layer + self.depth_per_layer
    end

    self.object_layer = 1
    for i,layer in ipairs(data.layers or {}) do
        local depth = i * self.depth_per_layer
        if layer.type == "objectgroup" and layer.name == "markers" then
            if #object_depths == 0 then
                self.object_layer = depth
            else
                local closest
                for _,obj_depth in ipairs(object_depths) do
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
        end
    end
end

function Map:loadTiles(layer, name, depth)
    local tilelayer = TileLayer(self, layer)
    tilelayer.layer = depth
    self.world:addChild(tilelayer)
    table.insert(self.tile_layers, tilelayer)
    if name == "battleborder" then
        tilelayer.tile_opacity = 0
        table.insert(self.battle_borders, tilelayer)
    end
end

function Map:loadImage(layer, name, depth)
    local texture = Utils.absoluteToLocalPath("assets/sprites/", layer.image, self.full_map_path)
    local sprite = Sprite(texture, layer.offsetx, layer.offsety)
    sprite:setParallax(layer.parallaxx, layer.parallaxy)
    sprite.alpha = layer.opacity
    sprite.layer = depth
    if layer.tintcolor then
        sprite:setColor(layer.tintcolor[1]/255, layer.tintcolor[2]/255, layer.tintcolor[3]/255)
    end
    sprite:setSpeed(layer.properties["speedx"] or 0, layer.properties["speedy"] or 0)
    if layer.properties["wrapx"] then
        sprite.wrap_texture_x = true
    end
    if layer.properties["wrapy"] then
        sprite.wrap_texture_y = true
    end
    if layer.properties["fitscreen"] then
        sprite.width = SCREEN_WIDTH
        sprite.height = SCREEN_HEIGHT
    end
    sprite:setScale(layer.properties["scalex"] or 1, layer.properties["scaley"] or 1)
    self.world:addChild(sprite)
    self.image_layers[layer.name] = sprite
    if name == "battleborder" then
        sprite.alpha = 0
        table.insert(self.battle_borders, sprite)
    end
end

function Map:loadCollision(layer)
    self.collision = self:loadHitboxes(layer)
end

function Map:loadBattleAreas(layer)
    self.battle_areas = self:loadHitboxes(layer)
end

function Map:loadHitboxes(layer)
    local hitboxes = {}
    for _,v in ipairs(layer.objects) do
        if v.shape == "rectangle" then
            table.insert(hitboxes, Hitbox(self.world, v.x, v.y, v.width, v.height))
        elseif v.shape == "polygon" then
            for i = 1, #v.polygon do
                local j = (i % #v.polygon) + 1
                local x1, y1 = v.x + v.polygon[i].x, v.y + v.polygon[i].y
                local x2, y2 = v.x + v.polygon[j].x, v.y + v.polygon[j].y
                table.insert(hitboxes, LineCollider(self.world, x1, y1, x2, y2))
            end
        end
    end
    return hitboxes
end

function Map:loadMarkers(layer)
    for _,v in ipairs(layer.objects) do
        v.width = v.width or 0
        v.height = v.height or 0
        v.center_x = v.x + v.width/2
        v.center_y = v.y + v.height/2

        self.markers[v.name] = v
    end
end

function Map:loadPaths(layer)
    for _,v in ipairs(layer.objects) do
        local path = {}
        if v.shape == "ellipse" then
            path.shape = "ellipse"
            path.x = v.x + v.width/2
            path.y = v.y + v.height/2
            path.rx = v.width/2
            path.ry = v.height/2

            -- Roughly calculte ellipse perimeter bc the actual calculation is hard
            path.length = 2*math.pi*((path.rx + path.ry)/2)
            path.closed = true
        else
            path.shape = "line"
            path.x = v.x
            path.y = v.y
            local polygon = Utils.copy(v.polygon or v.polyline or {})
            if v.shape == "rectangle" then
                polygon = {{x = v.x, y = v.y}, {x = v.x + v.width, y = v.y}, {x = v.x + v.width, y = v.y + v.height}, {x = v.x, y = v.y + v.height}}
            end
            if v.shape ~= "polyline" then
                table.insert(polygon, polygon[1])
                path.closed = true
            end
            path.polygon = polygon
            path.length = 0
            for i = 1, #polygon-1 do
                path.length = path.length + Vector.dist(polygon[i].x, polygon[i].y, polygon[i+1].x, polygon[i+1].y)
            end
        end
        self.paths[v.name] = path
    end
end

function Map:loadObjects(layer, depth)
    for _,v in ipairs(layer.objects) do
        v.width = v.width or 0
        v.height = v.height or 0
        v.center_x = v.x + v.width/2
        v.center_y = v.y + v.height/2

        local type = v.type
        if v.type == "" then
            type = v.name
        end

        local obj = self:loadObject(type, v)
        if obj then
            obj.layer = depth
            self.world:addChild(obj)
        end
    end
end

function Map:loadObject(name, data)
    -- Mod object loading
    local obj = Kristal.modCall("loadObject", self.world, name, data)
    if obj then
        return obj
    else
        local events = Kristal.modGet("Events")
        if events and events[name] then
            return events[name](data)
        end
    end
    local success, result = Kristal.executeModScript("scripts/world/events/"..name)
    if success then
        return result(data)
    end
    -- Kristal object loading
    if name:lower() == "savepoint" then
        return Savepoint(data)
    elseif name:lower() == "interactscript" then
        return InteractScript(data)
    elseif name:lower() == "script" then
        return Script(data)
    elseif name:lower() == "readable" then
        return Readable(data)
    elseif name:lower() == "transition" then
        return Transition(data)
    elseif name:lower() == "npc" then
        return NPC(data.properties["actor"], data.center_x, data.center_y, data.properties)
    elseif name:lower() == "enemy" then
        return ChaserEnemy(data.properties["actor"], data.center_x, data.center_y, data)
    elseif name:lower() == "outline" then
        return Outline(data)
    elseif name:lower() == "silhouette" then
        return Silhouette(data)
    elseif name:lower() == "chest" then
        return TreasureChest(data.center_x, data.center_y, data.properties)
    end
end

function Map:populateTilesets(data)
    self.tilesets = {}
    for _,tileset_data in ipairs(data) do
        if tileset_data.filename then
            local tileset_path = Utils.absoluteToLocalPath("assets/tilesets/", tileset_data.filename, self.full_map_path)
            local tileset = Assets.getTileset(tileset_path)
            if not tileset then
                error("Failed to load map \""..self.data.id.."\", tileset not found: \""..tileset_path.."\"")
            end
            table.insert(self.tilesets, tileset)
        else
            table.insert(self.tilesets, Tileset(tileset_data, self.full_map_path))
        end
    end
end

function Map:getTileset(id)
    if type(id) == "number" then
        local first_id = 1
        for _,v in ipairs(self.tilesets) do
            if id >= first_id and id < first_id + v.tile_count then
                return v, (id - first_id)
            end
            first_id = first_id + v.tile_count
        end
    elseif type(id) == "string" then
        local first_id = 1
        for _,v in ipairs(self.tilesets) do
            if v.name == id then
                return v, first_id
            end
            first_id = first_id + v.tile_count
        end
    end
    return nil, 0
end

return Map