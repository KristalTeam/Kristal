---@class TileLayer : Object
---@overload fun(...) : TileLayer
local TileLayer, super = Class(Object)

function TileLayer:init(map, data)
    data = data or {}

    self.map_width = data.width or map.width
    self.map_height = data.height or map.height

    super.init(self, data.offsetx or 0, data.offsety or 0, self.map_width * map.tile_width,
        self.map_height * map.tile_height)

    self.map = map
    self.name = data.name

    self.parallax_x = data.parallaxx or 1
    self.parallax_y = data.parallaxy or 1

    if data.tintcolor then
        self:setColor(data.tintcolor[1] / 255, data.tintcolor[2] / 255, data.tintcolor[3] / 255)
    end

    self.tile_data = data.data
    self.tile_opacity = data.opacity or 1

    if not self.tile_data then
        self.tile_data = {}
        for i = 1, (self.map_width * self.map_height) do
            self.tile_data[i] = 0
        end
    end

    self.animated_tiles = {}

    self.canvas = love.graphics.newCanvas(self.map_width * map.tile_width, self.map_height * map.tile_height)
    self.drawn = false

    self.debug_select = false
end

function TileLayer:setTile(x, y, tileset, ...)
    local index = x + (y * self.map_width) + 1
    if type(tileset) == "number" then
        self.tile_data[index] = tileset
    elseif type(tileset) == "string" then
        local tiles, first_id = self.map:getTileset(tileset)

        local args = { ... }
        if #args == 2 then -- x, y
            self.tile_data[index] = first_id + (args[1] + (args[2] * tiles.columns))
        else               -- tile index
            self.tile_data[index] = first_id + args[1]
        end
    end
    self.drawn = false
end

function TileLayer:getTile(x, y)
    local index = x + (y * self.map_width) + 1

    if self.tile_data[index] then
        local tile = self.tile_data[index]
        return self.map:getTileset(tile)
    end

    return nil, 0
end

function TileLayer:draw()
    local r, g, b, a = self:getDrawColor()

    local grid_w, grid_h = self.map.tile_width, self.map.tile_height

    if not self.drawn then
        Draw.setColor(r, g, b, self.tile_opacity)

        Draw.pushCanvas(self.canvas)
        love.graphics.clear()
        love.graphics.push()
        love.graphics.origin()
        self.animated_tiles = {}
        for i, xid in ipairs(self.tile_data) do
            local tx = ((i - 1) % self.map_width) * grid_w
            local ty = math.floor((i - 1) / self.map_width) * grid_h

            local gid, flip_x, flip_y, flip_diag = Utils.parseTileGid(xid)
            local tileset, id = self.map:getTileset(gid)
            if tileset then
                if not tileset:getAnimation(id) then
                    tileset:drawGridTile(id, tx, ty, grid_w, grid_h, flip_x, flip_y, flip_diag)
                else
                    table.insert(self.animated_tiles,
                        { tileset = tileset, id = id, x = tx, y = ty, flip_x = flip_x, flip_y = flip_y,
                            flip_diag = flip_diag })
                end
            end
        end
        love.graphics.pop()
        Draw.popCanvas()

        self.drawn = true
    end

    Draw.setColor(1, 1, 1, a)

    if a == 1 then
        love.graphics.setBlendMode("alpha", "premultiplied")
    else
        love.graphics.setBlendMode("alpha")
    end
    Draw.draw(self.canvas)
    love.graphics.setBlendMode("alpha")

    Draw.setColor(r, g, b, a * self.tile_opacity)
    for _, tile in ipairs(self.animated_tiles) do
        tile.tileset:drawGridTile(tile.id, tile.x, tile.y, grid_w, grid_h, tile.flip_x, tile.flip_y, tile.flip_diag)
    end

    Draw.setColor(1, 1, 1)

    super.draw(self)
end

return TileLayer
