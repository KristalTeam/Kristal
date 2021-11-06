local Tileset = Class()

function Tileset:init(data, path)
    self.name = data.name
    self.first_id = data.firstgid
    self.tile_width = data.tilewidth
    self.tile_height = data.tileheight
    self.margin = data.margin
    self.spacing = data.spacing
    self.columns = data.columns

    local texpath = Utils.absoluteToLocalPath("assets/sprites/", data.image, path)
    print(texpath)
    self.texture = Assets.getTexture(Utils.absoluteToLocalPath("assets/sprites/", data.image, path))
end

function Tileset:drawTile(id, x, y, ...)
    local tx = self.margin + (id % self.columns) * (self.tile_width + self.spacing)
    local ty = self.margin + math.floor(id / self.columns) * (self.tile_height + self.spacing)
    Draw.drawCutout(self.texture, x or 0, y or 0, tx, ty, self.tile_width, self.tile_height, ...)
end

return Tileset