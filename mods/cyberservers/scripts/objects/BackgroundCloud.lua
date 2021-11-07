local BackgroundCloud, super = Class(Object)

function BackgroundCloud:init(asset, x, y, speed, parallax_x, parallax_y)
    super:init(self, x, y)

    self.asset = asset
    self.speed = speed or 0.2

    self.parallax_x = parallax_x or 0.6
    self.parallax_y = parallax_y or 0.8

    self.initial_y = y
end

function BackgroundCloud:update()
    self.x = self.x - (self.speed * DTMULT)

    if (self.x + self.asset:getWidth()) < 0 then
       self.x = self.x + self.asset:getWidth() + (Game.world.map_width * Game.world.tile_width)
    end
end

function BackgroundCloud:draw()
    love.graphics.draw(self.asset, 0, 0)
end

return BackgroundCloud
