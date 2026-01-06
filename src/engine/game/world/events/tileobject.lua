--- A combination of a tile from a tileset and an Event. \
--- TileObject is not a standard event - it defines no properties and is placed in a map using the `Insert Tile` feature through Tiled, rather than as an object.
--- 
---@class TileObject : Event
---
---@field tileset Tileset       The name of the tileset the tile is from
---@field tile number           The gid of the tile in its tileset
---@field rotation number?      The rotation of the tile
---@field tile_flip_x boolean?  Whether the tile is flipped on its x-axis
---@field tile_flip_y boolean?  Whether the tile is flipped on its y-axis
---
---@overload fun(tileset: Tileset, tile: number, x: number, y: number, w?: number, h?: number, rotation?: number, flip_x?: boolean, flip_y?: boolean) : TileObject
local TileObject, super = Class(Event)

---@param tileset Tileset
---@param tile number
---@param x number
---@param y number
---@param w? number
---@param h? number
---@param rotation? number
---@param flip_x? boolean
---@param flip_y? boolean
function TileObject:init(tileset, tile, x, y, w, h, rotation, flip_x, flip_y)
    local tile_width, tile_height = tileset:getTileSize(tile)

    super.init(self, x, y, { w or tile_width, h or tile_height })

    self.tileset = tileset
    self.tile = tile
    self.rotation = rotation
    self.tile_flip_x = flip_x
    self.tile_flip_y = flip_y

    local origin = Tileset.ORIGINS[self.tileset.object_alignment] or Tileset.ORIGINS["unspecified"]
    self:setOrigin(origin[1], origin[2])
end

function TileObject:draw()
    local tile_width, tile_height = self.tileset:getTileSize(self.tileset:getDrawTile(self.tile))
    local sx = self.width / tile_width * (self.tile_flip_x and -1 or 1)
    local sy = self.height / tile_height * (self.tile_flip_y and -1 or 1)
    if self.tileset.preserve_aspect_fit then
        sx = MathUtils.absMin(sx, sy)
        sy = sx
    end
    self.tileset:drawTile(self.tile, self.width/2, self.height/2, 0, sx, sy, tile_width/2, tile_height/2)
end

return TileObject
