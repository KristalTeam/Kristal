local Alley2, super = Class(Map)

function Alley2:load()
    super:load(self)

    self.timer:every(0.5, function()
        if self.world.in_battle then
            local marker1 = self.markers["shooter_left"]
            local marker2 = self.markers["shooter_right"]
            self.world:spawnBullet("testbullet", marker1.center_x, Utils.random(marker1.y, marker1.y+marker1.height), false)
            self.world:spawnBullet("testbullet", marker2.center_x, Utils.random(marker2.y, marker2.y+marker2.height), true)
        end
    end)
end

return Alley2