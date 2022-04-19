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

    self.name = data and data.properties and data.properties["name"]

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
    self.enemy_collision = {}
    self.tile_layers = {}
    self.image_layers = {}
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
    self.layers = {}

    self.timer = Timer()
end

function Map:load()
    self.world:addChild(self.timer)
    if self.data then
        self:loadMapData(self.data)
    else
        self:addTileLayer(0)
    end
end

function Map:onEnter() end
function Map:onExit() end

function Map:onFootstep(char, num) end

function Map:update(dt) end
function Map:draw() end

function Map:getUniqueID()
    return "#"..self.id
end

function Map:setFlag(flag, value)
    local uid = self:getUniqueID()
    Game:setFlag(uid..":"..flag, value)
end

function Map:getFlag(flag, default)
    local uid = self:getUniqueID()
    return Game:getFlag(uid..":"..flag, default)
end

function Map:getMarker(name)
    local marker = self.markers[name]
    return marker and marker.center_x or (self.width * self.tile_width/2), marker and marker.center_y or (self.height * self.tile_height/2)
end

function Map:addTileset(id)
    local tileset = Registry.getTileset(id)
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
    local indexed_layers = {}
    local has_battle_border = false

    for i,layer in ipairs(data.layers or {}) do
        self.layers[layer.name] = self.next_layer
        indexed_layers[i] = self.next_layer
        self.next_layer = self.next_layer + self.depth_per_layer
    end

    for i,layer in ipairs(data.layers or {}) do
        local name = Utils.split(layer.name, "_")[1]
        local depth = indexed_layers[i]
        if not has_battle_border and name == "battleborder" then
            self.battle_fader_layer = depth - (self.depth_per_layer/2)
            has_battle_border = true
        end
        if layer.type == "tilelayer" then
            self:loadTiles(layer, name, depth)
        elseif layer.type == "imagelayer" then
            self:loadImage(layer, name, depth)
        elseif layer.type == "objectgroup" then
            if name == "objects" then
                table.insert(object_depths, depth)
                self:loadObjects(layer, depth)
            elseif name == "markers" then
                self:loadMarkers(layer)
            elseif name == "collision" then
                self:loadCollision(layer)
            elseif name == "enemycollision" then
                self:loadEnemyCollision(layer)
            elseif name == "paths" then
                self:loadPaths(layer)
            elseif name == "battleareas" then
                self:loadBattleAreas(layer)
            end
        end
    end

    self.object_layer = 1
    for i,layer in ipairs(data.layers or {}) do
        local depth = indexed_layers[i]
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
    tilelayer:setPosition(layer.offsetx or 0, layer.offsety or 0)
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
    if name == "battleborder" then
        sprite.alpha = 0
        table.insert(self.battle_borders, sprite)
    end
end

function Map:loadCollision(layer)
    self.collision = self:loadHitboxes(layer)
end

function Map:loadEnemyCollision(layer)
    self.enemy_collision = self:loadHitboxes(layer)
end

function Map:loadBattleAreas(layer)
    self.battle_areas = self:loadHitboxes(layer)
end

