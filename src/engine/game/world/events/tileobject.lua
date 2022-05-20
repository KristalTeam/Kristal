local TileObject, super = Class(Event)

TileObject.ORIGINS = {
    ["unspecified"] = {0,   1  },
    ["topleft"]     = {0,   0  },
    ["top"]         = {0.5, 0  },
    ["topright"]    = {1,   0  },
    ["left"]        = {0,   0.5},
    ["center"]      = {0.5, 0.5},
    ["right"]       = {1,   0.5},
    ["bottomleft"]  = {0,   1  },
    ["bottom"]      = {0.5, 1  },
    ["bottomright"] = {1,   1  },
}

function TileObject:init(tileset, tile, x, y, w, h)
    local tile_width, tile_height = tileset:getTileSize(tile)

    super:init(self, x, y, w or self.tile_width, h or self.tile_height)

    self.tileset = tileset
    self.tile = tile

    local origin = self.ORIGINS[self.tileset.object_alignment] or self.ORIGINS["unspecified"]
    self:setOrigin(origin[1], origin[2])
end

function TileObject:draw()
    local tile_width, tile_height = self.tileset:getTileSize(self.tileset:getDrawTile(self.tile))
    self.tileset:drawTile(self.tile, 0, 0, 0, self.width / tile_width, self.height / tile_height)
end

return TileObject