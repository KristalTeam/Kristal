---@class TileLayer : Object
---@field private drawn boolean
---@field private sprite_batches love.SpriteBatch[]
---@field private unbatched_tiles TileLayer.UnbatchedTileData[]
---@overload fun(...) : TileLayer
local TileLayer, super = Class(Object)

---@alias TileLayer.UnbatchedTileData table

---@param map Map
function TileLayer:init(map, data)
    data = data or {}

    self.map_width = data.width or map.width
    self.map_height = data.height or map.height

    super.init(
        self,
        data.offsetx or 0, data.offsety or 0,
        self.map_width * map.tile_width,
        self.map_height * map.tile_height
    )

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

    self.unbatched_tiles = {}

    self.sprite_batches = {}
    self.drawn = false

    self.debug_select = false
end

function TileLayer:setTile(x, y, tileset, ...)
    local index = x + (y * self.map_width) + 1
    if type(tileset) == "number" then
        self.tile_data[index] = tileset
    elseif type(tileset) == "string" then
        local args = { ... }
        local tile_id
        if #args == 2 then -- x, y
            local tiles = self.map:getTileset(tileset)
            tile_id = args[1] + (args[2] * tiles.columns)
        else -- tile index
            tile_id = args[1]
        end
        self.tile_data[index] = self.map:encodeTileData(tileset, tile_id)
    end
    self:markTilesDirty()
end

function TileLayer:getTile(x, y)
    local index = x + (y * self.map_width) + 1

    if self.tile_data[index] then
        local tile = self.tile_data[index]
        return self.map:getTileset(tile)
    end

    return nil, 0
end

function TileLayer:markTilesDirty()
    self.drawn = false
end

---@private
function TileLayer:regenerateTiles()
    self.drawn = true
    local r, g, b, a = self:getDrawColor()
    local grid_w, grid_h = self.map.tile_width, self.map.tile_height
    Draw.setColor(r, g, b, self.tile_opacity)

    self.unbatched_tiles = {}
    self.sprite_batches = {}
    ---@type table<Tileset, love.SpriteBatch>
    local tileset_sprite_batches = {}
    for i, xid in ipairs(self.tile_data) do
        local tx = ((i - 1) % self.map_width) * grid_w
        local ty = math.floor((i - 1) / self.map_width) * grid_h

        local gid, flip_x, flip_y, flip_diag = self.map:decodeTileData(xid)
        local tileset, id = self.map:getTileset(gid)
        if tileset then
            if tileset.texture == nil or tileset:getAnimation(id) ~= nil then
                table.insert(
                    self.unbatched_tiles,
                    {
                        tileset = tileset, id = id,
                        x = tx, y = ty,
                        flip_x = flip_x, flip_y = flip_y,
                        flip_diag = flip_diag
                    }
                )
            else
                local batch = tileset_sprite_batches[tileset]
                if batch == nil then
                    local batch_size = self.map_width * self.map_height
                    batch = love.graphics.newSpriteBatch(tileset.texture, batch_size, "static")
                    tileset_sprite_batches[tileset] = batch
                    table.insert(self.sprite_batches, batch)
                end
                tileset:addTileToBatch(batch, id, tx, ty, grid_w, grid_h, flip_x, flip_y, flip_diag)
            end
        end
    end
end

function TileLayer:draw()
    if not self.drawn then
        self:regenerateTiles()
    end

    local r, g, b, a = self:getDrawColor()
    Draw.setColor(r, g, b, a * self.tile_opacity)

    for _,batch in ipairs(self.sprite_batches) do
        love.graphics.draw(batch)
    end

    local grid_w, grid_h = self.map.tile_width, self.map.tile_height

    for _, tile in ipairs(self.unbatched_tiles) do
        tile.tileset:drawGridTile(tile.id, tile.x, tile.y, grid_w, grid_h, tile.flip_x, tile.flip_y, tile.flip_diag)
    end

    Draw.setColor(1, 1, 1)

    super.draw(self)
end

return TileLayer
