local Alley2, super = Class(Map)

function Alley2:load()
    super.load(self)

    self.timer:every(0.5, function()
        if self.world:inBattle() then
            local marker1 = self.markers["shooter_left"]
            local marker2 = self.markers["shooter_right"]
            self.world:spawnBullet("testbullet", marker1.center_x, Utils.random(marker1.y, marker1.y+marker1.height), false)
            self.world:spawnBullet("testbullet", marker2.center_x, Utils.random(marker2.y, marker2.y+marker2.height), true)
        end
    end)
end

function Alley2:update()
    super.update(self)
    local clicked = false
    for _,banana in ipairs(self:getEvents("banana")) do
        if banana.mouse_collider:clicked() then
            clicked = true
            Kristal.Console:log("* You clicked a banana")
        end
    end
    if Input.mousePressed() and not clicked then
        local ralsei = Game.world:getCharacter("ralsei")
        if ralsei and ralsei:clicked() then
            ralsei:explode()
            Kristal.Console:log("* You clicked Ralsei. Why did you do that?")
        else
            Kristal.Console:log("* You missed every banana. How sad.")
        end
    end
end

return Alley2