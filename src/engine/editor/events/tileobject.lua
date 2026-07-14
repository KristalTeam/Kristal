---@class EditorTileObject : EditorEvent
---@overload fun(data?: table, options?: table): EditorTileObject
local EditorTileObject, super = Class(EditorEvent)

function EditorTileObject:init(data, options)
    super.init(self, data, options)
    options = options or {}
    local map = options.map
    local tile_id, flip_x, flip_y
    if data.gid and map then
        local gid
        gid, flip_x, flip_y = MapUtils.unpackTileGid(data.gid)
        self.tileset, tile_id = map:getTileset(gid)
    else
        self.tileset = data.tileset and Registry.getTileset(data.tileset)
        tile_id, flip_x, flip_y = data.tile_id, data.flip_x, data.flip_y
    end
    self.tile_id = tile_id
    self.flip_x, self.flip_y = flip_x == true, flip_y == true
    if self.tileset and tile_id ~= nil then
        local width, height = self.tileset:getTileSize(tile_id)
        self.width, self.height = data.width or width, data.height or height
        self.origin = Tileset.ORIGINS[self.tileset.object_alignment] or Tileset.ORIGINS.unspecified
    else
        self.origin = Tileset.ORIGINS.unspecified
    end
end

function EditorTileObject:createObject(map, context)
    if not self.tileset or self.tile_id == nil then return nil end
    return TileObject(self.tileset, self.tile_id, self.x, self.y,
        self.width, self.height, self.rotation, self.flip_x, self.flip_y)
end

function EditorTileObject:draw(alpha)
    if not self.visible or not self.tileset or self.tile_id == nil then return end
    alpha = alpha or 1
    local tile_width, tile_height = self.tileset:getTileSize(self.tileset:getDrawTile(self.tile_id))
    local scale_x = self.width / tile_width * (self.flip_x and -1 or 1)
    local scale_y = self.height / tile_height * (self.flip_y and -1 or 1)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    Draw.setColor(1, 1, 1, alpha)
    self.tileset:drawTile(self.tile_id,
        (0.5 - self.origin[1]) * self.width, (0.5 - self.origin[2]) * self.height,
        0, scale_x, scale_y, tile_width / 2, tile_height / 2)
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
end

function EditorTileObject:drawBounds(alpha, line_width)
    if not self.visible then return end
    local color = self.layer_color
    local previous_width = love.graphics.getLineWidth()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.setLineWidth(line_width or 1)
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1,
        math.min(color[4] or 1, 0.9) * (alpha or 1))
    love.graphics.rectangle("line", -self.origin[1] * self.width, -self.origin[2] * self.height,
        self.width, self.height)
    love.graphics.pop()
    love.graphics.setLineWidth(previous_width)
    Draw.setColor(1, 1, 1, 1)
end

return EditorTileObject
