local World, super = Class(Object)

function World:init(map)
    super:init(self)


    self.layers = {
        ["tiles"]         = 0,
        ["objects"]       = 0,
        ["soul"]          = 200,
        ["bullets"]       = 300,
    }


    -- states: GAMEPLAY, TRANSITION_OUT, TRANSITION_IN
    self.state = "GAMEPLAY"

    self.music = Music()

    self.tile_width = 40
    self.tile_height = 40
    self.map_width = 16
    self.map_height = 12

    self.width = self.map_width * self.tile_width
    self.height = self.map_height * self.tile_height

    self.tilesets = {}
    self.collision = {}
    self.tile_layers = {}
    self.markers = {}
    self.battle_areas = {}

    self.camera = Camera(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.camera:setBounds()
    self.camera_attached = true

    self.shake_x = 0
    self.shake_y = 0

    self.player = nil
    self.soul = nil

    self.battle_borders = {}

    self.bg_color = {0, 0, 0, 0}

    self.transition_fade = 0
    self.transition_target = nil

    self.in_battle = false
    self.battle_alpha = 0

    self.followers = {}

    self.timer = Timer.new()

    if map then
        self:loadMap(map)
    end
end

function World:getCollision()
    local col = {}
    for _,collider in ipairs(self.collision) do
        table.insert(col, collider)
    end
    for _,child in ipairs(self.children) do
        if child.collider and child.solid then
            table.insert(col, child.collider)
        end
    end
    return col
end

function World:checkCollision(collider)
    Object.startCache()
    for _,other in ipairs(self:getCollision()) do
        if collider:collidesWith(other) then
            Object.endCache()
            return true, other.parent
        end
    end
    Object.endCache()
    return false
end

function World:spawnPlayer(...)
    local args = {...}

    local x, y = 0, 0
    local chara = self.player and self.player.actor
    if #args > 0 then
        if type(args[1]) == "number" then
            x, y = args[1], args[2]
            chara = args[3] or chara
        elseif type(args[1]) == "string" then
            local marker = self.markers[args[1]]
            x, y = marker and marker.center_x or (self.map_width * self.tile_width/2), marker and marker.center_y or (self.map_height * self.tile_height/2)
            chara = args[2] or chara
        end
    end

    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end

    local facing = "down"

    if self.player then
        facing = self.player.facing
        self:removeChild(self.player)
    end
    if self.soul then
        self:removeChild(self.soul)
    end

    self.player = Player(chara, x, y)
    self.player.layer = self.layers["objects"]
    self.player:setFacing(facing)
    self:addChild(self.player)

    self.soul = OverworldSoul(x + 10, y + 24) -- TODO: unhardcode
    self.soul.layer = self.layers["soul"]
    self:addChild(self.soul)

    if self.camera_attached then
        self.camera:lookAt(self.player.x, self.player.y - (self.player.height * 2)/2)
        self:updateCamera()
    end
end

function World:spawnFollower(chara)
    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end
    local follower = Follower(chara, self.player.x, self.player.y)
    follower.layer = self.layers["objects"]
    table.insert(self.followers, follower)
    self:addChild(follower)
    return follower
end

function World:spawnParty(marker, party)
    party = party or Game.party or {"kris"}
    if #party > 0 then
        if type(marker) == "table" then
            self:spawnPlayer(marker[1], marker[2], party[1].actor)
        else
            self:spawnPlayer(marker or "spawn", party[1].actor)
        end
        for i = 2, #Game.party do
            local follower = self:spawnFollower(party[i].actor)
            follower:setFacing(self.player.facing)
        end
    end
end

function World:loadMap(map)
    local success, map_data = Kristal.executeModScript("scripts/world/maps/"..map)
    if not success then
        error("No map: "..map)
    end

    local map_path = Mod.info.path.."/scripts/world/maps/"..map..".lua"
    map_path = Utils.split(map_path, "/")
    map_path = Utils.join(map_path, "/", 1, #map_path - 1)
    self.full_map_path = map_path

    self.tile_width = map_data.tilewidth
    self.tile_height = map_data.tileheight
    self.map_width = map_data.width
    self.map_height = map_data.height

    self.width = self.map_width * self.tile_width
    self.height = self.map_height * self.tile_height

    self:populateTilesets(map, map_data.tilesets)

    for _,child in ipairs(self.children) do
        if child ~= self.player then
            self:removeChild(child)
        end
    end

    self.followers = {}

    if map_data.backgroundcolor then
        local bgc = map_data.backgroundcolor
        self.bg_color = {bgc[1]/255, bgc[2]/255, bgc[3]/255, (bgc[4] or 255)/255}
    else
        self.bg_color = {0, 0, 0, 0}
    end

    self.collision = {}
    self.battle_areas = {}
    self.tile_layers = {}
    self.image_layers = {}
    self.markers = {}
    self.paths = {}

    local function getDepth(index)
        return ((index - 1) / #map_data.layers) * 100
    end

    local object_depths = {}
    local first_battle_border = 0
    for i,layer in ipairs(map_data.layers) do
        local depth = getDepth(i)
        local name = Utils.split(layer.name, "_")[1]
        if first_battle_border == 0 and name == "battleborder" then
            first_battle_border = i
        end
        if layer.type == "tilelayer" then
            self:loadTiles(layer, depth)
        elseif layer.type == "imagelayer" then
            self:loadImage(layer, depth)
        elseif layer.type == "objectgroup" then
            if name == "objects" then
                table.insert(object_depths, depth)
                self:loadObjects(layer, depth)
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
    end

    for i,layer in ipairs(map_data.layers) do
        local depth = ((i - 1) / #map_data.layers) * 100
        if layer.type == "objectgroup" and layer.name == "markers" then
            if #object_depths == 0 then
                self.layers["objects"] = depth
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
                self.layers["objects"] = closest or depth
            end
        end
    end

    self.camera:setBounds(0, 0, self.map_width * self.tile_width, self.map_height * self.tile_height)

    if self.markers["spawn"] then
        local spawn = self.markers["spawn"]
        self.camera:lookAt(spawn.center_x, spawn.center_y)
    end

    self.battle_fader = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.battle_fader.layer = Utils.lerp(getDepth(first_battle_border), getDepth(first_battle_border - 1), 0.1)
    self:addChild(self.battle_fader)

    if map_data.properties["music"] and map_data.properties["music"] ~= "" then
        if self.music.current ~= map_data.properties["music"] then
            if self.music:isPlaying() then
                self.music:fade(0, 0.1, function()
                    self.music:play(map_data.properties["music"], 1)
                end)
            else
                self.music:play(map_data.properties["music"], 1)
            end
        else
            if not self.music:isPlaying() then
                self.music:play(map_data.properties["music"], 1)
            else
                self.music:fade(1)
            end
        end
    else
        if self.music:isPlaying() then
            self.music:fade(0, 0.1, function() self.music:stop() end)
        end
    end

    self:updateCamera()
end

function World:loadTiles(layer, depth)
    local tilelayer = TileLayer(self, layer)
    tilelayer.layer = depth
    self:addChild(tilelayer)
    table.insert(self.tile_layers, tilelayer)
    if layer.name == "battleborder" then
        tilelayer.tile_opacity = 0
        table.insert(self.battle_borders, tilelayer)
    end
end

function World:loadImage(layer, depth)
    local texture = Utils.absoluteToLocalPath("assets/sprites/", layer.image, self.full_map_path)
    local sprite = Sprite(texture, layer.offsetx, layer.offsety)
    sprite:setParallax(layer.parallaxx, layer.parallaxy)
    sprite.alpha = layer.opacity
    sprite.layer = depth
    if layer.tintcolor then
        sprite:setColor(layer.tintcolor[1]/255, layer.tintcolor[2]/255, layer.tintcolor[3]/255)
    end
    self:addChild(sprite)
    self.image_layers[layer.name] = sprite
    if layer.name == "battleborder" then
        sprite.alpha = 0
        table.insert(self.battle_borders, sprite)
    end
end

function World:loadCollision(layer)
    self.collision = self:loadHitboxes(layer)
end

function World:loadBattleAreas(layer)
    self.battle_areas = self:loadHitboxes(layer)
end

function World:loadHitboxes(layer)
    local hitboxes = {}
    for _,v in ipairs(layer.objects) do
        if v.shape == "rectangle" then
            table.insert(hitboxes, Hitbox(self, v.x, v.y, v.width, v.height))
        elseif v.shape == "polygon" then
            for i = 1, #v.polygon do
                local j = (i % #v.polygon) + 1
                local x1, y1 = v.x + v.polygon[i].x, v.y + v.polygon[i].y
                local x2, y2 = v.x + v.polygon[j].x, v.y + v.polygon[j].y
                table.insert(hitboxes, LineCollider(self, x1, y1, x2, y2))
            end
        end
    end
    return hitboxes
end

function World:loadMarkers(layer)
    for _,v in ipairs(layer.objects) do
        v.width = v.width or 0
        v.height = v.height or 0
        v.center_x = v.x + v.width/2
        v.center_y = v.y + v.height/2

        self.markers[v.name] = v
    end
end

function World:loadPaths(layer)
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

function World:loadObjects(layer, depth)
    for _,v in ipairs(layer.objects) do
        v.width = v.width or 0
        v.height = v.height or 0
        v.center_x = v.x + v.width/2
        v.center_y = v.y + v.height/2

        local obj = self:loadObject(v.name, v)
        if obj then
            obj.layer = depth
            self:addChild(obj)
        end
    end
end

function World:loadObject(name, data)
    -- Mod object loading
    local obj = Kristal.modCall("loadObject", self, name, data)
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
        return NPC(data)
    elseif name:lower() == "enemy" then
        return ChaserEnemy(data.properties["actor"], data.center_x, data.center_y, data)
    end
end

function World:populateTilesets(path, data)
    local map_path = Mod.info.path.."/scripts/world/maps/"..path..".lua"
    map_path = Utils.split(map_path, "/")
    map_path = Utils.join(map_path, "/", 1, #map_path - 1)

    self.tilesets = {}
    for _,tileset_data in ipairs(data) do
        table.insert(self.tilesets, Tileset(tileset_data, map_path))
    end
    table.sort(self.tilesets, function(a,b) return a.first_id > b.first_id end)
end

function World:getTileset(id)
    for _,v in ipairs(self.tilesets) do
        if id >= v.first_id then
            return v, (id - v.first_id)
        end
    end
    return nil, 0
end

function World:transition(target)
    self.state = "TRANSITION_OUT"
    self.transition_target = target
end

function World:transitionImmediate(target)
    if target.map then
        self:loadMap(target.map)
    end
    local pos
    if target.x and target.y then
        pos = {target.x, target.y}
    elseif target.marker then
        pos = target.marker
    end
    self:spawnParty(pos)
end

function World:getCameraTarget()
    return self.player:getRelativePos(self.player.width/2, self.player.height/2)
end

function World:updateCamera()
    if self.shake_x ~= 0 or self.shake_y ~= 0 then
        local last_shake_x = math.ceil(self.shake_x)
        local last_shake_y = math.ceil(self.shake_y)
        self.camera.ox = last_shake_x
        self.camera.oy = last_shake_y
        self.shake_x = Utils.approach(self.shake_x, 0, DTMULT)
        self.shake_y = Utils.approach(self.shake_y, 0, DTMULT)
        local new_shake_x = math.ceil(self.shake_x)
        if new_shake_x ~= last_shake_x then
            self.shake_x = self.shake_x * -1
        end
        local new_shake_y = math.ceil(self.shake_y)
        if new_shake_y ~= last_shake_y then
            self.shake_y = self.shake_y * -1
        end
    else
        self.camera.ox = 0
        self.camera.oy = 0
    end
end

function World:createTransform()
    local transform = super:createTransform(self)
    transform:apply(self.camera:getTransform(0, 0))
    return transform
end

function World:sortChildren()
    Utils.pushPerformance("World#sortChildren")
    -- Sort children by Y position, or by follower index if it's a follower/player (so the player is always on top)
    Object.startCache()
    table.sort(self.children, function(a, b)
        local ax, ay = a:getRelativePos(a.width/2, a.height, self)
        local bx, by = b:getRelativePos(b.width/2, b.height, self)
        return a.layer < b.layer or (a.layer == b.layer and (math.floor(ay) < math.floor(by) or(math.floor(ay) == math.floor(by) and (b == self.player or (a:includes(Follower) and b:includes(Follower) and b.index < a.index)))))
    end)
    Object.endCache()
    Utils.popPerformance()
end

function World:update(dt)
    -- Fade transition
    if self.state == "TRANSITION_OUT" then
        self.transition_fade = Utils.approach(self.transition_fade, 1, dt / 0.25)
        if self.transition_fade == 1 then
            self:transitionImmediate(self.transition_target or {})
            self.state = "TRANSITION_IN"
        end
    elseif self.state == "TRANSITION_IN" then
        self.transition_fade = Utils.approach(self.transition_fade, 0, dt / 0.25)
        if self.transition_fade == 0 then
            self.state = "GAMEPLAY"
        end
    elseif self.state == "GAMEPLAY" then
        -- Object collision
        local collided = {}
        Object.startCache()
        for _,obj in ipairs(self.children) do
            if not obj.solid and obj.onCollide then
                for _,char in ipairs(self.stage:getObjects(Character)) do
                    if obj:collidesWith(char) then
                        if not obj:includes(OverworldSoul) then
                            table.insert(collided, {obj, char})
                        end
                    end
                end
            end
        end
        Object.endCache()
        for _,v in ipairs(collided) do
            v[1]:onCollide(v[2])
        end
    end

    self.timer:update(dt)

    -- Keep camera in bounds
    self:updateCamera()

    if self.in_battle then
        self.battle_alpha = math.min(self.battle_alpha + (0.04 * DTMULT), 0.52)
    else
        self.battle_alpha = math.max(self.battle_alpha - (0.04 * DTMULT), 0)
    end

    for _,v in ipairs(self.followers) do
        v.sprite:setColor(1 - self.battle_alpha, 1 - self.battle_alpha, 1 - self.battle_alpha, 1)
    end

    for _,battle_border in ipairs(self.battle_borders) do
        if battle_border:includes(TileLayer) then
            battle_border.tile_opacity = (self.battle_alpha * 2)
        else
            battle_border.alpha = (self.battle_alpha * 2)
        end
    end
    if self.battle_fader then
        --self.battle_fader.layer = self.battle_border.layer - 1
        self.battle_fader.color = {0, 0, 0, self.battle_alpha}
        self.battle_fader.x = self.camera.x - 320
        self.battle_fader.y = self.camera.y - 240
    end

    -- Always sort
    self.update_child_list = true
    super:update(self, dt)

    local bx, by = self.player:getRelativePos(self.player.width/2, self.player.height/2, self.soul.parent)
    self.soul.x = bx + 1
    self.soul.y = by + 11
    -- TODO: unhardcode offset (???)
end

function World:draw()
    -- Draw background
    love.graphics.setColor(self.bg_color)
    love.graphics.rectangle("fill", 0, 0, self.map_width * self.tile_width, self.map_height * self.tile_height)
    love.graphics.setColor(1, 1, 1)

    super:draw(self)

    -- Draw transition fade
    love.graphics.setColor(0, 0, 0, self.transition_fade)
    love.graphics.rectangle("fill", 0, 0, self.map_width * self.tile_width, self.map_height * self.tile_height)
    love.graphics.setColor(1, 1, 1)
end

return World