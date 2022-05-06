local Tileset = Class()

function Tileset:init(data, path)
    self.id = data.id
    self.name = data.name
    self.tile_count = data.tilecount or 0
    self.tile_width = data.tilewidth or 40
    self.tile_height = data.tileheight or 40
    self.margin = data.margin or 0
    self.spacing = data.spacing or 0
    self.columns = data.columns or 0

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
        self.tile_info[v.id] = info
    end

    self.texture = Assets.getTexture(Utils.absoluteToLocalPath("assets/sprites/", data.image, path))

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

function Tileset:drawTile(id, x, y, ...)
    local draw_id = id
    local info = self.tile_info[id]
    if info and info.animation then
        local time = Kristal.getTime()
        local pos = time % info.animation.duration
        local total_duration = 0
        for _,frame in ipairs(info.animation.frames) do
            draw_id = frame.id
            if pos < total_duration + frame.duration then
                break
            end
            total_duration = total_duration + frame.duration
        end
    end
    love.graphics.draw(self.texture, self.quads[draw_id], x or 0, y or 0, ...)
end

return Tileset