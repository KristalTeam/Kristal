local World, super = Class(Object)

World.Y_SORT = function(a, b) return Object.LAYER_SORT(a, b) or a.y < b.y end

function World:init(map)
    super:init(self)

    local success, map_data = Kristal.executeModScript("maps/"..map)
    if not success then
        error("No map: "..map)
    end

    self.tile_width = map_data.tilewidth
    self.tile_height = map_data.tileheight
    self.map_width = map_data.width
    self.map_height = map_data.height
    self:populateTilesets(map, map_data.tilesets)

    self.player = nil

    self.camera = Camera(0, 0)

    for _,layer in ipairs(map_data.layers) do
        if layer.type == "tilelayer" then
            self:addChild(TileLayer(self, layer))
        end
    end
end

function World:populateTilesets(path, data)
    local map_path = MOD.path.."/maps/"..path..".lua"
    map_path = Utils.split(map_path, "/")
    map_path = Utils.join(map_path, "/", #map_path - 1)

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

function World:createTransform()
    local transform = super:createTransform(self)
    transform:apply(self.camera:getTransform())
    return transform
end

function World:sortChildren()
    table.sort(self.children, World.Y_SORT)
end

function World:update(dt)
    -- Keep camera in bounds
    local zoom = 1/self.camera.scale
    local vw, vh = SCREEN_WIDTH/2, SCREEN_HEIGHT/2

    self.camera.x = Utils.clamp(self.camera.x, vw * zoom, self.map_width * self.tile_width - (vw * zoom))
    self.camera.y = Utils.clamp(self.camera.y, vh * zoom, self.map_height * self.tile_height - (vh * zoom))

    -- Always sort
    self.update_child_list = true
    self:updateChildren(dt)
end

function World:draw()

    self:drawChildren()
end

return World