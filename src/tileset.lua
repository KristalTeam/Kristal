local Tileset = Class()

function Tileset:init(data, path)
    self.name = data.name
    self.first_id = data.firstgid
    self.tile_width = data.tilewidth
    self.tile_height = data.tileheight
    self.margin = data.margin
    self.spacing = data.spacing
    self.columns = data.columns

    self.texture = Assets.getTexture(self:getTexturePath(data.image, path))
end

function Tileset:drawTile(id, x, y, ...)
    local tx = self.margin + (id % self.columns) * (self.tile_width + self.spacing)
    local ty = self.margin + math.floor(id / self.columns) * (self.tile_height + self.spacing)
    Draw.drawCutout(self.texture, x or 0, y or 0, tx, ty, self.tile_width, self.tile_height, ...)
end

function Tileset:getTexturePath(image, path)
    local current_path = Utils.split(path, "/")
    local tileset_path = Utils.split(image, "/")
    while tileset_path[1] == ".." do
        table.remove(tileset_path, 1)
        table.remove(current_path, #current_path)
    end
    Utils.merge(current_path, tileset_path)
    local final_path = Utils.join(current_path, "/")
    local _,sprite_index = final_path:find("assets/sprites/")
    return final_path:sub(sprite_index + 1, -5)
end

return Tileset