function Map:loadHitboxes(layer)
    local hitboxes = {}
    local ox, oy = layer.offsetx or 0, layer.offsety or 0
    for _,v in ipairs(layer.objects) do
        if v.shape == "rectangle" then
            table.insert(hitboxes, Hitbox(self.world, v.x+ox, v.y+oy, v.width, v.height))
        elseif v.shape == "polygon" then
            for i = 1, #v.polygon do
                local j = (i % #v.polygon) + 1
                local x1, y1 = v.x + v.polygon[i].x + ox, v.y + v.polygon[i].y + oy
                local x2, y2 = v.x + v.polygon[j].x + ox, v.y + v.polygon[j].y + oy
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

        local marker = Utils.copy(v, true)

        v.x = v.x + (layer.offsetx or 0)
        v.y = v.y + (layer.offsety or 0)
        v.center_x = v.center_x + (layer.offsetx or 0)
        v.center_y = v.center_y + (layer.offsety or 0)

        self.markers[v.name] = v
    end
end

function Map:loadPaths(layer)
    local ox, oy = layer.offsetx or 0, layer.offsety or 0
    for _,v in ipairs(layer.objects) do
        local path = {}
        if v.shape == "ellipse" then
            path.shape = "ellipse"
            path.x = v.x + v.width/2 + ox
            path.y = v.y + v.height/2 + oy
            path.rx = v.width/2 + ox
            path.ry = v.height/2 + oy

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
            for i,point in ipairs(polygon) do
                polygon[i] = {x = point.x+ox, y = point.y+oy}
            end
            path.polygon = polygon
            path.length = 0
            for i = 1, #polygon-1 do
                path.length = path.length + Utils.dist(polygon[i].x, polygon[i].y, polygon[i+1].x, polygon[i+1].y)
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

        local obj_type = v.type
        if v.type == "" then
            obj_type = v.name
        end

        local uid = self:getUniqueID().."#"..tostring(v.properties["uid"] or v.id)
        if not Game:getFlag(uid..":dont_load") then
            local skip_loading = false
            if v.properties["cond"] then
                local env = setmetatable({}, {__index = function(t, k)
                    return Game.flags[uid..":"..k] or Game.flags[k] or _G[k]
                end})
                skip_loading = not setfenv(loadstring("return "..v.properties["cond"]), env)()
            elseif v.properties["flagcheck"] then
                local inverted, flag = Utils.startsWith(v.properties["flagcheck"], "!")

                local value = Game.flags[flag]
                local is_true
                if type(value) == "number" then
                    is_true = value > 0
                else
                    is_true = value
                end

                if is_true then
                    skip_loading = inverted
                else
                    skip_loading = not inverted
                end
            end

            if not skip_loading then
                local obj = self:loadObject(obj_type, v)
                if obj then
                    obj.x = obj.x + (layer.offsetx or 0)
                    obj.y = obj.y + (layer.offsety or 0)
                    if not obj.object_id then
                        obj.object_id = v.id
                    end
                    if not obj.unique_id then
                        obj.unique_id = v.properties["uid"]
                    end
                    obj.layer = depth
                    self.world:addChild(obj)
                end
            end
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
    local registered_event = Registry.getEvent(name)
    if registered_event then
        return Registry.createEvent(name, data)
    end
    -- Library object loading
    for id,lib in pairs(Mod.libs) do
        local obj = Kristal.libCall(id, "loadObject", self.world, name, data)
        if obj then
            return obj
        else
            if lib.Events and lib.Events[name] then
                return lib.Events[name](data)
            end
        end
    end
    -- Kristal object loading
    if name:lower() == "savepoint" then
        return Savepoint(Readable.parseText(data.properties), data.center_x, data.center_y, data.properties.marker)
    elseif name:lower() == "interactscript" then
        return InteractScript(data.properties["cutscene"] or data.properties["scene"], data.x, data.y, data.width, data.height, data.properties["once"])
    elseif name:lower() == "script" then
        return Script(data.properties["cutscene"] or data.properties["scene"], data.x, data.y, data.width, data.height, data.properties["once"])
    elseif name:lower() == "readable" then
        return Readable(Readable.parseText(data.properties), data.x, data.y, data.width, data.height)
    elseif name:lower() == "transition" then
        return Transition(data.x, data.y, data.width, data.height, data.properties)
    elseif name:lower() == "npc" then
        return NPC(data.properties["actor"], data.center_x, data.center_y, data.properties)
    elseif name:lower() == "enemy" then
        return ChaserEnemy(data.properties["actor"], data.center_x, data.center_y, data.properties)
    elseif name:lower() == "outline" then
        return Outline(data.x, data.y, data.width, data.height)
    elseif name:lower() == "silhouette" then
        return Silhouette(data.x, data.y, data.width, data.height)
    elseif name:lower() == "slidearea" then
        return SlideArea(data.x, data.y, data.width, data.height)
    elseif name:lower() == "chest" then
        return TreasureChest(data.center_x, data.center_y, data.properties)
    end
end

function Map:populateTilesets(data)
    self.tilesets = {}
    for _,tileset_data in ipairs(data) do
        if tileset_data.filename then
            local tileset_path = Utils.absoluteToLocalPath("scripts/world/tilesets/", tileset_data.filename, self.full_map_path)
            local tileset = Registry.getTileset(tileset_path)
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