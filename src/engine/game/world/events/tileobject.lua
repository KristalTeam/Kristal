local TileObject, super = Class(Event)

function TileObject:init(tileset, tile, x, y, w, h)
    super:init(self, x, y, w or tileset.tile_width, h or tileset.tile_height)

    self:setOrigin(0, 1)

    self.tileset = tileset
    self.tile = tile
end

function TileObject:draw()
    self.tileset:drawTile(self.tile, 0, 0, 0, self.width / self.tileset.tile_width, self.height / self.tileset.tile_height)
end

return TileObject