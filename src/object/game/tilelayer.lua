local TileLayer, super = Class(Object)

function TileLayer:init(world, data)
    super:init(self)

    self.world = world

    self.map_width = data.width
    self.map_height = data.height

    self.offset_x = data.offset_x
    self.offset_y = data.offset_y

    self.tile_data = data.data
    self.tile_opacity = data.opacity

    self.canvas = love.graphics.newCanvas(self.map_width * world.tile_width, self.map_height * world.tile_height)
    self.drawn = false
end

function TileLayer:draw()
    if not self.drawn then
        local old_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()
        love.graphics.push()
        love.graphics.origin()
        for i,xid in ipairs(self.tile_data) do
            local tx = ((i - 1) % self.map_width) * self.world.tile_width
            local ty = math.floor((i - 1) / self.map_width) * self.world.tile_height

            local tileset, id = self.world:getTileset(xid)
            if tileset then
                tileset:drawTile(id, tx, ty)
            end
        end
        love.graphics.pop()
        love.graphics.setCanvas(old_canvas)

        self.drawn = true
    end

    local r, g, b, a = self:getColor()
    love.graphics.setColor(r, g, b, a * self.tile_opacity)
    love.graphics.draw(self.canvas)

    super:draw(self)
end

return TileLayer