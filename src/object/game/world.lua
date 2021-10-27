local World, super = Class(Object)

function World:init(map)
    super:init(self)

    -- states: GAMEPLAY, TRANSITION_OUT, TRANSITION_IN
    self.state = "GAMEPLAY"

    self.tile_width = 40
    self.tile_height = 40
    self.map_width = 16
    self.map_height = 12

    self.tilesets = {}
    self.collision = {}
    self.tile_layers = {}
    self.markers = {}

    self.camera = Camera(0, 0)
    self.player = nil

    self.transition_fade = 0
    self.transition_target = nil

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
    for _,other in ipairs(self:getCollision()) do
        if collider:collidesWith(other) then
            return true, other.parent
        end
    end
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

    if self.player then
        self:removeChild(self.player)
    end
    self.player = Player(chara, x, y)
    self:addChild(self.player)

    self.camera:lookAt(self.player.x, self.player.y)
    self:updateCamera()
end

function World:spawnFollower(chara)
    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end
    local follower = Follower(chara, self.player.x, self.player.y)
    self:addChild(follower)
end

function World:loadMap(map)
    local success, map_data = Kristal.executeModScript("maps/"..map)
    if not success then
        error("No map: "..map)
    end

    self.tile_width = map_data.tilewidth
    self.tile_height = map_data.tileheight
    self.map_width = map_data.width
    self.map_height = map_data.height
    self:populateTilesets(map, map_data.tilesets)

    for _,child in ipairs(self.children) do
        if child ~= self.player then
            self:removeChild(child)
        end
    end

    self.collision = {}
    self.tile_layers = {}
    self.markers = {}

    for _,layer in ipairs(map_data.layers) do
        if layer.type == "tilelayer" then
            self:loadTiles(layer)
        elseif layer.type == "objectgroup" then
            if layer.name == "objects" then
                self:loadObjects(layer)
            elseif layer.name == "markers" then
                self:loadMarkers(layer)
            elseif layer.name == "collision" then
                self:loadCollision(layer)
            end
        end
    end

    if self.markers["spawn"] then
        local spawn = self.markers["spawn"]
        self.camera:lookAt(spawn.center_x, spawn.center_y)
    end
    self:updateCamera()
end

function World:loadTiles(layer)
    local tilelayer = TileLayer(self, layer)
    self:addChild(tilelayer)
    table.insert(self.tile_layers, tilelayer)
end

function World:loadCollision(layer)
    for _,v in ipairs(layer.objects) do
        if v.shape == "rectangle" then
            table.insert(self.collision, Hitbox(v.x, v.y, v.width, v.height, self))
        elseif v.shape == "polygon" then
            for i = 1, #v.polygon do
                local j = (i % #v.polygon) + 1
                local x1, y1 = v.x + v.polygon[i].x, v.y + v.polygon[i].y
                local x2, y2 = v.x + v.polygon[j].x, v.y + v.polygon[j].y
                table.insert(self.collision, LineCollider(x1, y1, x2, y2, self))
            end
        end
    end
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

function World:loadObjects(layer)
    for _,v in ipairs(layer.objects) do
        v.width = v.width or 0
        v.height = v.height or 0
        v.center_x = v.x + v.width/2
        v.center_y = v.y + v.height/2

        local obj = self:loadObject(v.name, v)
        if obj then
            self:addChild(obj)
        end
    end
end

function World:loadObject(name, data)
    -- Mod object loading
    local obj = Kristal.modCall("LoadObject", self, name, data)
    if obj then
        return obj
    else
        local events = Kristal.modGet("Events")
        if events and events[name] then
            return events[name](data)
        end
    end
    local success, result = Kristal.executeModScript("events/"..name)
    if success then
        return result(data)
    end
    -- Kristal object loading
    if name:lower() == "savepoint" then
        return Savepoint(data)
    elseif name:lower() == "transition" then
        return Transition(data)
    elseif name:lower() == "npc" then
        return NPC(data)
    end
end

function World:populateTilesets(path, data)
    local map_path = MOD.path.."/maps/"..path..".lua"
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
    if target.x and target.y then
        self:spawnPlayer(target.x, target.y)
    elseif target.marker and self.markers[target.marker] then
        self:spawnPlayer(target.marker)
    else
        -- Default positions
        local marker
        for k,v in pairs(self.markers) do
            marker = k
        end
        if marker then
            self:spawnPlayer(marker)
        else
            self:spawnPlayer((self.map_width * self.tile_width) / 2, (self.map_height * self.tile_height) / 2)
        end
    end
    if MOD and MOD.party then
        for i = 2, #MOD.party do
            self:spawnFollower(MOD.party[i])
        end
    end
end

function World:updateCamera()
    local zoom = 1/self.camera.scale
    local vw, vh = SCREEN_WIDTH/2, SCREEN_HEIGHT/2

    self.camera.x = Utils.clamp(self.camera.x, vw * zoom, self.map_width * self.tile_width - (vw * zoom))
    self.camera.y = Utils.clamp(self.camera.y, vh * zoom, self.map_height * self.tile_height - (vh * zoom))
end

function World:createTransform()
    local transform = super:createTransform(self)
    transform:apply(self.camera:getTransform(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT))
    return transform
end

function World:sortChildren()
    Utils.pushPerformance("World#sortChildren")
    -- Sort children by Y position, or by follower index if it's a follower/player (so the player is always on top)
    table.sort(self.children, function(a, b)
        local ax, ay = a:getRelativePos(self, a.width/2, a.height)
        local bx, by = b:getRelativePos(self, b.width/2, b.height)
        return math.floor(ay) < math.floor(by) or(math.floor(ay) == math.floor(by) and (b == self.player or (a:includes(Follower) and b:includes(Follower) and b.index < a.index)))
    end)
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
    end

    -- Keep camera in bounds
    self:updateCamera()

    -- Always sort
    self.update_child_list = true
    self:updateChildren(dt)
end

function World:draw()
    self:drawChildren()

    -- Draw transition fade
    love.graphics.setColor(0, 0, 0, self.transition_fade)
    love.graphics.rectangle("fill", 0, 0, self.map_width * self.tile_width, self.map_height * self.tile_height)
    love.graphics.setColor(1, 1, 1)
end

return World