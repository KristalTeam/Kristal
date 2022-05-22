local Tileset = Class()

function Tileset:init(data, path)
    self.path = path

    self.id = data.id
    self.name = data.name
    self.tile_count = data.tilecount or 0
    self.tile_width = data.tilewidth or 40
    self.tile_height = data.tileheight or 40
    self.margin = data.margin or 0
    self.spacing = data.spacing or 0
    self.columns = data.columns or 0
    self.object_alignment = data.objectalignment or "unspecified"

    self.tile_info = {}
    for _,v in ipairs(data.tiles or {}) do
        local info = {}
        if v.animation then
            info.animation = {duration = 0, frames={}}
            for _,anim in ipairs(v.animation) do
                table.insert(info.animation.frames, {id = anim.tileid, duration = anim.duration / 1000})
                info.animation.duration = info.animation.duration + (anim.duration / 1000)
            end
        end
        if v.image then
            local image_path = Utils.absoluteToLocalPath("assets/sprites/", v.image, path)
            info.texture = Assets.getTexture(image_path)
            if not info.texture then
                error("Could not load tileset tile texture: "..image_path)
            end
            info.width = v.width
            info.height = v.height
        end
        self.tile_info[v.id] = info
    end

    if data.image then
        local image_path = Utils.absoluteToLocalPath("assets/sprites/", data.image, path)
        self.texture = Assets.getTexture(image_path)
        if not self.texture then
            error("Could not load tileset texture: "..image_path)
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
        love.graphics.draw(info.texture, x or 0, y or 0, ...)
    else
        love.graphics.draw(self.texture, self.quads[draw_id], x or 0, y or 0, ...)
    end
end

function Tileset:drawTileFlipped(id, x, y, flip_x, flip_y, flip_diag)
    local draw_id = self:getDrawTile(id)
    local w, h = self:getTileSize(draw_id)

    local rot = 0
    if flip_diag then
        flip_y = not flip_y
        rot = -math.pi / 2
    end

    local info = self.tile_info[draw_id]
    if info and info.texture then
        love.graphics.draw(info.texture, (x or 0) + w/2, (y or 0) + h/2, rot, flip_x and -1 or 1, flip_y and -1 or 1, w/2, h/2)
    else
        love.graphics.draw(self.texture, self.quads[draw_id], (x or 0) + w/2, (y or 0) + h/2, rot, flip_x and -1 or 1, flip_y and -1 or 1, w/2, h/2)
    end
end

function Tileset:canDeepCopy()
    return false
end

return Tileset