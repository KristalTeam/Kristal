local Background, super = Class(Event)

function Background:init(data)
    super:init(self, data.center_x, data.center_y)

    self.backdrop = Assets.getTexture("servers_background")
    self.cloud_1 = Assets.getTexture("cloud_1")
    self.cloud_2 = Assets.getTexture("cloud_2")
    self.bottom_clouds = Assets.getTexture("bottom_clouds")

    self.timer = 0

    for i = 1, math.floor(Game.world.map_width / 8) do
        local cloud_index = ((i - 1) % 4) + 1
        local x_offset = math.floor((i - 1) / 4)
        if cloud_index == 1 then
            self:createCloud(self.cloud_2, x_offset + -244, 238, 0.2 , 0.5,  0.7 , {0.9,  0.9,  0.9 })
        elseif cloud_index == 2 then
            self:createCloud(self.cloud_1, x_offset + 154, 154,  0.35, 0.6,  0.8 , {1,    1,    1   })
        elseif cloud_index == 3 then
            self:createCloud(self.cloud_2, x_offset + 560, 240,  0.25, 0.55, 0.75, {0.95, 0.95, 0.95})
        elseif cloud_index == 4 then
            self:createCloud(self.cloud_1, x_offset + 840, 190,  0.25, 0.5,  0.7,  {0.9, 0.9, 0.9})
        end
    end
end

function Background:createCloud(asset, x, y, speed, parallax_x, parallax_y, color)
    local cloud = BackgroundCloud(asset, x, y, speed, parallax_x, parallax_y)
    if color then
        cloud:setColor(color)
    end
    self:addChild(cloud)
    return cloud
end

function Background:draw()
    love.graphics.draw(self.backdrop, self.world.camera:getParallax(0, 0.6))

    local clouds_x, clouds_y = self.world.camera:getParallax(0, 0.8)
    love.graphics.draw(self.bottom_clouds, clouds_x, clouds_y + 200)

    super:draw(self)
end

return Background
