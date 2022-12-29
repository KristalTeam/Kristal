---@class TileObject : Event
---@overload fun(...) : TileObject
local TileObject, super = Class(Event)

function TileObject:init(tileset, tile, x, y, w, h, rotation, flip_x, flip_y)
    local tile_width, tile_height = tileset:getTileSize(tile)

    super.init(self, x, y, w or self.tile_width, h or self.tile_height)

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
        sx = Utils.absMin(sx, sy)
        sy = sx
    end
    self.tileset:drawTile(self.tile, self.width/2, self.height/2, 0, sx, sy, tile_width/2, tile_height/2)
end

return TileObject