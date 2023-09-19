---@class Tileset : Class
---@overload fun(...) : Tileset
local Tileset = Class()

Tileset.ORIGINS = {
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

function Tileset:init(data, path, base_dir)
    self.path = path
    self.base_dir = base_dir or Utils.getDirname(self.path)

    self.id = data.id
    self.name = data.name
    self.tile_count = data.tilecount or 0
    self.tile_width = data.tilewidth or 40
    self.tile_height = data.tileheight or 40
    self.margin = data.margin or 0
    self.spacing = data.spacing or 0
    self.columns = data.columns or 0
    self.object_alignment = data.objectalignment or "unspecified"
    self.fill_grid = data.tilerendersize == "grid"
    self.preserve_aspect_fit = data.fillmode == "preserve-aspect-fit"

    self.id_count = self.tile_count

    self.tile_info = {}
    for _,tile in ipairs(data.tiles or {}) do
        local info = {}
        if tile.animation then
            info.animation = {duration = 0, frames={}}
            for _,anim in ipairs(tile.animation) do
                table.insert(info.animation.frames, {id = anim.tileid, duration = anim.duration / 1000})
                info.animation.duration = info.animation.duration + (anim.duration / 1000)
            end
        end
        if tile.image then
            local image_path = Utils.absoluteToLocalPath("assets/sprites/", tile.image, self.base_dir)
            info.path = image_path
            info.texture = Assets.getTexture(image_path)
            if not info.texture then
                error("Could not load tileset tile texture: " .. tostring(image_path) .. " [" .. tostring(path) .. "]")
            end
            info.x = tile.x or 0
            info.y = tile.y or 0
            info.width = tile.width or info.texture:getWidth()
            info.height = tile.height or info.texture:getHeight()

            if info.x ~= 0 or info.y ~= 0 or info.width ~= info.texture:getWidth() or info.height ~= info.texture:getHeight() then
                info.quad = love.graphics.newQuad(info.x, info.y, info.width, info.height, info.texture:getWidth(), info.texture:getHeight())
            end
        end
        self.tile_info[tile.id] = info
        self.id_count = math.max(self.id_count, tile.id + 1)
    end

    if data.image then
        local image_path = Utils.absoluteToLocalPath("assets/sprites/", data.image, self.base_dir)
        self.texture = Assets.getTexture(image_path)
        if not self.texture then
            error("Could not load tileset texture: " .. tostring(image_path) .. " [" .. tostring(path) .. "]")
        end
    end

    self.quads = {}
    if self.texture then
        local tw, th = self.texture:getWidth(), self.texture:getHeight()
        for i = 0, self.tile_count-1 do
            local tx = self.margin + (i % self.columns) * (self.tile_width + self.spacing)
            local ty = self.margin + math.floor(i / self.columns) * (self.tile_height + self.spacing)
            self.quads[i] = love.graphics.newQuad(tx, ty, self.tile_width, self.tile_height, tw, th)
        end
    end
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
        for _,frame in ipairs(info.animation.frames) do
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
    else
        Draw.draw(self.texture, self.quads[draw_id], x or 0, y or 0, ...)
    end
end

function Tileset:drawGridTile(id, x, y, gw, gh, flip_x, flip_y, flip_diag)
    local draw_id = self:getDrawTile(id)
    local w, h = self:getTileSize(draw_id)

    x, y = x or 0, y or 0
    gw, gh = gw or w, gh or h

    local rot = 0
    if flip_diag then
        flip_y = not flip_y
        rot = -math.pi / 2
    end

    local sx, sy = 1, 1
    if self.fill_grid and gw and gh and (w ~= gw or h ~= gh) then
        sx = gw / w
        sy = gh / h
        if self.preserve_aspect_fit then
            sx = Utils.absMin(sx, sy)
            sy = sx
        end
    end

    local ox, oy = (w * sx) / 2, gh - (h * sy) / 2

    local info = self.tile_info[draw_id]
    if info and info.texture then
        if not info.quad then
            Draw.draw(info.texture, (x or 0) + ox, (y or 0) + oy, rot, flip_x and -sx or sx, flip_y and -sy or sy, w/2, h/2)
        else
            Draw.draw(info.texture, info.quad, (x or 0) + ox, (y or 0) + oy, rot, flip_x and -sx or sx, flip_y and -sy or sy, w/2, h/2)
        end
    else
        Draw.draw(self.texture, self.quads[draw_id], (x or 0) + ox, (y or 0) + oy, rot, flip_x and -sx or sx, flip_y and -sy or sy, w/2, h/2)
    end
end

function Tileset:canDeepCopy()
    return false
end

return Tileset