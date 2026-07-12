---@class Tileset : Class
---@overload fun(...) : Tileset
---@field quads love.Quad[]
local Tileset = Class()

Tileset.ORIGINS = {
    ["unspecified"] = { 0, 1 },
    ["topleft"]     = { 0, 0 },
    ["top"]         = { 0.5, 0 },
    ["topright"]    = { 1, 0 },
    ["left"]        = { 0, 0.5 },
    ["center"]      = { 0.5, 0.5 },
    ["right"]       = { 1, 0.5 },
    ["bottomleft"]  = { 0, 1 },
    ["bottom"]      = { 0.5, 1 },
    ["bottomright"] = { 1, 1 },
}

---@param data table
---@param path string
---@param base_dir? string
function Tileset:init(data, path, base_dir)
    local reader_class = self.reader_class or data.__tileset_reader or TiledTilesetReader
    assert(isClass(reader_class) and reader_class:includes(TilesetReader),
        "Tileset reader must be a TilesetReader class")

    self.reader = reader_class(self)
    self.reader:initialize(data, path, base_dir)
end

function Tileset:loadTextureFromImagePath(filename)
    return self.reader:call("loadTextureFromImagePath", filename)
end

function Tileset:save(path, options)
    return self.reader:save(path, options)
end

function Tileset:getAnimation(id)
    local info = self.tile_info[id]
    return info and info.animation
end

function Tileset:getTileSize(id)
    local info = self.tile_info[id]
    if info and info.width and info.height then
        return info.width, info.height
    else
        return self.tile_width, self.tile_height
    end
end

function Tileset:getDrawTile(id)
    local info = self.tile_info[id]
    if info and info.animation then
        local time = Kristal.getTime()
        local pos = time % info.animation.duration
        local total_duration = 0
        for _, frame in ipairs(info.animation.frames) do
            id = frame.id
            if pos < total_duration + frame.duration then
                break
            end
            total_duration = total_duration + frame.duration
        end
    end
    return id
end

function Tileset:drawTile(id, x, y, ...)
    local draw_id = self:getDrawTile(id)
    local info = self.tile_info[draw_id]

    if info and info.texture then
        if not info.quad then
            Draw.draw(info.texture, x or 0, y or 0, ...)
        else
            Draw.draw(info.texture, info.quad, x or 0, y or 0, ...)
        end
    elseif self.texture and self.quads[draw_id] then
        Draw.draw(self.texture, self.quads[draw_id], x or 0, y or 0, ...)
    end
end

---@return love.Quad quad
---@return number x
---@return number y
---@return number rotation_radians
---@return number scale_x
---@return number scale_y
---@return number ox
---@return number oy
function Tileset:getGridTile(id, x, y, gw, gh, flip_x, flip_y, flip_diag)
    local draw_id = self:getDrawTile(id)
    local w, h = self:getTileSize(draw_id)

    x, y = x or 0, y or 0
    gw, gh = gw or w, gh or h

    local rot = 0
    if flip_diag then
        if flip_x == flip_y then
            flip_x = not flip_x
        else
            flip_y = not flip_y
        end
        rot = -math.pi / 2
    end

    local sx, sy = 1, 1
    if self.fill_grid and gw and gh and (w ~= gw or h ~= gh) then
        sx = gw / w
        sy = gh / h
        if self.preserve_aspect_fit then
            sx = MathUtils.absMin(sx, sy)
            sy = sx
        end
    end

    local ox, oy = (w * sx) / 2, gh - (h * sy) / 2

    return self.quads[draw_id], (x or 0) + ox, (y or 0) + oy, rot, flip_x and -sx or sx, flip_y and -sy or sy, w / 2, h / 2
end

function Tileset:drawGridTile(id, x, y, gw, gh, flip_x, flip_y, flip_diag)
    local draw_id = self:getDrawTile(id)
    local quad, draw_x, draw_y, rot, scale_x, scale_y, ox, oy = self:getGridTile(id, x, y, gw, gh, flip_x, flip_y, flip_diag)

    local info = self.tile_info[draw_id]
    if info and info.texture then
        if not info.quad then
            Draw.draw(info.texture, draw_x, draw_y, rot, scale_x, scale_y, ox, oy)
        else
            Draw.draw(info.texture, info.quad, draw_x, draw_y, rot, scale_x, scale_y, ox, oy)
        end
    elseif self.texture and quad then
        Draw.draw(self.texture, quad, draw_x, draw_y, rot, scale_x, scale_y, ox, oy)
    end
end

---@param batch love.SpriteBatch
function Tileset:addTileToBatch(batch, id, x, y, gw, gh, flip_x, flip_y, flip_diag)
    batch:add(self:getGridTile(id, x, y, gw, gh, flip_x, flip_y, flip_diag))
end

function Tileset:canDeepCopy()
    return false
end

return Tileset
